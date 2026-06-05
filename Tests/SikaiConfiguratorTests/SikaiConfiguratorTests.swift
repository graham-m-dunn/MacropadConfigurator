import XCTest
@testable import SikaiConfigurator

final class SikaiConfiguratorTests: XCTestCase {
    
    func testKeyIDMappingCh57x2() {
        // Buttons (0-indexed) mapping to IDs (1-based)
        XCTAssertEqual(Protocol.toKeyID(key: .button(0), model: .ch57x_2), 1)
        XCTAssertEqual(Protocol.toKeyID(key: .button(1), model: .ch57x_2), 2)
        XCTAssertEqual(Protocol.toKeyID(key: .button(11), model: .ch57x_2), 12)
        
        // Knobs mapping to IDs
        XCTAssertEqual(Protocol.toKeyID(key: .knob(0, .rotateCCW), model: .ch57x_2), 13)
        XCTAssertEqual(Protocol.toKeyID(key: .knob(0, .press), model: .ch57x_2), 14)
        XCTAssertEqual(Protocol.toKeyID(key: .knob(0, .rotateCW), model: .ch57x_2), 15)
        XCTAssertEqual(Protocol.toKeyID(key: .knob(1, .rotateCCW), model: .ch57x_2), 16)
    }
    
    func testKeyIDMappingCh57x1() {
        XCTAssertEqual(Protocol.toKeyID(key: .button(0), model: .ch57x_1), 1)
        XCTAssertEqual(Protocol.toKeyID(key: .button(14), model: .ch57x_1), 15)
        
        // Knobs mapping to IDs
        XCTAssertEqual(Protocol.toKeyID(key: .knob(0, .rotateCCW), model: .ch57x_1), 16)
        XCTAssertEqual(Protocol.toKeyID(key: .knob(0, .press), model: .ch57x_1), 17)
        XCTAssertEqual(Protocol.toKeyID(key: .knob(0, .rotateCW), model: .ch57x_1), 18)
        
        // Special case fourth knob
        XCTAssertEqual(Protocol.toKeyID(key: .knob(3, .rotateCCW), model: .ch57x_1), 13)
    }
    
    func testBuildPacketsCh57x2Keyboard() {
        let key = Key.button(0)
        let macro = KeyMacro.keyboard(modifiers: [.ctrl], keys: [0x04]) // Ctrl + A
        let packets = Protocol.buildPackets(key: key, layer: 0, macro: macro, model: .ch57x_2)
        
        // Ctrl+A keyboard macro builds:
        // Packet 0: Start binding [0x03, 0xfe, 0x01, 0x01, 0x01]
        // Packet 1: Empty packet [0x03, 0x01, 0x11, 0x01, 0x00, 0x00, 0x00]
        // Packet 2: Key press [0x03, 0x01, 0x11, 0x01, 0x01, 0x01, 0x04]
        // Packet 3: Finish binding [0x03, 0xaa, 0xaa]
        XCTAssertEqual(packets.count, 4)
        
        XCTAssertEqual(packets[0][0], 0x03)
        XCTAssertEqual(packets[0][1], 0xfe)
        XCTAssertEqual(packets[0][2], 0x01) // layer 1
        
        XCTAssertEqual(packets[1][0], 0x03)
        XCTAssertEqual(packets[1][1], 1) // Key ID 1
        XCTAssertEqual(packets[1][2], 0x11) // (layer 1 << 4) | 1 = 0x11
        XCTAssertEqual(packets[1][3], 1) // length = 1
        XCTAssertEqual(packets[1][4], 0) // index 0 (empty packet)
        
        XCTAssertEqual(packets[2][4], 1) // index 1
        XCTAssertEqual(packets[2][5], 0x01) // Ctrl modifier
        XCTAssertEqual(packets[2][6], 0x04) // Key A scancode
        
        XCTAssertEqual(packets[3][0], 0x03)
        XCTAssertEqual(packets[3][1], 0xaa)
        XCTAssertEqual(packets[3][2], 0xaa)
    }
}
