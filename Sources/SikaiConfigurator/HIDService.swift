import Foundation
import IOKit
import IOKit.hid

public class HIDService: ObservableObject {
    @Published public var isConnected = false
    @Published public var connectedDeviceName = "Disconnected"
    @Published public var connectedModel: KeyboardModel? = nil
    @Published public var connectedPID: UInt16 = 0
    @Published public var logs: [String] = []
    
    private var manager: IOHIDManager?
    private var activeDevice: IOHIDDevice?
    
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
