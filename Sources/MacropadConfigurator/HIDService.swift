import Foundation
import IOKit
import IOKit.hid

public class HIDService: ObservableObject {
    @Published public var isConnected = false
    @Published public var connectedDeviceName = "Disconnected"
    @Published public var connectedModel: KeyboardModel? = nil
    @Published public var connectedPID: UInt16 = 0
    @Published public var logs: [String] = []
    
    @Published public var isReading = false
    @Published public var readProgress: Double = 0.0
    @Published public var readMappings: [String: KeyMacro] = [:]
    @Published public var readLEDModes: [UInt8: LEDMode] = [:]
    
    private var manager: IOHIDManager?
    private var activeDevice: IOHIDDevice?
    private var deviceReportBuffer = [UInt8](repeating: 0, count: 64)
    
    private enum ReadPhase {
        case idle
        case readingKeys(outerIndex: UInt8)
        case readingLEDs(layerIndex: UInt8)
    }
    
    private var readPhase: ReadPhase = .idle
    private var accumulatedKeyPackets: [Data] = []
    private var accumulatedLEDPackets: [UInt8: Data] = [:]
    
    public init() {
        log("Initializing IOHIDManager...")
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = manager else {
            log("Error: Failed to create IOHIDManager.")
            return
        }
        
        // Match the target keyboards
        let matchDicts: [[String: Any]] = [
            [kIOHIDVendorIDKey: 0x1189, kIOHIDProductIDKey: 0x8840],
            [kIOHIDVendorIDKey: 0x1189, kIOHIDProductIDKey: 0x8842],
            [kIOHIDVendorIDKey: 0x1189, kIOHIDProductIDKey: 0x8850],
            [kIOHIDVendorIDKey: 0x1189, kIOHIDProductIDKey: 0x8851],
            [kIOHIDVendorIDKey: 0x1189, kIOHIDProductIDKey: 0x8890],
            [kIOHIDVendorIDKey: 0x514C, kIOHIDProductIDKey: 0x8840],
            [kIOHIDVendorIDKey: 0x514C, kIOHIDProductIDKey: 0x8842],
            [kIOHIDVendorIDKey: 0x514C, kIOHIDProductIDKey: 0x8850],
            [kIOHIDVendorIDKey: 0x514C, kIOHIDProductIDKey: 0x8851],
            [kIOHIDVendorIDKey: 0x514C, kIOHIDProductIDKey: 0x8890]
        ]
        
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchDicts as CFArray)
        
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { (context, result, sender, device) in
            guard let context = context else { return }
            let this = Unmanaged<HIDService>.fromOpaque(context).takeUnretainedValue()
            this.deviceAttached(device)
        }, selfPointer)
        
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { (context, result, sender, device) in
            guard let context = context else { return }
            let this = Unmanaged<HIDService>.fromOpaque(context).takeUnretainedValue()
            this.deviceRemoved(device)
        }, selfPointer)
        
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let openStatus = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        
        if openStatus == kIOReturnSuccess {
            log("IOHIDManager opened successfully. Scanning for devices...")
        } else {
            log("Error: Failed to open IOHIDManager (Code: \(openStatus)).")
        }
    }
    
    private func deviceAttached(_ device: IOHIDDevice) {
        // Only match the custom programming/vendor HID interface (Usage Page 0xFF00)
        let usagePage = IOHIDDeviceGetProperty(device, kIOHIDPrimaryUsagePageKey as CFString) as? Int ?? 0
        guard usagePage == 0xFF00 else {
            return
        }
        
        self.activeDevice = device
        
        // Register report callback
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        IOHIDDeviceRegisterInputReportCallback(
            device,
            &self.deviceReportBuffer,
            64,
            hidInputReportCallback,
            selfPointer
        )
        
        // Read device parameters
        let name = IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Generic Macro Keyboard"
        let vendorID = IOHIDDeviceGetProperty(device, kIOHIDVendorIDKey as CFString) as? UInt16 ?? 0
        let productID = IOHIDDeviceGetProperty(device, kIOHIDProductIDKey as CFString) as? UInt16 ?? 0
        
        DispatchQueue.main.async {
            self.isConnected = true
            self.connectedDeviceName = name
            self.connectedPID = productID
            self.connectedModel = KeyboardModel.from(productID: productID) ?? .ch57x_1
            self.log("Connected to device: \(name) [VID: 0x\(String(vendorID, radix: 16)), PID: 0x\(String(productID, radix: 16))]")
            self.log("Identified model: \(self.connectedModel?.rawValue ?? "Unknown")")
            self.startReading()
        }
    }
    
    private func deviceRemoved(_ device: IOHIDDevice) {
        if self.activeDevice == device {
            self.activeDevice = nil
            DispatchQueue.main.async {
                self.isConnected = false
                self.connectedDeviceName = "Disconnected"
                self.connectedPID = 0
                self.connectedModel = nil
                self.isReading = false
                self.readPhase = .idle
                self.log("Device disconnected.")
            }
        }
    }
    
    public func writeReport(packet: [UInt8]) -> Bool {
        guard let device = activeDevice else {
            log("Write Error: No active device connected.")
            return false
        }
        
        var report = packet
        if report.count < 64 {
            report.append(contentsOf: [UInt8](repeating: 0, count: 64 - report.count))
        }
        
        // Print packet dump
        let hexString = report.map { String(format: "%02X", $0) }.joined(separator: " ")
        log("Sending packet: [\(hexString)]")
        
        let result = IOHIDDeviceSetReport(
            device,
            kIOHIDReportTypeOutput,
            0,
            &report,
            64
        )
        
        if result == kIOReturnSuccess {
            return true
        } else {
            log("Write Error: Failed to write report (Code: \(result)).")
            return false
        }
    }
    
    public func startReading() {
        guard isConnected, !isReading else { return }
        
        self.isReading = true
        self.readProgress = 0.0
        self.readMappings = [:]
        self.readLEDModes = [:]
        self.accumulatedKeyPackets = []
        self.accumulatedLEDPackets = [:]
        
        self.readPhase = .idle
        self.sendNextReadCommand()
    }
    
    private func sendNextReadCommand() {
        guard isConnected, let model = connectedModel else {
            self.isReading = false
            self.readPhase = .idle
            return
        }
        
        switch readPhase {
        case .idle:
            self.log("Starting configuration read...")
            self.readPhase = .readingKeys(outerIndex: 1)
            sendNextReadCommand()
            
        case .readingKeys(let outerIndex):
            if outerIndex <= 3 {
                self.log("Reading keys configuration block \(outerIndex)/3...")
                let arg2: UInt8 = (model == .ch57x_2) ? 0x19 : 0x0f
                let arg3: UInt8 = (model == .ch57x_2) ? 0x00 : 0x03
                let cmd: [UInt8] = [0x03, 0xfa, arg2, arg3, outerIndex]
                _ = self.writeReport(packet: cmd)
            } else {
                self.log("Reading LED configurations...")
                self.readPhase = .readingLEDs(layerIndex: 0)
                sendNextReadCommand()
            }
            
        case .readingLEDs(let layerIndex):
            if layerIndex <= 3 {
                self.log("Reading LED configuration for Layer \(layerIndex + 1)...")
                let cmd: [UInt8] = [0x03, 0xfa, 0xb0, layerIndex]
                _ = self.writeReport(packet: cmd)
            } else {
                self.finishReading()
            }
        }
    }
    
    public func didReceiveInputReport(report: UnsafeMutablePointer<UInt8>, length: Int) {
        let data = Data(bytes: report, count: length)
        DispatchQueue.main.async {
            self.handleIncomingReport(data)
        }
    }
    
    private func handleIncomingReport(_ data: Data) {
        guard isReading else { return }
        guard data.count >= 64, data[0] == 0x03 else { return }
        guard let model = connectedModel else { return }
        
        switch readPhase {
        case .readingKeys(let outerIndex):
            accumulatedKeyPackets.append(data)
            
            let expectedCount: Int
            if model == .ch57x_2 {
                expectedCount = Int(outerIndex) * 25
            } else {
                expectedCount = Int(outerIndex) * 24
            }
            
            let totalExpected = (model == .ch57x_2 ? 75 : 72) + 4
            self.readProgress = Double(accumulatedKeyPackets.count) / Double(totalExpected)
            
            if accumulatedKeyPackets.count >= expectedCount {
                self.readPhase = .readingKeys(outerIndex: outerIndex + 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.sendNextReadCommand()
                }
            }
            
        case .readingLEDs(let layerIndex):
            accumulatedLEDPackets[layerIndex] = data
            
            let totalExpected = (model == .ch57x_2 ? 75 : 72) + 4
            self.readProgress = Double(accumulatedKeyPackets.count + accumulatedLEDPackets.count) / Double(totalExpected)
            
            self.readPhase = .readingLEDs(layerIndex: layerIndex + 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.sendNextReadCommand()
            }
            
        default:
            break
        }
    }
    
    private func finishReading() {
        guard let model = connectedModel else {
            self.isReading = false
            self.readPhase = .idle
            return
        }
        
        var newMappings = [String: KeyMacro]()
        var newLEDModes = [UInt8: LEDMode]()
        
        // 1. Decode keys
        if model == .ch57x_1 {
            for packet in accumulatedKeyPackets {
                let payload = Array(packet[1...50])
                if let result = Protocol.decodeMacroCh57x1(payload: payload) {
                    let path = "\(result.key.description)-L\(result.layer)"
                    newMappings[path] = result.macro
                }
            }
        } else if model == .ch57x_2 {
            var keyboardAccumulator = [String: (modifiers: ModifierFlags, keys: [UInt8])]()
            for packet in accumulatedKeyPackets {
                let payload = Array(packet[1...60])
                if let result = Protocol.decodeMacroCh57x2(payload: payload, keyboardAccumulator: &keyboardAccumulator) {
                    let path = "\(result.key.description)-L\(result.layer)"
                    newMappings[path] = result.macro
                }
            }
            
            for (path, val) in keyboardAccumulator {
                if newMappings[path] == nil {
                    newMappings[path] = .keyboard(modifiers: val.modifiers, keys: val.keys)
                }
            }
        }
        
        // 2. Decode LEDs
        for (layer, packet) in accumulatedLEDPackets {
            let combinedCode = packet[1]
            let mode = Protocol.decodeLEDMode(combinedCode: combinedCode)
            newLEDModes[layer] = mode
        }
        
        self.log("Success: Loaded configuration from device (\(newMappings.count) key mappings, \(newLEDModes.count) LED settings).")
        
        self.readMappings = newMappings
        self.readLEDModes = newLEDModes
        self.isReading = false
        self.readPhase = .idle
        self.readProgress = 1.0
        
        NotificationCenter.default.post(name: Notification.Name("MacropadConfigReadDone"), object: nil)
    }
    
    public func uploadConfig(key: Key, layer: UInt8, macro: KeyMacro) {
        guard isConnected, let model = connectedModel else {
            log("Upload Error: Device is not connected.")
            return
        }
        
        log("Uploading configuration for \(key) on Layer \(layer)...")
        let packets = Protocol.buildPackets(key: key, layer: layer, macro: macro, model: model)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var success = true
            for packet in packets {
                if !self.writeReport(packet: packet) {
                    success = false
                    break
                }
                // Small sleep to allow device to digest the packet
                Thread.sleep(forTimeInterval: 0.01)
            }
            
            DispatchQueue.main.async {
                if success {
                    self.log("Success: Key configuration programmed to device memory.")
                } else {
                    self.log("Error: Programming failed midway.")
                }
            }
        }
    }
    
    public func clearConfig(key: Key, layer: UInt8) {
        // Clear config is sending an empty keyboard macro
        uploadConfig(key: key, layer: layer, macro: .keyboard(modifiers: [], keys: []))
    }
    
    public func uploadLED(layer: UInt8, mode: LEDMode) {
        guard isConnected, let model = connectedModel else {
            log("LED Upload Error: Device is not connected.")
            return
        }
        
        log("Uploading LED configuration for Layer \(layer)...")
        let packets = Protocol.buildLEDPackets(layer: layer, mode: mode, model: model)
        
        DispatchQueue.global(qos: .userInitiated).async {
            var success = true
            for packet in packets {
                if !self.writeReport(packet: packet) {
                    success = false
                    break
                }
                // Small sleep to allow device to digest the packet
                Thread.sleep(forTimeInterval: 0.01)
            }
            
            DispatchQueue.main.async {
                if success {
                    self.log("Success: LED configuration applied successfully.")
                } else {
                    self.log("Error: LED programming failed midway.")
                }
            }
        }
    }
    
    public func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let formattedMsg = "[\(timestamp)] \(message)"
        
        DispatchQueue.main.async {
            self.logs.append(formattedMsg)
            // Limit log items
            if self.logs.count > 100 {
                self.logs.removeFirst()
            }
        }
    }
}

fileprivate func hidInputReportCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    type: IOHIDReportType,
    reportID: UInt32,
    report: UnsafeMutablePointer<UInt8>,
    reportLength: CFIndex
) {
    guard let context = context else { return }
    let this = Unmanaged<HIDService>.fromOpaque(context).takeUnretainedValue()
    this.didReceiveInputReport(report: report, length: reportLength)
}
