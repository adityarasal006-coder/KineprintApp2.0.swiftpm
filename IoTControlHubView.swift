import SwiftUI
import CoreBluetooth
import AudioToolbox

@MainActor
struct IoTControlHubView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var showingConnectionSheet = false
    @State private var selectedDevice: IoTDevice?
    @State private var activeTab: IoTTab = .components
    @State private var showSettings = false
    @State private var isInterfacing = false
    @State private var selectedInterfacingDevice: IoTDevice?
    
    enum IoTTab: String {
        case components = "COMPONENTS"
        case training = "TRAINING"
    }
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
                // Background: Blueprint Grid
                Color.black.ignoresSafeArea()
                
                EngineeringGridBackground(cyanColor: neonCyan)
                    .opacity(0.15)
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
                    
                    // Custom Tab Bar
                    HStack(spacing: 0) {
                        ForEach([IoTTab.components, .training], id: \.self) { tab in
                            Button(action: { 
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    activeTab = tab 
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(activeTab == tab ? neonCyan : .gray.opacity(0.6))
                                    
                                    Rectangle()
                                        .fill(activeTab == tab ? neonCyan : Color.clear)
                                        .frame(height: 2)
                                        .shadow(color: activeTab == tab ? neonCyan.opacity(0.5) : .clear, radius: 4)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Hub Status Monitor
                    HStack(spacing: 20) {
                        HubHUDItem(icon: "antenna.radiowaves.left.and.right", label: "LINK", value: bluetoothManager.isConnected ? "CONNECTED" : "ACTIVE", color: bluetoothManager.isConnected ? .green : neonCyan)
                        HubHUDItem(icon: "bolt.fill", label: "PWR", value: "98%", color: .green)
                        HubHUDItem(icon: "cpu", label: "PROC", value: "LOAD: 12%", color: neonCyan)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    if activeTab == .components {
                        IoTComponentLibraryView()
                    } else if activeTab == .training {
                        IoTLearningGameView()
                    }
                    
                    Spacer()
                }
                .padding(.top, 10)
                
                // Full Screen Hardware Interfacing Animation
                if isInterfacing, let device = selectedInterfacingDevice {
                    HardwareInterfacingView(device: device, isPresented: $isInterfacing) {
                        selectedDevice = device
                    }
                    .transition(.opacity)
                }
            }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            IoTSettingsSheet(bluetoothManager: bluetoothManager)
        }
    }
}

// MARK: - IoT Settings Sheet

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
                                
                                Divider().background(neonCyan.opacity(0.1))
                                
                                Toggle(isOn: $bluetoothManager.useSimulatedDevices) {
                                    HStack {
                                        Text("Simulation Mode")
                                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(bluetoothManager.useSimulatedDevices ? "ON" : "OFF")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(bluetoothManager.useSimulatedDevices ? neonCyan : .gray)
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

struct HubHUDItem: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.1), lineWidth: 0.5))
    }
}

