import Foundation

public struct ModifierFlags: OptionSet, Codable, Hashable {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    public static let ctrl      = ModifierFlags(rawValue: 0x01)
    public static let shift     = ModifierFlags(rawValue: 0x02)
    public static let alt       = ModifierFlags(rawValue: 0x04)
    public static let win       = ModifierFlags(rawValue: 0x08)
    public static let rctrl     = ModifierFlags(rawValue: 0x10)
    public static let rshift    = ModifierFlags(rawValue: 0x20)
    public static let ralt      = ModifierFlags(rawValue: 0x40)
    public static let rwin      = ModifierFlags(rawValue: 0x80)
}

public enum MouseActionType: String, Codable, CaseIterable {
    case move = "Move Cursor"
    case drag = "Drag"
    case click = "Click"
    case wheel = "Scroll Wheel"
}

public enum KeyMacro: Codable, Hashable {
    case keyboard(modifiers: ModifierFlags, keys: [UInt8])
    case media(UInt16)
    case mouse(action: MouseActionType, buttons: UInt8, dx: Int, dy: Int, scroll: Int)
}

public struct USBKeyCode: Identifiable, Hashable {
    public var id: UInt8 { code }
    public let name: String
    public let code: UInt8
    
    public static let codes: [USBKeyCode] = [
        USBKeyCode(name: "A", code: 0x04),
        USBKeyCode(name: "B", code: 0x05),
        USBKeyCode(name: "C", code: 0x06),
        USBKeyCode(name: "D", code: 0x07),
        USBKeyCode(name: "E", code: 0x08),
        USBKeyCode(name: "F", code: 0x09),
        USBKeyCode(name: "G", code: 0x0A),
        USBKeyCode(name: "H", code: 0x0B),
        USBKeyCode(name: "I", code: 0x0C),
        USBKeyCode(name: "J", code: 0x0D),
        USBKeyCode(name: "K", code: 0x0E),
        USBKeyCode(name: "L", code: 0x0F),
        USBKeyCode(name: "M", code: 0x10),
        USBKeyCode(name: "N", code: 0x11),
        USBKeyCode(name: "O", code: 0x12),
        USBKeyCode(name: "P", code: 0x13),
        USBKeyCode(name: "Q", code: 0x14),
        USBKeyCode(name: "R", code: 0x15),
        USBKeyCode(name: "S", code: 0x16),
        USBKeyCode(name: "T", code: 0x17),
        USBKeyCode(name: "U", code: 0x18),
        USBKeyCode(name: "V", code: 0x19),
        USBKeyCode(name: "W", code: 0x1A),
        USBKeyCode(name: "X", code: 0x1B),
        USBKeyCode(name: "Y", code: 0x1C),
        USBKeyCode(name: "Z", code: 0x1D),
        USBKeyCode(name: "1", code: 0x1E),
        USBKeyCode(name: "2", code: 0x1F),
        USBKeyCode(name: "3", code: 0x20),
        USBKeyCode(name: "4", code: 0x21),
        USBKeyCode(name: "5", code: 0x22),
        USBKeyCode(name: "6", code: 0x23),
        USBKeyCode(name: "7", code: 0x24),
        USBKeyCode(name: "8", code: 0x25),
        USBKeyCode(name: "9", code: 0x26),
        USBKeyCode(name: "0", code: 0x27),
        USBKeyCode(name: "Enter", code: 0x28),
        USBKeyCode(name: "Escape", code: 0x29),
        USBKeyCode(name: "Backspace", code: 0x2A),
        USBKeyCode(name: "Tab", code: 0x2B),
        USBKeyCode(name: "Spacebar", code: 0x2C),
        USBKeyCode(name: "Minus (-)", code: 0x2D),
        USBKeyCode(name: "Equal (=)", code: 0x2E),
        USBKeyCode(name: "[", code: 0x2F),
        USBKeyCode(name: "]", code: 0x30),
        USBKeyCode(name: "\\", code: 0x31),
        USBKeyCode(name: ";", code: 0x33),
        USBKeyCode(name: "'", code: 0x34),
        USBKeyCode(name: "`", code: 0x35),
        USBKeyCode(name: ",", code: 0x36),
        USBKeyCode(name: ".", code: 0x37),
        USBKeyCode(name: "/", code: 0x38),
        USBKeyCode(name: "Caps Lock", code: 0x39),
        USBKeyCode(name: "F1", code: 0x3A),
        USBKeyCode(name: "F2", code: 0x3B),
        USBKeyCode(name: "F3", code: 0x3C),
        USBKeyCode(name: "F4", code: 0x3D),
        USBKeyCode(name: "F5", code: 0x3E),
        USBKeyCode(name: "F6", code: 0x3F),
        USBKeyCode(name: "F7", code: 0x40),
        USBKeyCode(name: "F8", code: 0x41),
        USBKeyCode(name: "F9", code: 0x42),
        USBKeyCode(name: "F10", code: 0x43),
        USBKeyCode(name: "F11", code: 0x44),
        USBKeyCode(name: "F12", code: 0x45),
        USBKeyCode(name: "Delete", code: 0x4C),
        USBKeyCode(name: "Right Arrow", code: 0x4F),
        USBKeyCode(name: "Left Arrow", code: 0x50),
        USBKeyCode(name: "Down Arrow", code: 0x51),
        USBKeyCode(name: "Up Arrow", code: 0x52)
    ]
}

