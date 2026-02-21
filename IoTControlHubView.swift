#if os(iOS)
import SwiftUI
import CoreBluetooth

@available(iOS 16.0, *)
struct IoTControlHubView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var showingConnectionSheet = false
    @State private var selectedDevice: IoTDevice?
    @State private var activeTab: IoTTab = .devices
    @State private var showSettings = false
    
    enum IoTTab: String {
        case devices = "DEVICES"
        case components = "COMPONENTS"
        case training = "TRAINING"
    }
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
                // Background: Blueprint Grid
                Color.black.ignoresSafeArea()
                
                GeometryReader { geo in
                    ZStack {
                        // Moving grid lines for flair
                        ForEach(0..<10) { i in
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: geo.size.height / 10 * CGFloat(i)))
                                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 10 * CGFloat(i)))
                            }
                            .stroke(neonCyan.opacity(0.1), lineWidth: 0.5)
                        }
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    // Header
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(neonCyan)
                            .font(.system(size: 20, weight: .bold))
                        
                        Spacer()
                        
                        Text("IOT CONTROL")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        
                        Spacer()
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(neonCyan)
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Tab Picker
                    Picker("IoT Section", selection: $activeTab) {
                        Text(IoTTab.devices.rawValue).tag(IoTTab.devices)
                        Text(IoTTab.components.rawValue).tag(IoTTab.components)
                        Text(IoTTab.training.rawValue).tag(IoTTab.training)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    
                    if activeTab == .devices {
                        // Device Discovery Panel
                        DeviceDiscoveryPanel(bluetoothManager: bluetoothManager, selectedDevice: $selectedDevice)
                        
                        // Robot Controls Section
                        if let selectedDevice = selectedDevice {
                            RobotControlPanel(device: selectedDevice)
                        }
                    } else if activeTab == .components {
                        IoTComponentLibraryView()
                    } else if activeTab == .training {
                        IoTLearningGameView()
                    }
                    
                    Spacer()
                }
                .padding(.top, 10)
            }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            IoTSettingsSheet(bluetoothManager: bluetoothManager)
        }
    }
}

// MARK: - IoT Settings Sheet