struct DeviceDiscoveryPanel: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    @Binding var selectedDevice: IoTDevice?
    @Binding var isInterfacing: Bool
    @Binding var interfacingDevice: IoTDevice?
    @State private var radarRotation: Double = 0
    @State private var scanningLogs: [String] = []
    @State private var spectrumHeights: [CGFloat] = Array(repeating: 5, count: 18)
    @State private var dragOffset: CGFloat = 0
    @State private var buttonPulse: Bool = false
    
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
            
            if bluetoothManager.isScanning {
                VStack(spacing: 20) {
                    HStack(alignment: .top, spacing: 20) {
                        // Radar Animation
                        ZStack {
                            Circle()
                                .stroke(neonCyan.opacity(0.1), lineWidth: 1)
                                .frame(width: 140, height: 140)
                            
                            // Pulse Ring
                            Circle()
                                .stroke(neonCyan.opacity(0.2), lineWidth: 1)
                                .frame(width: 140, height: 140)
                                .scaleEffect(radarRotation > 0 ? 1.2 : 1.0)
                                .opacity(radarRotation > 0 ? 0 : 1.0)
                            
                            // Radar Sweep
                            Circle()
                                .trim(from: 0, to: 0.15)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [.clear, neonCyan]),
                                        center: .center,
                                        startAngle: .degrees(0),
                                        endAngle: .degrees(360)
                                    ),
                                    style: StrokeStyle(lineWidth: 15, lineCap: .butt)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(radarRotation))
                            
                            if #available(iOS 17.0, *) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 24))
                                    .foregroundColor(neonCyan)
                                    .symbolEffect(.pulse)
                            } else {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 24))
                                    .foregroundColor(neonCyan)
                            }
                        }
                        
                        // Scanning Logs
                        VStack(alignment: .leading, spacing: 6) {
                            Text("SCANNING LOGS")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(scanningLogs, id: \.self) { log in
                                    Text(log)
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(neonCyan.opacity(0.8))
                                }
                            }
                            .frame(height: 80, alignment: .top)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(neonCyan.opacity(0.1), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 16)
                }
                .transition(.opacity)
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        radarRotation = 360
                    }
                    startSimulatingLogs()
                }
            }
            
            // Device List
            ScrollView {
                if bluetoothManager.discoveredDevices.isEmpty && !bluetoothManager.isScanning {
                    VStack(spacing: 20) {
                        // Environment Noise Visualizer (Isolated DANCING Bars)
                        ZStack(alignment: .bottom) {
                            HStack(alignment: .bottom, spacing: 3) {
                                ForEach(0..<18) { i in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(neonCyan.opacity(0.4))
                                        .frame(width: 4, height: spectrumHeights[i])
                                        .offset(y: sin(Double(i) + Double(dragOffset / 10)) * 3)
                                }
                            }
                            .frame(height: 40, alignment: .bottom)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 10)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                    for idx in 0..<18 {
                                        spectrumHeights[idx] = CGFloat.random(in: 10...35)
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.spring()) { dragOffset = 0 }
                                }
                        )
                        .onAppear {
                            // Only animate the heights, not the layout container
                            withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                                spectrumHeights = spectrumHeights.map { _ in CGFloat.random(in: 6...30) }
                            }
                        }
                        
                        // Mission Intel (CLEAR EXPLANATION FIRST)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(neonCyan)
                                Text("MISSION INTEL")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(neonCyan)
                            }
                            
                            Text("The Kineprint Hub is currently idle. Initialize a Deep Scan to detect structural IoT modules in your vicinity. Once detected, you can interface with hardware to extract engineering telemetry.")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                                .lineLimit(3)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                                .font(.system(size: 24))
                                .foregroundColor(.gray.opacity(0.4))
                            
                            Text("NO LOCAL ASSETS DETECTED")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        
                        // Actionable Pulsing Button (STABLE BUT ACTIVE)
                        Button(action: { 
                            let impact = UIImpactFeedbackGenerator(style: .heavy)
                            impact.impactOccurred()
                            bluetoothManager.startScan() 
                        }) {
                            Text("INITIALIZE DEEP SCAN")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 12)
                                .background(
                                    ZStack {
                                        neonCyan
                                        Capsule()
                                            .stroke(neonCyan, lineWidth: 2)
                                            .scaleEffect(buttonPulse ? 1.2 : 1.0)
                                            .opacity(buttonPulse ? 0 : 0.6)
                                    }
                                )
                                .clipShape(Capsule())
                                .shadow(color: neonCyan.opacity(0.5), radius: buttonPulse ? 12 : 6)
                        }
                        .buttonStyle(ActiveButtonStyle())
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                buttonPulse = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(bluetoothManager.discoveredDevices, id: \.id) { device in
                            DeviceRowView(device: device, bluetoothManager: bluetoothManager) {
                                interfacingDevice = device
                                withAnimation {
                                    isInterfacing = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(maxHeight: bluetoothManager.isScanning ? 240 : .infinity)
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
    
    private func startSimulatingLogs() {
        let possibleLogs = [
            "SCANNING_CORE_0x\(String(format: "%04X", Int.random(in: 0...65535)))",
            "SIG_OVERRIDE_ENABLED",
            "MAPPING_BLUETOOTH_MESH...",
            "DECODING_HEX_PACKET_7F",
            "FILTERING_STATIC_NOISE",
            "EXTRACTING_DEVICE_UUID",
            "VERIFYING_HARDWARE_INTEGRITY",
            "READY_FOR_HANDSHAKE"
        ]
        
        Task { @MainActor in
            while bluetoothManager.isScanning {
                try? await Task.sleep(nanoseconds: 800_000_000)
                guard !Task.isCancelled && bluetoothManager.isScanning else { break }
                
                withAnimation {
                    scanningLogs.insert("> " + (possibleLogs.randomElement() ?? ""), at: 0)
                    if scanningLogs.count > 6 { scanningLogs.removeLast() }
                }
            }
        }
    }
}

struct DeviceRowView: View {
    let device: IoTDevice
    @ObservedObject var bluetoothManager: BluetoothManager
    let onTap: () -> Void
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Device Icon Sidebar
                ZStack {
                    Rectangle()
                        .fill(neonCyan.opacity(0.1))
                        .frame(width: 45)
                    
                    Image(systemName: device.icon)
                        .font(.system(size: 18))
                        .foregroundColor(neonCyan)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(device.name)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Signal Strength HUD
                        HStack(spacing: 2) {
                            ForEach(0..<5) { idx in
                                Rectangle()
                                    .fill(idx < device.signalStrength ? neonCyan : Color.gray.opacity(0.3))
                                    .frame(width: 3, height: CGFloat(3 + idx * 2))
                            }
                        }
                    }
                    
                    Text(device.type.rawValue.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 15) {
                        Label {
                            Text(device.connectionStatus == .connected ? "ONLINE" : "READY")
                                .font(.system(size: 8, design: .monospaced))
                        } icon: {
                            Circle().fill(device.connectionStatus == .connected ? Color.green : neonCyan.opacity(0.5))
                                .frame(width: 6, height: 6)
                        }
                        .foregroundColor(device.connectionStatus == .connected ? .green : .gray)
                        
                        Text("UUID: \(device.id.uuidString.prefix(8))")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Connect Action Arrow
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(neonCyan.opacity(0.4))
                    .padding(.trailing, 12)
            }
            .background(Color.white.opacity(0.04))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(neonCyan.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RobotControlPanel: View {
    var device: IoTDevice
    @ObservedObject var bluetoothManager: BluetoothManager
    
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

enum DeviceType: String, CaseIterable {
    case esp32 = "ESP32"
    case arduino = "Arduino"
    case raspberryPi = "Raspberry Pi"
    case educationalRobot = "Educational Robot"
    case other = "Other"
}

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
}

enum RotationDirection {
    case clockwise
    case counterClockwise
}

enum IoTCommand {
    case setMotorSpeed(Float)
    case setServoAngle(Float)
    case setDirection(RotationDirection)
    case toggleLED(Bool)
    case emergencyStop
}

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
        case .esp32: return "cpu"
        case .arduino: return "memorychip"
        case .raspberryPi: return "terminal"
        case .educationalRobot: return "robot"
        case .other: return "sensor"
        }
    }

    var imageName: String {
        switch type {
        case .esp32: return "esp32_component"
        case .arduino: return "arduino_uno_component"
        case .raspberryPi: return "raspberry_pi_component"
        case .educationalRobot: return "robot_1"
        case .other: return "esp32_component"
        }
    }
}

@MainActor
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var discoveredDevices: [IoTDevice] = []
    @Published var isConnected = false
    @Published var isScanning = false
    @Published var useSimulatedDevices = true
    
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [CBPeripheral: IoTDevice] = [:]
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    func startScan() {
        // If simulated devices are enabled, allow the scan to "proceed" visually even if BT is off
        if !useSimulatedDevices {
            guard centralManager.state == .poweredOn else { return }
        }
        
        isScanning = true
        discoveredPeripherals.removeAll()
        
        if useSimulatedDevices {
            addSimulatedDevices()
        }
        
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        // Auto-stop scan after some time to simulate a completed discovery cycle
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            self.stopScan()
        }
    }
    
    private func addSimulatedDevices() {
        let simulated = [
            IoTDevice(name: "KINE-SCOUT-01", type: .educationalRobot, signalStrength: 5, connectionStatus: .disconnected),
            IoTDevice(name: "LAB-CORE-BRAIN", type: .esp32, signalStrength: 4, connectionStatus: .disconnected),
            IoTDevice(name: "ARDUINO-HV-DRIVE", type: .arduino, signalStrength: 3, connectionStatus: .disconnected),
            IoTDevice(name: "PI-VISION-NODE", type: .raspberryPi, signalStrength: 2, connectionStatus: .disconnected)
        ]
        
        for device in simulated {
            if !discoveredDevices.contains(where: { $0.name == device.name }) {
                discoveredDevices.append(device)
            }
        }
    }
    
    func stopScan() {
        centralManager.stopScan()
        isScanning = false
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
    
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        Task { @MainActor in
            switch state {
            case .poweredOn:
                print("Bluetooth is powered on")
                self.startScan()
            case .poweredOff:
                print("Bluetooth is powered off")
            case .unauthorized:
                print("Bluetooth is unauthorized")
            case .unsupported:
                print("Bluetooth is unsupported")
            default:
                print("Bluetooth state: \(state)")
            }
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        Task { @MainActor in
            let deviceType = self.determineDeviceType(from: advertisementData)
            let signalBars = self.calculateSignalBars(from: RSSI)
            
            let iotDevice = IoTDevice(
                name: peripheral.name ?? "Unknown Device",
                type: deviceType,
                signalStrength: signalBars,
                connectionStatus: .disconnected,
                motorSpeed: 0,
                servoAngle: 90,
                direction: .clockwise
            )
            
            self.discoveredPeripherals[peripheral] = iotDevice
            self.discoveredDevices = Array(self.discoveredPeripherals.values)
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            if let device = self.discoveredPeripherals[peripheral] {
                var updatedDevice = device
                updatedDevice.connectionStatus = .connected
                self.discoveredPeripherals[peripheral] = updatedDevice
                self.discoveredDevices = Array(self.discoveredPeripherals.values)
                
                peripheral.delegate = self
                peripheral.discoverServices(nil)
            }
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            if let device = self.discoveredPeripherals[peripheral] {
                var updatedDevice = device
                updatedDevice.connectionStatus = .disconnected
                self.discoveredPeripherals[peripheral] = updatedDevice
                self.discoveredDevices = Array(self.discoveredPeripherals.values)
            }
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            if let device = self.discoveredPeripherals[peripheral] {
                var updatedDevice = device
                updatedDevice.connectionStatus = .disconnected
                self.discoveredPeripherals[peripheral] = updatedDevice
                self.discoveredDevices = Array(self.discoveredPeripherals.values)
            }
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        Task { @MainActor in
            guard let services = peripheral.services else { return }
            for service in services {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        Task { @MainActor in
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
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading characteristic: \(error.localizedDescription)")
            return
        }
        let value = characteristic.value
        Task { @MainActor in
            guard let value = value else { return }
            self.processReceivedData(value, for: characteristic)
        }
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
        // Find the peripheral and update its state
        if let pair = discoveredPeripherals.first(where: { $0.value.id == device.id }) {
            let peripheral = pair.key
            var updatedDevice = pair.value
            
            // Apply command to local state
            switch command {
            case .setMotorSpeed(let speed): updatedDevice.motorSpeed = speed
            case .setServoAngle(let angle): updatedDevice.servoAngle = angle
            case .setDirection(let dir): updatedDevice.direction = dir
            case .toggleLED(let on): updatedDevice.sensorTelemetry["led"] = on ? 1 : 0
            case .emergencyStop: updatedDevice.motorSpeed = 0
            }
            
            discoveredPeripherals[peripheral] = updatedDevice
            discoveredDevices = Array(discoveredPeripherals.values)
            
            if peripheral.state == .connected {
                let commandData = encodeCommand(command)
                if let service = peripheral.services?.first,
                   let characteristic = service.characteristics?.first(where: { char in char.properties.contains(.write) }) {
                    peripheral.writeValue(commandData, for: characteristic, type: .withResponse)
                }
            } else if useSimulatedDevices {
                // In simulation mode, we just update the local state as if it succeeded
                print("Simulated command sent: \(command)")
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
        case .toggleLED(let on):
            return Data([0x04, on ? 0x01 : 0x00])
        case .emergencyStop:
            return Data([0xFF])
        }
    }
}

struct IoTComponentLibraryView: View {
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    @State private var selectedComponent: IoTComponent?
    @State private var searchTerm: String = ""

    var filteredComponents: [IoTComponent] {
        if searchTerm.isEmpty {
            return IoTComponentsDatabase.shared.components
        } else {
            return IoTComponentsDatabase.shared.components.filter { 
                $0.name.localizedCaseInsensitiveContains(searchTerm) || 
                $0.category.rawValue.localizedCaseInsensitiveContains(searchTerm) ||
                $0.description.localizedCaseInsensitiveContains(searchTerm)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(neonCyan.opacity(0.6))
                TextField("", text: $searchTerm, prompt: Text("SEARCH COMPONENT DATABASE").foregroundColor(.gray.opacity(0.5)))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(neonCyan.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            ScrollView {
                VStack(spacing: 16) {
                    if searchTerm.isEmpty {
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
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredComponents) { comp in
                                ComponentCardView(component: comp) {
                                    selectedComponent = comp
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .sheet(item: $selectedComponent) { comp in
            ComponentDetailView(component: comp)
        }
    }
}

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
                        
                        Image(component.componentImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .background(Color.black)
                            .compositingGroup()
                            .luminanceToAlpha()
                            .mask(
                                Image(component.componentImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                            )
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
                            
                            // Core Component Image
                            Image(component.componentImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 140, height: 140)
                                .background(Color.black)
                                .clipShape(Circle())
                                .opacity(textOpacity)
                                .shadow(color: neonCyan, radius: 20)
                            
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
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    textOpacity = 1.0
                }
            }
        }
    }
}

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

struct ActiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Hardware Interfacing Animation (Scanner-Style)
struct HardwareInterfacingView: View {
    let device: IoTDevice
    @Binding var isPresented: Bool
    var onComplete: () -> Void
    
    @State private var scanPhase = 0
    @State private var matrixLines: [String] = Array(repeating: "", count: 20)
    @State private var glitchOffset: CGFloat = 0
    
    @State private var innerRotation: Double = 0
    @State private var middleRotation: Double = 0
    @State private var outerRotation: Double = 0
    
    @State private var showHardware = false
    @State private var instructionIndex = 0
    @State private var hudVisible = false
    @State private var popups: [InterfacingPopup] = []
    @State private var showRedWarning = false
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Animation removed per user request
            

            

            
            // Removed heavy red flash warning strobe
            
            // Device Info (after scan)
            if showHardware {
                VStack(spacing: 25) {
                    ZStack {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .stroke(neonCyan.opacity(0.2), lineWidth: 1)
                                .frame(width: CGFloat(220 + i * 40))
                                .scaleEffect(1.1)
                        }
                        
                        Image(device.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 180, height: 180)
                            .background(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: neonCyan.opacity(0.6), radius: 30)
                        
                        Rectangle()
                            .fill(neonCyan.opacity(0.4))
                            .frame(width: 240, height: 2)
                            .offset(y: showHardware ? 100 : -100)
                            .animation(.linear(duration: 2).repeatForever(autoreverses: true), value: showHardware)
                    }
                    .padding(.top, 40)
                    
                    Text("SYNCING: \(device.name)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(0..<instructions.count, id: \.self) { idx in
                            HStack(spacing: 12) {
                                Rectangle()
                                    .fill(idx <= instructionIndex ? neonCyan : Color.gray.opacity(0.2))
                                    .frame(width: 4, height: 25)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("STEP 0\(idx + 1)")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(idx <= instructionIndex ? neonCyan : .gray)
                                    Text(instructions[idx])
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(idx <= instructionIndex ? .white : .gray.opacity(0.5))
                                }
                                
                                Spacer()
                                
                                if idx <= instructionIndex {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(neonCyan)
                                        .font(.system(size: 12))
                                }
                            }
                            .padding(.vertical, 4)
                            .opacity(idx <= instructionIndex ? 1 : 0.3)
                        }
                    }
                    .padding(15)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(10)
                    .padding(.horizontal, 25)
                    
                    if instructionIndex == instructions.count - 1 {
                        Button(action: {
                            onComplete()
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                Text("INITIALIZE LINK")
                            }
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 35)
                            .padding(.vertical, 14)
                            .background(neonCyan)
                            .cornerRadius(8)
                        }
                        .padding(.bottom, 20)
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity))
            }
        }
        .onAppear {
            startScanAnimation()
        }
        .onAppear {
            startScanAnimation()
        }
    }
    
    private var instructions: [String] {
        switch device.type {
        case .educationalRobot:
            return ["CALIBRATE CHASSIS", "ARM POWER MODULE", "ENABLE BT_MESH", "SYNC HANDSHAKE"]
        case .esp32, .arduino:
            return ["DETECT USB_BUS", "OPEN UART_SERIAL", "UPLOAD FIRMWARE", "INITIALIZE GPIO"]
        default:
            return ["VERIFY HARDWARE", "LOAD DRIVERS", "ESTABLISH LINK", "READY STATUS"]
        }
    }
    
    private func startScanAnimation() {
        // Show device immediately without animation overload
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showHardware = true
            }
            AudioServicesPlaySystemSound(1322) // Dhoom equivalent success sound
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            startInstructionCycle()
        }
    }
    
    private func startInstructionCycle() {
        Task { @MainActor in
            for i in 1..<instructions.count {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                withAnimation { instructionIndex = i }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }
}

struct DataStreamPacket: Identifiable {
    let id = UUID()
    let content: String
    var position: CGPoint
    let size: CGFloat
    let opacity: Double
    let duration: Double
}

struct InterfacingPopup: Identifiable {
    let id = UUID()
    let title: String
    let offset: CGSize
}

struct InterfacingPopupView: View {
    let popup: InterfacingPopup
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(popup.title).bold()
                Spacer()
                Text("X").foregroundColor(.white).bold()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red)
            .foregroundColor(.black)
            .font(.system(size: 10, design: .monospaced))
            
            Text("ERR: SYS_FAULT\nDATA CORRUPTED\nMEM_ADDR UNKNOWN")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.red)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.8))
        }
        .frame(width: 150)
        .border(Color.red, width: 2)
        .shadow(color: .red, radius: 10)
        .offset(popup.offset)
        .transition(.scale(scale: 0.1).combined(with: .opacity))
    }
}


