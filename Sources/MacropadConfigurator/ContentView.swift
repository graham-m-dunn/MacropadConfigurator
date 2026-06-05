import SwiftUI
import UniformTypeIdentifiers

public struct ContentView: View {
    @StateObject private var hidService = HIDService()
    
    @State private var selectedLayer: UInt8 = 0
    @State private var selectedKey: Key = .button(0)
    
    // Configurator States
    @State private var macroType: Int = 0 // 0: Keyboard, 1: Media, 2: Mouse
    
    // Keyboard Macro States
    @State private var ctrlModifier = false
    @State private var shiftModifier = false
    @State private var altModifier = false
    @State private var winModifier = false
    @State private var selectedKeys: [UInt8] = []
    
    // Media Macro States
    @State private var selectedMediaCode: UInt16 = 0xcd // Play/Pause default
    
    // Mouse Macro States
    @State private var mouseAction: MouseActionType = .click
    @State private var selectedMouseButton: UInt8 = 0x01 // Left Click default
    @State private var mouseDX: Int = 0
    @State private var mouseDY: Int = 0
    @State private var mouseScroll: Int = 0
    
    // In-memory mappings cache to show in the visual buttons
    @State private var mockMappings: [String: KeyMacro] = [:]
    
    // LED States
    @State private var ledModeSelection: Int = 0 // 0: Off, 1: Backlight, 2: Shock, 3: Shock2, 4: Press
    @State private var ledColorSelection: LEDColor = .cyan
    @State private var ledBacklightColorSelection: LEDBacklightColor = .cyan
    
    public init() {}
    
    private var activeModifiers: ModifierFlags {
        var flags = ModifierFlags()
        if ctrlModifier { flags.insert(.ctrl) }
        if shiftModifier { flags.insert(.shift) }
        if altModifier { flags.insert(.alt) }
        if winModifier { flags.insert(.win) }
        return flags
    }
    
    private var activeLEDMode: LEDMode {
        switch ledModeSelection {
        case 0: return .off
        case 1: return .backlight(ledBacklightColorSelection)
        case 2: return .shock(ledColorSelection)
        case 3: return .shock2(ledColorSelection)
        case 4: return .press(ledColorSelection)
        default: return .off
        }
    }
    