@available(iOS 16.0, *)
struct IoTSettingsSheet: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Environment(\.dismiss) var dismiss
    @State private var autoScanEnabled = true
    @State private var showSignalStrength = true
    @State private var showDeviceLabels = true
    @State private var scanTimeout: Double = 30
    @State private var showClearAlert = false
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Background grid
            GeometryReader { geo in
                ForEach(0..<12) { i in
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geo.size.height / 12 * CGFloat(i)))
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 12 * CGFloat(i)))
                    }
                    .stroke(neonCyan.opacity(0.07), lineWidth: 0.5)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(neonCyan)
                    }
                    Spacer()
                    Text("IOT SETTINGS")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                    Spacer()
                    Color.clear.frame(width: 24) // balance
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                Rectangle()
                    .fill(neonCyan.opacity(0.3))
                    .frame(height: 1)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // ─── SCANNING ───
                        SettingsSection(title: "SCANNING") {
                            VStack(spacing: 12) {
                                Toggle(isOn: $autoScanEnabled) {
                                    HStack {
                                        Text("Auto-Scan on Launch")
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(autoScanEnabled ? "ON" : "OFF")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(autoScanEnabled ? neonCyan : .gray)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: neonCyan))
                                
                                Divider().background(neonCyan.opacity(0.1))
                                
                                VStack(spacing: 6) {
                                    HStack {
                                        Text("Scan Timeout")
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(Int(scanTimeout))s")
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(neonCyan)
                                    }
                                    Slider(value: $scanTimeout, in: 10...120, step: 5)
                                        .accentColor(neonCyan)
                                }
                            }
                        }
                        
                        // ─── DISPLAY ───
                        SettingsSection(title: "DISPLAY") {
                            VStack(spacing: 12) {
                                Toggle(isOn: $showSignalStrength) {
                                    HStack {
                                        Text("Signal Strength Bars")
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(showSignalStrength ? "ON" : "OFF")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(showSignalStrength ? neonCyan : .gray)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: neonCyan))
                                
                                Divider().background(neonCyan.opacity(0.1))
                                
                                Toggle(isOn: $showDeviceLabels) {
                                    HStack {
                                        Text("Device Type Labels")
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(showDeviceLabels ? "ON" : "OFF")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(showDeviceLabels ? neonCyan : .gray)
                                    }
                                }
                                .toggleStyle(SwitchToggleStyle(tint: neonCyan))
                            }
                        }
                        
                        // ─── ACTIONS ───
                        SettingsSection(title: "ACTIONS") {
                            VStack(spacing: 10) {
                                ActionRow(
                                    icon: "arrow.clockwise",
                                    label: "RESCAN DEVICES",
                                    color: neonCyan,
                                    action: {
                                        bluetoothManager.startScan()
                                        dismiss()
                                    }
                                )
                                
                                Divider().background(neonCyan.opacity(0.1))
                                
                                ActionRow(
                                    icon: "trash",
                                    label: "CLEAR DISCOVERED DEVICES",
                                    color: .orange,
                                    action: { showClearAlert = true }
                                )
                            }
                        }
                        
                        // ─── INFO ───
                        SettingsSection(title: "ABOUT") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Bluetooth")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                        Text("ACTIVE")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(.green)
                                    }
                                }
                                HStack {
                                    Text("Devices Found")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("\(bluetoothManager.discoveredDevices.count)")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonCyan)
                                }
                                HStack {
                                    Text("IoT Hub Version")
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("v2.0")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonCyan)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Clear Devices", isPresented: $showClearAlert) {
            Button("CLEAR", role: .destructive) {
                bluetoothManager.discoveredDevices.removeAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear all discovered devices from the list. You can rescan to find them again.")
        }
    }
}

@available(iOS 16.0, *)
struct DeviceDiscoveryPanel: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Binding var selectedDevice: IoTDevice?
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("DEVICE DISCOVERY")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: { bluetoothManager.startScan() }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(neonCyan)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 16)
            
            // Device List
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(bluetoothManager.discoveredDevices, id: \.id) { device in
                        DeviceRowView(device: device, bluetoothManager: bluetoothManager) {
                            selectedDevice = device
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 10)
        .background(
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark) {
                Rectangle().fill(Color.clear)
            }
            .opacity(0.85)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(neonCyan.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }
}