// MARK: - Device Hologram View (Realistic Hardware Rendering)
struct DeviceHologramView: View {
    let device: IoTDevice
    let color: Color
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            // Outer glow
            RadialGradient(gradient: Gradient(colors: [color.opacity(0.2), .clear]), center: .center, startRadius: 20, endRadius: 90)
            
            // Render device-specific board
            switch device.type {
            case .arduino:
                ArduinoBoardView(color: color, pulse: pulse)
            case .raspberryPi:
                RaspberryPiBoardView(color: color, pulse: pulse)
            case .esp32:
                ESP32BoardView(color: color, pulse: pulse)
            case .educationalRobot:
                RobotBoardView(color: color, pulse: pulse)
            case .other:
                ESP32BoardView(color: color, pulse: pulse)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Arduino Uno Board
struct ArduinoBoardView: View {
    let color: Color
    let pulse: Bool
    private let boardColor = Color(red: 0.0, green: 0.35, blue: 0.55)
    
    var body: some View {
        ZStack {
            // PCB Board — the distinctive Arduino Uno shape
            UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 20)
                .fill(boardColor)
                .frame(width: 150, height: 105)
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 20)
                        .stroke(color.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: boardColor.opacity(0.5), radius: 12)
            
            // USB-B Port (top left, silver rectangle)
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: [Color.gray.opacity(0.9), Color.white.opacity(0.5), Color.gray.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .frame(width: 18, height: 14)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.gray, lineWidth: 1))
                .offset(x: -60, y: -30)
            
            // DC Power Jack (below USB)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.9))
                .frame(width: 14, height: 12)
                .overlay(Circle().fill(Color.gray.opacity(0.5)).frame(width: 6, height: 6))
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.gray.opacity(0.6), lineWidth: 0.5))
                .offset(x: -60, y: -8)
            
            // ATmega328P main chip (center, large DIP)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.95))
                .frame(width: 38, height: 20)
                .overlay(
                    VStack(spacing: 1) {
                        Text("ATMEGA")
                            .font(.system(size: 5, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.gray.opacity(0.8))
                        Text("328P")
                            .font(.system(size: 5, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.gray.opacity(0.8))
                    }
                )
                .offset(x: 5, y: 5)
            
            // DIP chip pins (top row)
            HStack(spacing: 2) {
                ForEach(0..<14, id: \.self) { _ in
                    Rectangle().fill(Color.gray.opacity(0.7)).frame(width: 2, height: 4)
                }
            }
            .offset(x: 5, y: -8)
            
            // DIP chip pins (bottom row)
            HStack(spacing: 2) {
                ForEach(0..<14, id: \.self) { _ in
                    Rectangle().fill(Color.gray.opacity(0.7)).frame(width: 2, height: 4)
                }
            }
            .offset(x: 5, y: 18)
            
            // Digital Pin Headers (top edge — 14 pins)
            HStack(spacing: 2.5) {
                ForEach(0..<14, id: \.self) { _ in
                    Rectangle().fill(Color.black).frame(width: 4, height: 8)
                        .overlay(Circle().fill(color.opacity(0.5)).frame(width: 2.5, height: 2.5))
                }
            }
            .offset(x: 10, y: -48)
            
            // Analog Pin Headers (bottom edge — 6 pins)
            HStack(spacing: 2.5) {
                ForEach(0..<6, id: \.self) { _ in
                    Rectangle().fill(Color.black).frame(width: 4, height: 8)
                        .overlay(Circle().fill(color.opacity(0.5)).frame(width: 2.5, height: 2.5))
                }
            }
            .offset(x: -30, y: 48)
            
            // Power pin headers
            HStack(spacing: 2.5) {
                ForEach(0..<6, id: \.self) { _ in
                    Rectangle().fill(Color.black).frame(width: 4, height: 8)
                        .overlay(Circle().fill(color.opacity(0.5)).frame(width: 2.5, height: 2.5))
                }
            }
            .offset(x: 20, y: 48)
            
            // Crystal Oscillator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.8))
                .frame(width: 10, height: 6)
                .offset(x: 35, y: -10)
            
            // Reset button (small circle)
            Circle()
                .fill(Color.red.opacity(0.7))
                .frame(width: 8, height: 8)
                .shadow(color: .red.opacity(0.3), radius: 3)
                .offset(x: -35, y: 15)
            
            // Status LEDs
            HStack(spacing: 5) {
                Circle().fill(Color.green).frame(width: 4, height: 4)
                    .shadow(color: .green, radius: pulse ? 5 : 2)
                Circle().fill(Color.yellow).frame(width: 4, height: 4)
                    .shadow(color: .yellow, radius: pulse ? 4 : 1)
                Circle().fill(Color.red.opacity(0.6)).frame(width: 4, height: 4)
            }
            .offset(x: -25, y: -30)
            
            // "ARDUINO" label
            Text("ARDUINO UNO")
                .font(.system(size: 6, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
                .offset(x: 30, y: 35)
        }
    }
}

// MARK: - Raspberry Pi Board
struct RaspberryPiBoardView: View {
    let color: Color
    let pulse: Bool
    private let boardColor = Color(red: 0.0, green: 0.45, blue: 0.2)
    
    var body: some View {
        ZStack {
            // PCB Board (credit card size, green)
            RoundedRectangle(cornerRadius: 6)
                .fill(boardColor)
                .frame(width: 150, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: boardColor.opacity(0.5), radius: 12)
            
            // Mounting holes (4 corners)
            ForEach([(x: -62, y: -38), (x: 62, y: -38), (x: -62, y: 38), (x: 62, y: 38)], id: \.x) { pos in
                Circle().stroke(Color.white.opacity(0.4), lineWidth: 1).frame(width: 7, height: 7)
                    .overlay(Circle().fill(Color.black.opacity(0.5)).frame(width: 4, height: 4))
                    .offset(x: CGFloat(pos.x), y: CGFloat(pos.y))
            }
            
            // Broadcom SoC (big silver square with heatsink pattern)
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(colors: [Color.gray.opacity(0.8), Color.white.opacity(0.4), Color.gray.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 28, height: 28)
                .overlay(
                    // Heatsink grid lines
                    VStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { _ in
                            Rectangle().fill(Color.gray.opacity(0.5)).frame(height: 1)
                        }
                    }
                    .padding(4)
                )
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray, lineWidth: 0.5))
                .offset(x: -10, y: -5)
            
            // GPIO 40-pin header (2 rows of 20, right side)
            VStack(spacing: 1.5) {
                HStack(spacing: 1.5) {
                    ForEach(0..<20, id: \.self) { _ in
                        Circle().fill(Color.yellow.opacity(0.8)).frame(width: 3, height: 3)
                    }
                }
                HStack(spacing: 1.5) {
                    ForEach(0..<20, id: \.self) { _ in
                        Circle().fill(Color.yellow.opacity(0.8)).frame(width: 3, height: 3)
                    }
                }
            }
            .offset(x: 5, y: -42)
            
            // USB-A Ports (2 stacked, silver)
            VStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [.gray, .white.opacity(0.5), .gray], startPoint: .top, endPoint: .bottom))
                    .frame(width: 20, height: 10)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.gray, lineWidth: 0.5))
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [.gray, .white.opacity(0.5), .gray], startPoint: .top, endPoint: .bottom))
                    .frame(width: 20, height: 10)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.gray, lineWidth: 0.5))
            }
            .offset(x: 60, y: -10)
            
            // Ethernet Port (silver, tall)
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: [.gray.opacity(0.8), .white.opacity(0.4), .gray.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                .frame(width: 22, height: 18)
                .overlay(
                    VStack(spacing: 1) {
                        // LED indicators on ethernet
                        HStack(spacing: 8) {
                            Circle().fill(Color.green.opacity(0.8)).frame(width: 3, height: 3)
                                .shadow(color: .green, radius: pulse ? 3 : 1)
                            Circle().fill(Color.orange.opacity(0.8)).frame(width: 3, height: 3)
                        }
                        RoundedRectangle(cornerRadius: 1).fill(Color.black.opacity(0.3)).frame(width: 14, height: 8)
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.gray, lineWidth: 0.5))
                .offset(x: 60, y: 22)
            
            // USB-C Power Port (left edge)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.8))
                .frame(width: 12, height: 6)
                .offset(x: -68, y: 20)
            
            // HDMI Micro ports
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 10, height: 5)
                    .overlay(RoundedRectangle(cornerRadius: 1).stroke(Color.gray.opacity(0.5), lineWidth: 0.5))
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.black.opacity(0.9))
                    .frame(width: 10, height: 5)
                    .overlay(RoundedRectangle(cornerRadius: 1).stroke(Color.gray.opacity(0.5), lineWidth: 0.5))
            }
            .offset(x: -68, y: -10)
            
            // SD Card slot (bottom edge)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.gray.opacity(0.7))
                .frame(width: 18, height: 4)
                .offset(x: -20, y: 48)
            
            // RAM chip
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.9))
                .frame(width: 16, height: 12)
                .overlay(
                    Text("RAM")
                        .font(.system(size: 4, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))
                )
                .offset(x: 25, y: 5)
            
            // Activity LED
            Circle().fill(Color.green).frame(width: 4, height: 4)
                .shadow(color: .green, radius: pulse ? 6 : 2)
                .offset(x: -50, y: 35)
            
            // Power LED
            Circle().fill(Color.red.opacity(0.8)).frame(width: 4, height: 4)
                .shadow(color: .red.opacity(0.5), radius: 3)
                .offset(x: -42, y: 35)
            
            // Raspberry Pi logo text
            Text("Raspberry Pi 4")
                .font(.system(size: 5, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .offset(x: -10, y: 30)
        }
    }
}

