#if os(iOS)
import SwiftUI
import CoreBluetooth

@available(iOS 16.0, *)
struct IoTControlHubView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var showingConnectionSheet = false
    @State private var selectedDevice: IoTDevice?
    @State private var activeTab: IoTTab = .devices
    
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
                        
                        Button(action: {}) {
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
                        Image(systemName: component.iconName)
                            .foregroundColor(neonCyan)
                            .font(.system(size: 22))
                            .shadow(color: neonCyan.opacity(0.4), radius: 6)
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
    @Environment(\.dismiss) var dismiss
    
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
            
            ScrollView {
                VStack(spacing: 0) {
                    // Hero section with large icon
                    ZStack {
                        // Glow circles
                        Circle()
                            .fill(neonCyan.opacity(0.04))
                            .frame(width: 200, height: 200)
                        Circle()
                            .stroke(neonCyan.opacity(0.1), lineWidth: 1)
                            .frame(width: 160, height: 160)
                        Circle()
                            .stroke(neonCyan.opacity(0.15), lineWidth: 2)
                            .frame(width: 120, height: 120)
                        Circle()
                            .fill(neonCyan.opacity(0.08))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: component.iconName)
                            .font(.system(size: 52))
                            .foregroundColor(neonCyan)
                            .shadow(color: neonCyan.opacity(0.6), radius: 20)
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [neonCyan.opacity(0.05), Color.black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // Name & category
                        VStack(alignment: .leading, spacing: 6) {
                            Text(component.name)
                                .font(.system(size: 26, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                            Text(component.category.rawValue.uppercased())
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan)
                        }
                        
                        // Description
                        Text(component.description)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                        
                        // Use Case
                        DetailSection(title: "USE CASE", icon: "lightbulb.fill") {
                            Text(component.useCase)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.white.opacity(0.85))
                                .lineSpacing(3)
                        }
                        
                        // Specifications
                        DetailSection(title: "SPECIFICATIONS", icon: "list.bullet.clipboard.fill") {
                            VStack(spacing: 8) {
                                ForEach(component.specs.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    HStack(alignment: .top) {
                                        Text(key)
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(.gray)
                                            .frame(width: 130, alignment: .leading)
                                        Text(value)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    if key != component.specs.sorted(by: { $0.key < $1.key }).last?.key {
                                        Divider().background(neonCyan.opacity(0.1))
                                    }
                                }
                            }
                        }
                        
                        // Pin Connections
                        DetailSection(title: "PIN CONNECTIONS", icon: "point.3.connected.trianglepath.dotted") {
                            VStack(spacing: 10) {
                                ForEach(component.pinout) { pin in
                                    HStack(alignment: .top, spacing: 10) {
                                        Text(pin.pin)
                                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(neonCyan)
                                            .cornerRadius(4)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(pin.label)
                                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                                .foregroundColor(.white)
                                            Text(pin.description)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.gray)
                                                .lineSpacing(2)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // How to Connect
                        DetailSection(title: "HOW TO CONNECT", icon: "cable.connector") {
                            VStack(alignment: .leading, spacing: 0) {
                                let steps = component.connectionGuide.components(separatedBy: "\n")
                                ForEach(steps.indices, id: \.self) { i in
                                    if !steps[i].trimmingCharacters(in: .whitespaces).isEmpty {
                                        HStack(alignment: .top, spacing: 10) {
                                            if steps[i].hasPrefix("⚠️") {
                                                Text(steps[i])
                                                    .font(.system(size: 12, design: .monospaced))
                                                    .foregroundColor(.orange)
                                                    .lineSpacing(3)
                                            } else {
                                                Text(steps[i])
                                                    .font(.system(size: 12, design: .monospaced))
                                                    .foregroundColor(.white.opacity(0.85))
                                                    .lineSpacing(3)
                                            }
                                        }
                                        .padding(.bottom, 6)
                                    }
                                }
                            }
                        }
                        
                        // Related Components
                        if !component.relatedComponents.isEmpty {
                            DetailSection(title: "PAIRS WELL WITH", icon: "link.circle.fill") {
                                FlowLayout(items: component.relatedComponents) { item in
                                    Text(item)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonCyan)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(neonCyan.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(neonCyan.opacity(0.3), lineWidth: 0.5)
                                        )
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(20)
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(neonCyan)
                            .shadow(color: neonCyan.opacity(0.4), radius: 8)
                    }
                    .padding(16)
                }
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
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