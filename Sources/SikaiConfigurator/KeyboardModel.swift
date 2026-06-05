import Foundation

public enum KeyboardModel: String, Codable, CaseIterable {
    case ch57x_1 = "CH57x Model 1 (8840/8842/8850/8851)"
    case ch57x_2 = "CH57x Model 2 (8890)"
    
    public var defaultPID: UInt16 {
        switch self {
        case .ch57x_1: return 0x8840
        case .ch57x_2: return 0x8890
        }
    }
    
    public var preferredEndpoint: UInt8 {
        switch self {
        case .ch57x_1: return 0x04
        case .ch57x_2: return 0x02
        }
    }
    
    public static func from(productID: UInt16) -> KeyboardModel? {
        switch productID {
        case 0x8840, 0x8842, 0x8850, 0x8851:
            return .ch57x_1
        case 0x8890:
            return .ch57x_2
        default:
            return nil
        }
    }
}

public enum Key: Hashable, CustomStringConvertible {
    case button(Int)        // 0-indexed button index
    case knob(Int, KnobAction) // 0-indexed knob index, action type
    
    public var description: String {
        switch self {
        case .button(let index):
            return "Button \(index + 1)"
        case .knob(let index, let action):
            return "Knob \(index + 1) \(action.description)"
        }
    }
}

public enum KnobAction: Int, Hashable, CaseIterable, CustomStringConvertible {
    case rotateCCW = 0
    case press = 1
    case rotateCW = 2
    
    public var description: String {
        switch self {
        case .rotateCCW: return "Rotate CCW"
        case .press: return "Press"
        case .rotateCW: return "Rotate CW"
        }
    }
}