// MARK: - ESP32 Board
struct ESP32BoardView: View {
    let color: Color
    let pulse: Bool
    private let boardColor = Color(red: 0.1, green: 0.1, blue: 0.4)
    
    var body: some View {
        ZStack {
            // PCB (smaller, dark blue)
            RoundedRectangle(cornerRadius: 4)
                .fill(boardColor)
                .frame(width: 130, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(color.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: boardColor.opacity(0.5), radius: 12)
            
            // WiFi/BT Antenna (metal shield at top)
            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: [Color.gray.opacity(0.7), Color.white.opacity(0.3), Color.gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                .frame(width: 28, height: 20)
                .overlay(
                    // Antenna pattern
                    Path { path in
                        path.move(to: CGPoint(x: 5, y: 5))
                        path.addLine(to: CGPoint(x: 23, y: 5))
                        path.addLine(to: CGPoint(x: 23, y: 15))
                        path.move(to: CGPoint(x: 8, y: 8))
                        path.addLine(to: CGPoint(x: 20, y: 8))
                        path.addLine(to: CGPoint(x: 20, y: 12))
                    }
                    .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                    .frame(width: 28, height: 20)
                )
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.gray.opacity(0.6), lineWidth: 0.5))
                .offset(x: -42, y: 0)
            
            // ESP32 Main Chip (center)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.95))
                .frame(width: 22, height: 18)
                .overlay(
                    VStack(spacing: 1) {
                        Text("ESP32")
                            .font(.system(size: 5, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.gray.opacity(0.8))
                        Text("WROOM")
                            .font(.system(size: 4, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.gray.opacity(0.6))
                    }
                )
                .offset(x: -5, y: 0)
            
            // Pin headers (top row — 15 pins)
            HStack(spacing: 2) {
                ForEach(0..<15, id: \.self) { _ in
                    Circle().fill(Color.yellow.opacity(0.7)).frame(width: 3, height: 3)
                }
            }
            .offset(x: 5, y: -28)
            
            // Pin headers (bottom row — 15 pins)
            HStack(spacing: 2) {
                ForEach(0..<15, id: \.self) { _ in
                    Circle().fill(Color.yellow.opacity(0.7)).frame(width: 3, height: 3)
                }
            }
            .offset(x: 5, y: 28)
            
            // Micro USB port
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.8))
                .frame(width: 10, height: 6)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.gray, lineWidth: 0.5))
                .offset(x: 55, y: 0)
            