public struct USBMediaCode: Identifiable, Hashable {
    public var id: UInt16 { code }
    public let name: String
    public let code: UInt16
    
    public static let codes: [USBMediaCode] = [
        USBMediaCode(name: "Next Track", code: 0xb5),
        USBMediaCode(name: "Previous Track", code: 0xb6),
        USBMediaCode(name: "Stop", code: 0xb7),
        USBMediaCode(name: "Play/Pause", code: 0xcd),
        USBMediaCode(name: "Mute", code: 0xe2),
        USBMediaCode(name: "Volume Up", code: 0xe9),
        USBMediaCode(name: "Volume Down", code: 0xea),
        USBMediaCode(name: "Calculator", code: 0x192),
        USBMediaCode(name: "Screen Lock", code: 0x19e)
    ]
}

public struct USBMouseButton: Identifiable, Hashable {
    public var id: UInt8 { value }
    public let name: String
    public let value: UInt8
    
    public static let buttons: [USBMouseButton] = [
        USBMouseButton(name: "Left Click", value: 0x01),
        USBMouseButton(name: "Right Click", value: 0x02),
        USBMouseButton(name: "Middle Click", value: 0x04)
    ]
}

public struct Protocol {
    
    public static func toKeyID(key: Key, model: KeyboardModel, knobsCount: Int = 1) -> UInt8 {
        switch model {
        case .ch57x_2:
            // CH57x_2 (8890)
            switch key {
            case .button(let index):
                return UInt8(index + 1)
            case .knob(let index, let action):
                return UInt8(12 + 1 + 3 * index + action.rawValue)
            }
            
        case .ch57x_1:
            // CH57x_1 (8840/8842/8850)
            switch key {
            case .button(let index):
                return UInt8(index + 1)
            case .knob(let index, let action):
                if index == 3 {
                    // special case for fourth knob
                    return UInt8(13 + action.rawValue)
                } else {
                    return UInt8(15 + 1 + 3 * index + action.rawValue)
                }
            }
        }
    }
    
    public static func buildPackets(key: Key, layer: UInt8, macro: KeyMacro, model: KeyboardModel) -> [[UInt8]] {
        let keyId = toKeyID(key: key, model: model)
        switch model {
        case .ch57x_2:
            return buildPacketsCh57x2(keyId: keyId, layer: layer, macro: macro)
        case .ch57x_1:
            return buildPacketsCh57x1(keyId: keyId, layer: layer, macro: macro)
        }
    }
    