    private func mappingKey(key: Key, layer: UInt8) -> String {
        return "\(key.description)-L\(layer)"
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // SIDEBAR: Layers & Status
            VStack(alignment: .leading, spacing: 20) {
                // Connection Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(hidService.isConnected ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                        .shadow(color: hidService.isConnected ? .green : .red, radius: 4)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hidService.isConnected ? "Connected" : "Disconnected")
                            .font(.headline)
                        Text(hidService.connectedDeviceName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if hidService.isConnected {
                        Spacer()
                        Button(action: { hidService.startReading() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .help("Reload configuration from device")
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // Layers Selection
                Text("Layers")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { layer in
                        let isSupported = layer == 0 || (hidService.isConnected && hidService.connectedModel == .ch57x_2)
                        Button(action: {
                            if isSupported {
                                selectedLayer = UInt8(layer)
                                loadConfigurationForSelectedKey()
                            }
                        }) {
                            HStack {
                                Text("Layer \(layer + 1)")
                                    .fontWeight(selectedLayer == layer ? .bold : .regular)
                                    .foregroundColor(isSupported ? .primary : .secondary.opacity(0.5))
                                Spacer()
                                if selectedLayer == layer {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(selectedLayer == layer ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                        .disabled(!isSupported)
                    }
                }
                .padding(.horizontal)
                
                if hidService.isConnected && hidService.connectedModel == .ch57x_1 {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Wired-only macro pads only support Layer 1 in hardware.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Profiles Section
                Text("Profiles")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 8) {
                    Button(action: saveBackupToFile) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Backup Profile...")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: loadBackupFromFile) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Load Profile...")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: downloadAllConfigurations) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Flash Profile")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hidService.isConnected || mockMappings.isEmpty)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Info Box
                VStack(alignment: .leading, spacing: 8) {
                    Text("3-Key Setup")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("This app configures standard 3-key macro pads via native macOS IOKit USB interfaces.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                .padding()
            }
            .frame(width: 200)
            .background(.ultraThinMaterial)
            
            Divider()
            
            // MAIN PANEL: Grid visualizer & configuration
            VStack(spacing: 0) {
                // Keyboard Visual Grid
                VStack(spacing: 12) {
                    Text("Physical Key Map")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 24) {
                        ForEach(0..<3, id: \.self) { index in
                            let keyVal = Key.button(index)
                            Button(action: {
                                selectedKey = keyVal
                                loadConfigurationForSelectedKey()
                            }) {
                                VStack(spacing: 8) {
                                    Text("Key \(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.secondary)
                                    
                                    // Visual Key Representation
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .fill(selectedKey == keyVal ? 
                                                  LinearGradient(colors: [.accentColor.opacity(0.8), .accentColor], startPoint: .top, endPoint: .bottom) :
                                                  LinearGradient(colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(selectedKey == keyVal ? Color.accentColor : Color.white.opacity(0.1), lineWidth: 2)
                                            )
                                            .shadow(color: selectedKey == keyVal ? .accentColor.opacity(0.3) : .clear, radius: 10)
                                        
                                        // Bound value preview
                                        let desc = getMacroSummary(key: keyVal)
                                        Text(desc)
                                            .font(.system(.footnote, design: .monospaced))
                                            .fontWeight(.semibold)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .padding(8)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 20)
                }
                .padding()
                .background(Color.black.opacity(0.15))
                
                Divider()
                
                // Key Action Configurator
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Configure Action for \(selectedKey.description)")
                            .font(.headline)
                            .padding(.top)
                        
                        Picker("Macro Type", selection: $macroType) {
                            Text("Keyboard").tag(0)
                            Text("Media").tag(1)
                            Text("Mouse").tag(2)
                        }
                        .pickerStyle(.segmented)
                        
                        // Panel switcher
                        if macroType == 0 {
                            keyboardConfigPanel()
                        } else if macroType == 1 {
                            mediaConfigPanel()
                        } else {
                            mouseConfigPanel()
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Buttons
                        HStack(spacing: 12) {
                            Button(action: saveConfiguration) {
                                HStack {
                                    Image(systemName: "arrow.down.to.line.compact")
                                    Text("Download to Keyboard")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!hidService.isConnected)
                            
                            Button(action: clearConfiguration) {
                                Text("Clear Key")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .disabled(!hidService.isConnected)
                            
                            Spacer()
                        }
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        ledConfigurationSection()
                            .padding(.bottom)
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Low-level Log monitor
                VStack(spacing: 0) {
                    HStack {
                        Text("Transmissions Monitor")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: exportLogs) {
                            Text("Export logs...")
                                .font(.caption2)
                        }
                        .buttonStyle(.borderless)
                        
                        Button(action: { hidService.logs.removeAll() }) {
                            Text("Clear logs")
                                .font(.caption2)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal)
                    .background(Color.black.opacity(0.2))
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(0..<hidService.logs.count, id: \.self) { i in
                                    Text(hidService.logs[i])
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(hidService.logs[i].contains("Error") ? .red : (hidService.logs[i].contains("Success") ? .green : .secondary))
                                        .id(i)
                                }
                            }
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                        }
                        .frame(height: 120)
                        .background(Color.black.opacity(0.3))
                        .onChange(of: hidService.logs.count) { _ in
                            if hidService.logs.count > 0 {
                                proxy.scrollTo(hidService.logs.count - 1, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 600)
        .onChange(of: hidService.connectedModel) { model in
            if model == .ch57x_1 {
                selectedLayer = 0
                loadConfigurationForSelectedKey()
            }
        }
        .onChange(of: selectedLayer) { _ in
            updateLEDSelectionFromLoadedConfig()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MacropadConfigReadDone"))) { _ in
            self.mockMappings = hidService.readMappings
            self.loadConfigurationForSelectedKey()
            self.updateLEDSelectionFromLoadedConfig()
        }
        .overlay {
            if hidService.isReading {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView(value: hidService.readProgress)
                            .progressViewStyle(.linear)
                            .frame(width: 200)
                        
                        Text("Reading Device Configuration...")
                            .font(.headline)
                        
                        Text("\(Int(hidService.readProgress * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Panel Builders
    
    @ViewBuilder
    private func keyboardConfigPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modifiers")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Toggle("Ctrl", isOn: $ctrlModifier)
                Toggle("Shift", isOn: $shiftModifier)
                Toggle("Alt/Option", isOn: $altModifier)
                Toggle("Command/Win", isOn: $winModifier)
            }
            .toggleStyle(.checkbox)
            
            Text("Key Code")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            HStack {
                Picker("Select Target Key", selection: Binding(
                    get: { selectedKeys.first ?? 0 },
                    set: { code in
                        if code == 0 {
                            selectedKeys = []
                        } else {
                            selectedKeys = [code]
                        }
                    }
                )) {
                    Text("None (Modifier Only)").tag(UInt8(0))
                    ForEach(USBKeyCode.codes) { item in
                        Text(item.name).tag(item.code)
                    }
                }
                .frame(width: 250)
                
                Spacer()
            }
            
            Text("Note: The device supports triggering the modifier keys in combination with the selected scancode (e.g. Ctrl + C).")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func mediaConfigPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Media Action")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("Media Key", selection: $selectedMediaCode) {
                ForEach(USBMediaCode.codes) { item in
                    Text(item.name).tag(item.code)
                }
            }
            .frame(width: 250)
        }
    }
    
    @ViewBuilder
    private func mouseConfigPanel() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Mouse Action", selection: $mouseAction) {
                ForEach(MouseActionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            
            switch mouseAction {
            case .click, .drag:
                Picker("Mouse Button", selection: $selectedMouseButton) {
                    ForEach(USBMouseButton.buttons) { item in
                        Text(item.name).tag(item.value)
                    }
                }
                .frame(width: 250)
                
                if mouseAction == .drag {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("dX (pixels)").font(.caption)
                            TextField("0", value: $mouseDX, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                        VStack(alignment: .leading) {
                            Text("dY (pixels)").font(.caption)
                            TextField("0", value: $mouseDY, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                }
                
            case .move:
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("dX (pixels)").font(.caption)
                        TextField("0", value: $mouseDX, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                    VStack(alignment: .leading) {
                        Text("dY (pixels)").font(.caption)
                        TextField("0", value: $mouseDY, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
                
            case .wheel:
                VStack(alignment: .leading) {
                    Text("Scroll Speed / Delta").font(.caption)
                    TextField("0", value: $mouseScroll, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }
        }
    }
    
    // MARK: - Controller Actions
    
    private func getMacroSummary(key: Key) -> String {
        let path = mappingKey(key: key, layer: selectedLayer)
        guard let macro = mockMappings[path] else {
            return "Unassigned"
        }
        
        switch macro {
        case .keyboard(let modifiers, let keys):
            var parts = [String]()
            if modifiers.contains(.ctrl) { parts.append("Ctrl") }
            if modifiers.contains(.shift) { parts.append("Shift") }
            if modifiers.contains(.alt) { parts.append("Alt") }
            if modifiers.contains(.win) { parts.append("Cmd") }
            
            if let firstCode = keys.first {
                let name = USBKeyCode.codes.first(where: { $0.code == firstCode })?.name ?? "<\(firstCode)>"
                parts.append(name)
            }
            
            return parts.isEmpty ? "None" : parts.joined(separator: " + ")
            
        case .media(let code):
            return USBMediaCode.codes.first(where: { $0.code == code })?.name ?? "Media (\(code))"
            
        case .mouse(let action, let buttons, let dx, let dy, let scroll):
            switch action {
            case .click:
                let name = USBMouseButton.buttons.first(where: { $0.value == buttons })?.name ?? "Click"
                return name
            case .drag:
                return "Drag (\(dx), \(dy))"
            case .move:
                return "Move (\(dx), \(dy))"
            case .wheel:
                return "Scroll (\(scroll))"
            }
        }
    }
    
    private func loadConfigurationForSelectedKey() {
        let path = mappingKey(key: selectedKey, layer: selectedLayer)
        if let macro = mockMappings[path] {
            switch macro {
            case .keyboard(let modifiers, let keys):
                macroType = 0
                ctrlModifier = modifiers.contains(.ctrl)
                shiftModifier = modifiers.contains(.shift)
                altModifier = modifiers.contains(.alt)
                winModifier = modifiers.contains(.win)
                selectedKeys = keys
                
            case .media(let code):
                macroType = 1
                selectedMediaCode = code
                
            case .mouse(let action, let buttons, let dx, let dy, let scroll):
                macroType = 2
                mouseAction = action
                selectedMouseButton = buttons
                mouseDX = dx
                mouseDY = dy
                mouseScroll = scroll
            }
        } else {
            // Reset to defaults
            macroType = 0
            ctrlModifier = false
            shiftModifier = false
            altModifier = false
            winModifier = false
            selectedKeys = []
            selectedMediaCode = 0xcd
            mouseAction = .click
            selectedMouseButton = 0x01
            mouseDX = 0
            mouseDY = 0
            mouseScroll = 0
        }
    }
    
    private func updateLEDSelectionFromLoadedConfig() {
        if let mode = hidService.readLEDModes[selectedLayer] {
            switch mode {
            case .off:
                ledModeSelection = 0
            case .backlight(let color):
                ledModeSelection = 1
                ledBacklightColorSelection = color
            case .shock(let color):
                ledModeSelection = 2
                ledColorSelection = color
            case .shock2(let color):
                ledModeSelection = 3
                ledColorSelection = color
            case .press(let color):
                ledModeSelection = 4
                ledColorSelection = color
            }
        }
    }
    
    private func exportLogs() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        savePanel.nameFieldStringValue = "macropad_configurator_logs.txt"
        savePanel.title = "Export Logs"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let logContent = hidService.logs.joined(separator: "\n")
                    try logContent.write(to: url, atomically: true, encoding: .utf8)
                    hidService.log("Success: Logs exported to file.")
                } catch {
                    hidService.log("Error: Failed to export logs (\(error.localizedDescription)).")
                }
            }
        }
    }
    
    private func saveConfiguration() {
        let macro: KeyMacro
        if macroType == 0 {
            macro = .keyboard(modifiers: activeModifiers, keys: selectedKeys)
        } else if macroType == 1 {
            macro = .media(selectedMediaCode)
        } else {
            macro = .mouse(action: mouseAction, buttons: selectedMouseButton, dx: mouseDX, dy: mouseDY, scroll: mouseScroll)
        }
        
        let path = mappingKey(key: selectedKey, layer: selectedLayer)
        mockMappings[path] = macro
        
        hidService.uploadConfig(key: selectedKey, layer: selectedLayer, macro: macro)
    }
    
    private func clearConfiguration() {
        let path = mappingKey(key: selectedKey, layer: selectedLayer)
        mockMappings.removeValue(forKey: path)
        
        hidService.clearConfig(key: selectedKey, layer: selectedLayer)
        loadConfigurationForSelectedKey()
    }
    
    private func saveLEDConfiguration() {
        hidService.uploadLED(layer: selectedLayer, mode: activeLEDMode)
    }
    
    @ViewBuilder
    private func ledConfigurationSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Layer LED Settings")
                .font(.headline)
                .padding(.top, 4)
            
            Picker("LED Mode", selection: $ledModeSelection) {
                Text("Off").tag(0)
                Text("Backlight").tag(1)
                Text("Shock (Reactive)").tag(2)
                Text("Shock 2 (Reactive)").tag(3)
                Text("Press (Reactive)").tag(4)
            }
            .pickerStyle(.inline)
            
            if ledModeSelection == 1 {
                Picker("Backlight Color", selection: $ledBacklightColorSelection) {
                    ForEach(LEDBacklightColor.allCases) { color in
                        Text(color.name).tag(color)
                    }
                }
                .frame(width: 250)
            } else if ledModeSelection >= 2 {
                Picker("Reactive Color", selection: $ledColorSelection) {
                    ForEach(LEDColor.allCases) { color in
                        Text(color.name).tag(color)
                    }
                }
                .frame(width: 250)
            }
            
            Button(action: saveLEDConfiguration) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                    Text("Apply LED Settings")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .disabled(!hidService.isConnected)
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func saveBackupToFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        savePanel.nameFieldStringValue = "macropad_backup.json"
        savePanel.title = "Save Macropad Backup"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = .prettyPrinted
                    let data = try encoder.encode(mockMappings)
                    try data.write(to: url)
                    hidService.log("Success: Configuration backed up to file.")
                } catch {
                    hidService.log("Error: Failed to save backup (\(error.localizedDescription)).")
                }
            }
        }
    }
    
    private func loadBackupFromFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        openPanel.title = "Load Macropad Backup"
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    let loadedMappings = try decoder.decode([String: KeyMacro].self, from: data)
                    DispatchQueue.main.async {
                        self.mockMappings = loadedMappings
                        self.loadConfigurationForSelectedKey()
                        hidService.log("Success: Loaded configuration from file.")
                    }
                } catch {
                    hidService.log("Error: Failed to parse backup file (\(error.localizedDescription)).")
                }
            }
        }
    }
    
    private func parsePath(_ path: String) -> (Key, UInt8)? {
        let parts = path.components(separatedBy: "-L")
        guard parts.count == 2, let layer = UInt8(parts[1]) else { return nil }
        
        let keyDesc = parts[0]
        if keyDesc.hasPrefix("Button ") {
            if let numStr = keyDesc.components(separatedBy: " ").last, let index = Int(numStr) {
                return (.button(index - 1), layer)
            }
        } else if keyDesc.hasPrefix("Knob ") {
            let subparts = keyDesc.components(separatedBy: " ")
            if subparts.count >= 3, let knobNum = Int(subparts[1]) {
                let actionDesc = subparts[2...].joined(separator: " ")
                let action: KnobAction
                if actionDesc.contains("CCW") {
                    action = .rotateCCW
                } else if actionDesc.contains("CW") {
                    action = .rotateCW
                } else {
                    action = .press
                }
                return (.knob(knobNum - 1, action), layer)
            }
        }
        return nil
    }
    
    private func downloadAllConfigurations() {
        guard hidService.isConnected else { return }
        
        let mappings = mockMappings
        hidService.log("Starting bulk download of \(mappings.count) mappings...")
        
        DispatchQueue.global(qos: .userInitiated).async {
            var success = true
            for (path, macro) in mappings {
                guard let (key, layer) = self.parsePath(path) else { continue }
                
                let packets = Protocol.buildPackets(key: key, layer: layer, macro: macro, model: self.hidService.connectedModel ?? .ch57x_1)
                
                for packet in packets {
                    if !self.hidService.writeReport(packet: packet) {
                        success = false
                        break
                    }
                    Thread.sleep(forTimeInterval: 0.01)
                }
                
                if !success { break }
                Thread.sleep(forTimeInterval: 0.05)
            }
            
            DispatchQueue.main.async {
                if success {
                    self.hidService.log("Success: Bulk download completed successfully.")
                } else {
                    self.hidService.log("Error: Bulk download failed midway.")
                }
            }
        }
    }
}