            // LED
            Circle().fill(Color.blue).frame(width: 4, height: 4)
                .shadow(color: .blue, radius: pulse ? 6 : 2)
                .offset(x: 40, y: -10)
            
            // Boot / EN buttons
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 6, height: 4)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 6, height: 4)
            }
            .offset(x: 40, y: 10)
            
            // Voltage regulator
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.black.opacity(0.9))
                .frame(width: 8, height: 10)
                .offset(x: 25, y: 0)
            
            // Label
            Text("ESP32")
                .font(.system(size: 5, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .offset(x: 15, y: -18)
        }
    }
}

// MARK: - Educational Robot Board
struct RobotBoardView: View {
    let color: Color
    let pulse: Bool
    
    var body: some View {
        ZStack {
            // Robot chassis (rounded)
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                .frame(width: 140, height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.5), lineWidth: 1.5)
                )
                .shadow(color: color.opacity(0.3), radius: 12)
            
            // Wheels (left and right)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.9))
                .frame(width: 12, height: 30)
                .overlay(
                    VStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { _ in
                            Rectangle().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 1)
                        }
                    }
                )
                .offset(x: -72, y: 0)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.black.opacity(0.9))
                .frame(width: 12, height: 30)
                .overlay(
                    VStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { _ in
                            Rectangle().fill(Color.gray.opacity(0.4)).frame(width: 8, height: 1)
                        }
                    }
                )
                .offset(x: 72, y: 0)
            
            // Motor driver chips (L/R)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.9))
                .frame(width: 16, height: 12)
                .overlay(Text("M1").font(.system(size: 4, weight: .bold, design: .monospaced)).foregroundColor(.gray.opacity(0.7)))
                .offset(x: -48, y: 0)
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.9))
                .frame(width: 16, height: 12)
                .overlay(Text("M2").font(.system(size: 4, weight: .bold, design: .monospaced)).foregroundColor(.gray.opacity(0.7)))
                .offset(x: 48, y: 0)
            
            // Brain board (center, raised)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.0, green: 0.3, blue: 0.5))
                .frame(width: 50, height: 35)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.6), lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 2) {
                        Image(systemName: "cpu")
                            .font(.system(size: 12))
                            .foregroundColor(color)
                        Text("CORE")
                            .font(.system(size: 4, weight: .bold, design: .monospaced))
                            .foregroundColor(color.opacity(0.8))
                    }
                )
            
            // Ultrasonic sensor (front, two circles)
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: 14, height: 14)
                    .overlay(Circle().fill(Color.black.opacity(0.5)).frame(width: 8, height: 8))
                    .overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
                Circle()
                    .fill(Color.gray.opacity(0.7))
                    .frame(width: 14, height: 14)
                    .overlay(Circle().fill(Color.black.opacity(0.5)).frame(width: 8, height: 8))
                    .overlay(Circle().stroke(Color.gray, lineWidth: 0.5))
            }
            .offset(y: -42)
            
            // Sensor label
            Text("SONAR")
                .font(.system(size: 4, weight: .bold, design: .monospaced))
                .foregroundColor(.gray.opacity(0.6))
                .offset(y: -30)
            
            // Battery indicator area (bottom)
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 1).fill(Color.green).frame(width: 8, height: 6)
                RoundedRectangle(cornerRadius: 1).fill(Color.green).frame(width: 8, height: 6)
                RoundedRectangle(cornerRadius: 1).fill(Color.yellow).frame(width: 8, height: 6)
                RoundedRectangle(cornerRadius: 1).fill(Color.gray.opacity(0.3)).frame(width: 8, height: 6)
            }
            .offset(y: 35)
            
            // Power LED
            Circle().fill(Color.green).frame(width: 5, height: 5)
                .shadow(color: .green, radius: pulse ? 6 : 2)
                .offset(x: -20, y: 35)
            
            // Label
            Text("KINE-SCOUT")
                .font(.system(size: 5, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
                .offset(y: 46)
        }
    }
}