    private static func buildPacketsCh57x2(keyId: UInt8, layer: UInt8, macro: KeyMacro) -> [[UInt8]] {
        var packets = [[UInt8]]()
        
        // Start programming packet
        var startBuf = [UInt8](repeating: 0, count: 64)
        startBuf[0] = 0x03
        startBuf[1] = 0xfe
        startBuf[2] = layer + 1
        startBuf[3] = 0x01
        startBuf[4] = 0x01
        packets.append(startBuf)
        
        let layerShifted = (layer + 1) << 4
        
        switch macro {
        case .keyboard(let modifiers, let keys):
            let kind: UInt8 = 1
            let length = UInt8(keys.count)
            
            // Empty packet first (index 0)
            var emptyBuf = [UInt8](repeating: 0, count: 64)
            emptyBuf[0] = 0x03
            emptyBuf[1] = keyId
            emptyBuf[2] = layerShifted | kind
            emptyBuf[3] = length
            emptyBuf[4] = 0
            emptyBuf[5] = 0
            emptyBuf[6] = 0
            packets.append(emptyBuf)
            
            // Now send key scancodes (up to 5 keys in the macro sequence)
            for (i, code) in keys.prefix(5).enumerated() {
                var buf = [UInt8](repeating: 0, count: 64)
                buf[0] = 0x03
                buf[1] = keyId
                buf[2] = layerShifted | kind
                buf[3] = length
                buf[4] = UInt8(i + 1)
                buf[5] = modifiers.rawValue
                buf[6] = code
                packets.append(buf)
            }
            
        case .media(let code):
            let kind: UInt8 = 2
            let low = UInt8(code & 0xFF)
            let high = UInt8((code >> 8) & 0xFF)
            var buf = [UInt8](repeating: 0, count: 64)
            buf[0] = 0x03
            buf[1] = keyId
            buf[2] = layerShifted | kind
            buf[3] = low
            buf[4] = high
            packets.append(buf)
            
        case .mouse(let action, let buttons, let dx, let dy, let scroll):
            let kind: UInt8 = 3
            var buf = [UInt8](repeating: 0, count: 64)
            buf[0] = 0x03
            buf[1] = keyId
            buf[2] = layerShifted | kind
            
            switch action {
            case .move:
                buf[3] = 0
                buf[4] = UInt8(bitPattern: Int8(clamping: dx))
                buf[5] = UInt8(bitPattern: Int8(clamping: dy))
                buf[6] = 0
                buf[7] = 0
            case .drag:
                buf[3] = buttons
                buf[4] = UInt8(bitPattern: Int8(clamping: dx))
                buf[5] = UInt8(bitPattern: Int8(clamping: dy))
                buf[6] = 0
                buf[7] = 0
            case .click:
                buf[3] = buttons
                buf[4] = 0
                buf[5] = 0
                buf[6] = 0
                buf[7] = 0
            case .wheel:
                buf[3] = 0
                buf[4] = 0
                buf[5] = 0
                buf[6] = UInt8(bitPattern: Int8(clamping: scroll))
                buf[7] = 0
            }
            packets.append(buf)
        }
        
        // Finish programming packet
        var endBuf = [UInt8](repeating: 0, count: 64)
        endBuf[0] = 0x03
        endBuf[1] = 0xaa
        endBuf[2] = 0xaa
        packets.append(endBuf)
        
        return packets
    }
    
    private static func buildPacketsCh57x1(keyId: UInt8, layer: UInt8, macro: KeyMacro) -> [[UInt8]] {
        var packets = [[UInt8]]()
        
        var msg = [UInt8]()
        msg.append(0x03)
        msg.append(0xfe)
        msg.append(keyId)
        msg.append(layer + 1)
        
        switch macro {
        case .keyboard(let modifiers, let keys):
            msg.append(1) // kind = 1 (Keyboard)
            msg.append(contentsOf: [0, 0, 0, 0, 0]) // Padded headers
            
            if keys.isEmpty && !modifiers.isEmpty {
                msg.append(0)
            } else {
                msg.append(UInt8(keys.count))
            }
            
            for code in keys.prefix(18) {
                msg.append(modifiers.rawValue)
                msg.append(code)
            }
            
        case .media(let code):
            msg.append(2) // kind = 2 (Media)
            msg.append(contentsOf: [0, 0, 0, 0, 0])
            let low = UInt8(code & 0xFF)
            let high = UInt8((code >> 8) & 0xFF)
            msg.append(contentsOf: [0, low, high, 0, 0, 0, 0])
            
        case .mouse(let action, let buttons, let dx, let dy, let scroll):
            msg.append(3) // kind = 3 (Mouse)
            msg.append(contentsOf: [0, 0, 0, 0, 0])
            
            switch action {
            case .move:
                msg.append(contentsOf: [0x05, 0, 0, UInt8(bitPattern: Int8(clamping: dx)), UInt8(bitPattern: Int8(clamping: dy))])
            case .drag:
                msg.append(contentsOf: [0x05, 0, buttons, UInt8(bitPattern: Int8(clamping: dx)), UInt8(bitPattern: Int8(clamping: dy))])
            case .click:
                msg.append(contentsOf: [0x01, 0, buttons])
            case .wheel:
                msg.append(contentsOf: [0x03, 0, 0, 0, 0, UInt8(bitPattern: Int8(clamping: scroll))])
            }
        }
        
        // Chunk into 64-byte packets
        var tempMsg = msg
        while tempMsg.count > 0 {
            var chunk = [UInt8](repeating: 0, count: 64)
            let take = min(tempMsg.count, 64)
            chunk[0..<take] = tempMsg[0..<take]
            packets.append(chunk)
            tempMsg.removeFirst(take)
        }
        
        // Commit packets for CH57x_1
        var commit1 = [UInt8](repeating: 0, count: 64)
        commit1[0] = 0x03
        commit1[1] = 0xaa
        commit1[2] = 0xaa
        packets.append(commit1)
        
        var commit2 = [UInt8](repeating: 0, count: 64)
        commit2[0] = 0x03
        commit2[1] = 0xfd
        commit2[2] = 0xfe
        commit2[3] = 0xff
        packets.append(commit2)
        
        var commit3 = [UInt8](repeating: 0, count: 64)
        commit3[0] = 0x03
        commit3[1] = 0xaa
        commit3[2] = 0xaa
        packets.append(commit3)
        
        return packets
    }
}