@available(iOS 16.0, *)
struct DeviceRowView: View {
    let device: IoTDevice
    @ObservedObject var bluetoothManager: BluetoothManager
    let onTap: () -> Void
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        HStack {
            // Device Icon
            ZStack {
                Circle()
                    .fill(neonCyan.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: device.icon)
                    .foregroundColor(neonCyan)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(device.type.rawValue)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Signal Strength
            HStack(spacing: 2) {
                ForEach(0..<5) { level in
                    Rectangle()
                        .fill(level < device.signalStrength ? neonCyan : .gray.opacity(0.3))
                        .frame(width: 3, height: CGFloat(level * 3 + 3))
                }
            }
            .frame(width: 30)
            
            // Connect/Disconnect Button
            Button(action: {
                if device.connectionStatus == .connected {
                    bluetoothManager.disconnectFromDevice(device)
                } else {
                    bluetoothManager.connectToDevice(device)
                }
            }) {
                Text(device.connectionStatus == .connected ? "DISCONNECT" : "CONNECT")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(device.connectionStatus == .connected ? .red : neonCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        device.connectionStatus == .connected ?
                            Color.red.opacity(0.1) : Color.black.opacity(0.4)
                    )
                    .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Connection Status
            Circle()
                .fill(connectionColor)
                .frame(width: 10, height: 10)
                .padding(.leading, 8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.4))
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var connectionColor: Color {
        switch device.connectionStatus {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected: return .red
        }
    }
}

@available(iOS 16.0, *)
struct RobotControlPanel: View {
    var device: IoTDevice
    @StateObject private var bluetoothManager = BluetoothManager()
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            Text("ROBOTICS LIVE SYNC")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            if device.connectionStatus == .connected {
                // Motor Speed Slider
                VStack(spacing: 8) {
                    HStack {
                        Text("MOTOR SPEED")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        
                        Spacer()
                        
                        Text("\(Int(device.motorSpeed)) RPM")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(device.motorSpeed) },
                        set: { newValue in
                            var updatedDevice = device
                            updatedDevice.motorSpeed = Float(newValue)
                            bluetoothManager.sendCommand(.setMotorSpeed(Float(newValue)), to: updatedDevice)
                        }
                    ), in: 0...100, step: 1)
                        .accentColor(neonCyan)
                }
                .padding(.horizontal, 16)
                
                // Servo Angle Knob
                VStack(spacing: 8) {
                    HStack {
                        Text("SERVO ANGLE")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        
                        Spacer()
                        
                        Text("\(Int(device.servoAngle))°")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                    
                    Slider(value: Binding(
                        get: { Double(device.servoAngle) }, 
                        set: { newValue in
                            var updatedDevice = device
                            updatedDevice.servoAngle = Float(newValue)
                            bluetoothManager.sendCommand(.setServoAngle(Float(newValue)), to: updatedDevice)
                        }
                    ), in: 0...180, step: 1)
                        .accentColor(neonCyan)
                }
                .padding(.horizontal, 16)
                
                // Direction Toggle
                HStack {
                    Text("DIRECTION")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            var updatedDevice = device
                            updatedDevice.direction = .counterClockwise
                            bluetoothManager.sendCommand(.setDirection(.counterClockwise), to: updatedDevice)
                        }) {
                            Text("CCW")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(device.direction == .counterClockwise ? .black : neonCyan)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(device.direction == .counterClockwise ? neonCyan : Color.black.opacity(0.4))
                                .cornerRadius(6)
                        }
                        
                        Button(action: {
                            var updatedDevice = device
                            updatedDevice.direction = .clockwise
                            bluetoothManager.sendCommand(.setDirection(.clockwise), to: updatedDevice)
                        }) {
                            Text("CW")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(device.direction == .clockwise ? .black : neonCyan)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(device.direction == .clockwise ? neonCyan : Color.black.opacity(0.4))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                // Emergency Stop
                Button(action: {
                    if device.connectionStatus == .connected {
                        bluetoothManager.sendCommand(.emergencyStop, to: device)
                    }
                }) {
                    Text("EMERGENCY STOP")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            } else {
                Text("NO DEVICE CONNECTED")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 100)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
            }
        }
        .padding(.vertical, 10)
        .background(
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark) {
                Rectangle().fill(Color.clear)
            }
            .opacity(0.85)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(neonCyan.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - IoT Device Models and Bluetooth Manager

@available(iOS 16.0, *)
enum DeviceType: String, CaseIterable {
    case esp32 = "ESP32"
    case arduino = "Arduino"
    case raspberryPi = "Raspberry Pi"
    case educationalRobot = "Educational Robot"
    case other = "Other"
}

@available(iOS 16.0, *)
enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
}

@available(iOS 16.0, *)
enum RotationDirection {
    case clockwise
    case counterClockwise
}

enum IoTCommand {
    case setMotorSpeed(Float)
    case setServoAngle(Float)
    case setDirection(RotationDirection)
    case emergencyStop
}

@available(iOS 16.0, *)
struct IoTDevice: Identifiable {
    let id = UUID()
    let name: String
    let type: DeviceType
    var signalStrength: Int // 0-5 bars
    var connectionStatus: ConnectionStatus
    var motorSpeed: Float = 0
    var servoAngle: Float = 90
    var direction: RotationDirection = .clockwise
    var sensorTelemetry: [String: Float] = [:]
    
    var icon: String {
        switch type {
        case .esp32: return "chip"
        case .arduino: return "circuitgroup"
        case .raspberryPi: return "computerdesktop"
        case .educationalRobot: return "figure.2.arms.open"
        case .other: return "cpu"
        }
    }
}

@available(iOS 16.0, *)
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var discoveredDevices: [IoTDevice] = []
    @Published var isConnected = false
    
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [CBPeripheral: IoTDevice] = [:]
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        discoveredPeripherals.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func connectToDevice(_ device: IoTDevice) {
        if let peripheral = discoveredPeripherals.first(where: { $0.value.id == device.id })?.key {
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func disconnectFromDevice(_ device: IoTDevice) {
        if let peripheral = discoveredPeripherals.first(where: { $0.value.id == device.id })?.key {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            startScan()
        case .poweredOff:
            print("Bluetooth is powered off")
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .unsupported:
            print("Bluetooth is unsupported")
        default:
            print("Bluetooth state: \(central.state)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceType = determineDeviceType(from: advertisementData)
        let signalBars = calculateSignalBars(from: RSSI)
        
        let iotDevice = IoTDevice(
            name: peripheral.name ?? "Unknown Device",
            type: deviceType,
            signalStrength: signalBars,
            connectionStatus: .disconnected,
            motorSpeed: 0,
            servoAngle: 90,
            direction: .clockwise
        )
        
        discoveredPeripherals[peripheral] = iotDevice
        self.discoveredDevices = Array(self.discoveredPeripherals.values)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let device = discoveredPeripherals[peripheral] {
            var updatedDevice = device
            updatedDevice.connectionStatus = .connected
            discoveredPeripherals[peripheral] = updatedDevice
            self.discoveredDevices = Array(self.discoveredPeripherals.values)
            
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let device = discoveredPeripherals[peripheral] {
            var updatedDevice = device
            updatedDevice.connectionStatus = .disconnected
            discoveredPeripherals[peripheral] = updatedDevice
            self.discoveredDevices = Array(self.discoveredPeripherals.values)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let device = discoveredPeripherals[peripheral] {
            var updatedDevice = device
            updatedDevice.connectionStatus = .disconnected
            discoveredPeripherals[peripheral] = updatedDevice
            self.discoveredDevices = Array(self.discoveredPeripherals.values)
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic: \(error.localizedDescription)")
            return
        }
        guard let value = characteristic.value else { return }
        processReceivedData(value, for: characteristic)
    }
    
    // MARK: - Helper Methods
    
    private func determineDeviceType(from advertisementData: [String: Any]) -> DeviceType {
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            if name.lowercased().contains("esp") {
                return .esp32
            } else if name.lowercased().contains("arduino") {
                return .arduino
            } else if name.lowercased().contains("pi") {
                return .raspberryPi
            } else if name.lowercased().contains("robot") || name.lowercased().contains("bot") {
                return .educationalRobot
            }
        }
        return .other
    }
    
    private func calculateSignalBars(from rssi: NSNumber) -> Int {
        let rssiValue = rssi.intValue
        if rssiValue >= -50 { return 5 }
        else if rssiValue >= -60 { return 4 }
        else if rssiValue >= -70 { return 3 }
        else if rssiValue >= -80 { return 2 }
        else { return 1 }
    }

    private func processReceivedData(_ data: Data, for characteristic: CBCharacteristic) {
        print("Received data from characteristic \(characteristic.uuid): \(data)")
    }
    
    func sendCommand(_ command: IoTCommand, to device: IoTDevice) {
        if let peripheral = discoveredPeripherals.first(where: { pair in pair.value.id == device.id })?.key,
           peripheral.state == .connected {
            let commandData = encodeCommand(command)
            if let service = peripheral.services?.first,
               let characteristic = service.characteristics?.first(where: { char in char.properties.contains(.write) }) {
                peripheral.writeValue(commandData, for: characteristic, type: .withResponse)
            }
        }
    }
    
    private func encodeCommand(_ command: IoTCommand) -> Data {
        switch command {
        case .setMotorSpeed(let speed):
            return Data([0x01, UInt8(speed)])
        case .setServoAngle(let angle):
            return Data([0x02, UInt8(angle)])
        case .setDirection(let direction):
            let directionByte: UInt8 = direction == .clockwise ? 0x00 : 0x01
            return Data([0x03, directionByte])
        case .emergencyStop:
            return Data([0xFF])
        }
    }
}

@available(iOS 16.0, *)
struct IoTComponentLibraryView: View {
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    @State private var selectedComponent: IoTComponent?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(ComponentCategory.allCases, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(category.rawValue.uppercased())
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(IoTComponentsDatabase.shared.getComponents(by: category)) { comp in
                                ComponentCardView(component: comp) {
                                    selectedComponent = comp
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 10)
        }
        .sheet(item: $selectedComponent) { comp in
            ComponentDetailView(component: comp)
        }
    }
}

@available(iOS 16.0, *)
struct ComponentCardView: View {
    let component: IoTComponent
    let onTap: () -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(neonCyan.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Circle()
                            .stroke(neonCyan.opacity(0.3), lineWidth: 1)
                            .frame(width: 52, height: 52)
                        
                        if let path = Bundle.main.path(forResource: component.componentImageName, ofType: "png"),
                           let uiImage = UIImage(contentsOfFile: path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else if let uiImage = UIImage(named: component.componentImageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: component.iconName)
                                .foregroundColor(neonCyan)
                                .font(.system(size: 22))
                                .shadow(color: neonCyan.opacity(0.4), radius: 6)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(component.name)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text(component.category.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(neonCyan.opacity(0.5))
                }
                
                Text(component.description)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .padding(.top, 2)
            }
            .padding(14)
            .background(
                VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark) {
                    Rectangle().fill(Color.clear)
                }
                .opacity(0.85)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(neonCyan.opacity(0.2), lineWidth: 0.5)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = pressing }
        }, perform: {})
    }
}

// MARK: - Component Detail View

@available(iOS 16.0, *)
struct ComponentDetailView: View {
    let component: IoTComponent
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let starkWhite = Color(red: 0.9, green: 0.95, blue: 1.0)
    @Environment(\.dismiss) var dismiss
    
    @State private var rotatingAngle: Double = 0
    @State private var lineProgress: CGFloat = 0.0
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.08, blue: 0.15).ignoresSafeArea()
            EngineeringGridBackground(cyanColor: neonCyan)
                .opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Map
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(neonCyan)
                    }
                    Spacer()
                    Text("COMPONENT_ANALYSIS")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan.opacity(0.8))
                    Spacer()
                    Image(systemName: "cpu")
                        .foregroundColor(neonCyan)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 40) {
                        
                        // Holographic Arc Reactor Core representation
                        ZStack {
                            Circle()
                                .stroke(neonCyan.opacity(0.3), lineWidth: 1)
                                .frame(width: 260, height: 260)
                            
                            Circle()
                                .stroke(neonCyan.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                                .frame(width: 240, height: 240)
                                .rotationEffect(.degrees(rotatingAngle))
                            
                            Circle()
                                .trim(from: 0, to: lineProgress)
                                .stroke(starkWhite, lineWidth: 4)
                                .frame(width: 220, height: 220)
                                .rotationEffect(.degrees(-90))
                            
                            // Technical diagram lines
                            Path { path in
                                path.move(to: CGPoint(x: 130, y: 0))
                                path.addLine(to: CGPoint(x: 130, y: 260))
                                path.move(to: CGPoint(x: 0, y: 130))
                                path.addLine(to: CGPoint(x: 260, y: 130))
                            }
                            .trim(from: 0, to: lineProgress)
                            .stroke(neonCyan.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .frame(width: 260, height: 260)
                            
                            // Core Geometry (Image)
                            if let path = Bundle.main.path(forResource: component.componentImageName, ofType: "png"),
                               let uiImage = UIImage(contentsOfFile: path) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                                    .colorMultiply(neonCyan) // Holographic effect
                                    .opacity(textOpacity)
                                    .shadow(color: neonCyan, radius: 20)
                            } else if let uiImage = UIImage(named: component.componentImageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 140, height: 140)
                                    .clipShape(Circle())
                                    .colorMultiply(neonCyan)
                                    .opacity(textOpacity)
                                    .shadow(color: neonCyan, radius: 20)
                            } else {
                                Image(systemName: component.iconName)
                                    .font(.system(size: 60))
                                    .foregroundColor(neonCyan)
                                    .opacity(textOpacity)
                                    .shadow(color: neonCyan, radius: 20)
                            }
                            
                            // Data Nodes Bridging Out
                            if textOpacity > 0.5 {
                                VStack(spacing: 210) {
                                    HStack {
                                        BlueprintDataNode(title: "ID", val1: String(component.name.prefix(12)), val2: component.category.rawValue.uppercased(), color: neonCyan)
                                        Spacer()
                                        BlueprintDataNode(title: "SPEC", val1: "PINS: \(component.pinout.count)", val2: "STATUS: ACTIVE", color: neonCyan)
                                    }
                                    HStack {
                                        BlueprintDataNode(title: "USE CASE", val1: "ANALYSIS", val2: "OP: NORMAL", color: neonCyan)
                                        Spacer()
                                        BlueprintDataNode(title: "PWR", val1: "VOLTAGE: 3.3V/5V", val2: "DRAW: NOMINAL", color: neonCyan)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(height: 300)
                        
                        // Remaining details below as blueprint panels
                        VStack(spacing: 16) {
                            BlueprintPanel(title: "PROTOCOL DESCRIPTION", content: component.description, color: neonCyan)
                            
                            if !component.pinout.isEmpty {
                                let pinsString = component.pinout.map { "\($0.pin) -> \($0.label)" }.joined(separator: "\n")
                                BlueprintPanel(title: "TERMINAL MAPPING (PINS)", content: pinsString, color: neonCyan)
                            }
                            
                            BlueprintPanel(title: "INTEGRATION DIRECTIVES", content: component.connectionGuide, color: neonCyan)
                        }
                        .padding(.horizontal, 20)
                        .opacity(textOpacity)
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 30)
                }
            }
        }
        .onAppear {
            lineProgress = 0.0
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                rotatingAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.5)) {
                lineProgress = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    textOpacity = 1.0
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct BlueprintPanel: View {
    let title: String
    let content: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
                .border(color.opacity(0.5), width: 1)
            
            Text(content)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.3))
                .border(color.opacity(0.3), width: 1)
        }
    }
}

@available(iOS 16.0, *)
struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(neonCyan)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
            }
            
            VStack(alignment: .leading) {
                content
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.03))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(neonCyan.opacity(0.12), lineWidth: 0.5)
            )
            .cornerRadius(12)
        }
    }
}

@available(iOS 16.0, *)
struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 8) {
                ForEach(buildRows(maxWidth: geo.size.width), id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(row, id: \.self) { item in
                            content(item)
                        }
                    }
                }
            }
        }
        .frame(minHeight: 40)
    }
    
    private func buildRows(maxWidth: CGFloat) -> [[Item]] {
        var rows: [[Item]] = [[]]
        var currentWidth: CGFloat = 0
        let itemWidth: CGFloat = 120
        let spacing: CGFloat = 8
        
        for item in items {
            if currentWidth + itemWidth + spacing > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentWidth = 0
            }
            rows[rows.count - 1].append(item)
            currentWidth += itemWidth + spacing
        }
        return rows
    }
}
#endif