public enum LEDColor: UInt8, CaseIterable, Identifiable, Codable {
    case red = 1
    case orange = 2
    case yellow = 3
    case green = 4
    case cyan = 5
    case blue = 6
    case purple = 7
    
    public var id: UInt8 { rawValue }
    public var name: String {
        switch self {
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .cyan: return "Cyan"
        case .blue: return "Blue"
        case .purple: return "Purple"
        }
    }
}

public enum LEDBacklightColor: UInt8, CaseIterable, Identifiable, Codable {
    case white = 0
    case red = 1
    case orange = 2
    case yellow = 3
    case green = 4
    case cyan = 5
    case blue = 6
    case purple = 7
    
    public var id: UInt8 { rawValue }
    public var name: String {
        switch self {
        case .white: return "White"
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .cyan: return "Cyan"
        case .blue: return "Blue"
        case .purple: return "Purple"
        }
    }
}

public enum LEDMode: Codable, Hashable {
    case off
    case backlight(LEDBacklightColor)
    case shock(LEDColor)
    case shock2(LEDColor)
    case press(LEDColor)
    
    public var modeCode: UInt8 {
        switch self {
        case .off: return 0
        case .backlight(let color):
            return color == .white ? 5 : 1
        case .shock: return 2
        case .shock2: return 3
        case .press: return 4
        }
    }
    
    public var colorCode: UInt8 {
        switch self {
        case .off: return 0
        case .backlight(let color):
            return color == .white ? 0 : color.rawValue
        case .shock(let color), .shock2(let color), .press(let color):
            return color.rawValue
        }
    }
    
    public var combinedCode: UInt8 {
        return (colorCode << 4) | modeCode
    }
}

extension Protocol {
    public static func buildLEDPackets(layer: UInt8, mode: LEDMode, model: KeyboardModel) -> [[UInt8]] {
        var packets = [[UInt8]]()
        switch model {
        case .ch57x_1:
            let code = mode.combinedCode
            // First packet: 03 fe b0 LAYER 08 00 00 00 00 00 01 00 CODE
            var p1 = [UInt8](repeating: 0, count: 64)
            p1[0] = 0x03
            p1[1] = 0xfe
            p1[2] = 0xb0
            p1[3] = layer + 1
            p1[4] = 0x08
            p1[5] = 0x00
            p1[6] = 0x00
            p1[7] = 0x00
            p1[8] = 0x00
            p1[9] = 0x00
            p1[10] = 0x01
            p1[11] = 0x00
            p1[12] = code
            packets.append(p1)
            
            // Second packet: 03 fd fe ff
            var p2 = [UInt8](repeating: 0, count: 64)
            p2[0] = 0x03
            p2[1] = 0xfd
            p2[2] = 0xfe
            p2[3] = 0xff
            packets.append(p2)
            
        case .ch57x_2:
            let modeVal: UInt8
            switch mode {
            case .off: modeVal = 0
            case .backlight: modeVal = 1
            case .shock: modeVal = 2
            case .shock2: modeVal = 3
            case .press: modeVal = 4
            }
            
            var p1 = [UInt8](repeating: 0, count: 64)
            p1[0] = 0x03
            p1[1] = 0xa1
            p1[2] = 0x01
            packets.append(p1)
            
            var p2 = [UInt8](repeating: 0, count: 64)
            p2[0] = 0x03
            p2[1] = 0xb0
            p2[2] = 0x18
            p2[3] = modeVal
            packets.append(p2)
            
            var p3 = [UInt8](repeating: 0, count: 64)
            p3[0] = 0x03
            p3[1] = 0xaa
            p3[2] = 0xa1
            packets.append(p3)
        }
        return packets
    }
}

private extension Int8 {
    init(clamping value: Int) {
        if value < Int(Int8.min) {
            self = Int8.min
        } else if value > Int(Int8.max) {
            self = Int8.max
        } else {
            self = Int8(value)
        }
    }
}
