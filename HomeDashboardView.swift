import SwiftUI

struct LogItem: Identifiable {
    let id = UUID()
    let time: String
    let msg: String
    let type: SystemLogEntry.LogType
}

@MainActor
struct HomeDashboardView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @State private var showingAnalytics = false
    @State private var showingLidarConfig = false
    @State private var showingLidarDiagnostics = false
    @State private var showingLidarCalibration = false
    @State private var showingAbout = false
    @State private var scanlineOffset: CGFloat = 0
    @State private var headerGlitch = false
    @State private var statusPulse = false
    @State private var terminalCursor = true
    
    @State private var systemLogs: [LogItem] = [
        LogItem(time: "14:02:41", msg: "Booting KINEPRINT OS v2.0...", type: .normal),
        LogItem(time: "14:02:42", msg: "Kernel Initialized ✓", type: .success),
        LogItem(time: "14:02:43", msg: "Loading neural modules...", type: .normal),
        LogItem(time: "14:02:44", msg: "LiDAR Matrix Calibrated ✓", type: .success),
        LogItem(time: "14:02:45", msg: "All subsystems nominal ✓", type: .success)
    ]
    
    private let draftBlue = Color(red: 0.02, green: 0.08, blue: 0.15)
    private let neonCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    private let starkWhite = Color(red: 0.9, green: 0.95, blue: 1.0)

    var body: some View {
        ZStack {
            draftBlue.ignoresSafeArea()
            EngineeringGridBackground(cyanColor: neonCyan)
                .opacity(0.4)
            
            // Animated Scanline Effect
            GeometryReader { geo in
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.clear, neonCyan.opacity(0.08), .clear]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 80)
                    .offset(y: scanlineOffset)
                    .onAppear {
                        withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                            scanlineOffset = geo.size.height
                        }
                    }
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // ═══ HEADER BAR ═══
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle().fill(neonCyan).frame(width: 6, height: 6)
                                    .scaleEffect(statusPulse ? 1.5 : 1)
                                    .opacity(statusPulse ? 0.5 : 1)
                                Text("SECURE_TERMINAL // NODE_01")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(neonCyan.opacity(0.7))
                            }
                            Text("KINEPRINT_HUB")
                                .font(.system(size: 24, weight: .heavy, design: .monospaced))
                                .foregroundColor(starkWhite)
                                .shadow(color: neonCyan.opacity(0.4), radius: headerGlitch ? 8 : 0)
                                .offset(x: headerGlitch ? CGFloat.random(in: -2...2) : 0)
                            Text("OPERATOR: \(viewModel.userName.uppercased())")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(neonCyan)
                        }
                        Spacer()
                        
                        // Status Indicator
                        VStack(alignment: .trailing, spacing: 6) {
                            HStack(spacing: 6) {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                    .shadow(color: .green, radius: statusPulse ? 8 : 4)
                                Text("SYS_ONLINE")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            HStack(spacing: 8) {
                                Text("V2.1.0-PROTO")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.gray)
                                
                                Button(action: { showingAbout = true }) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(neonCyan)
                                        .font(.system(size: 14))
                                }
                            }
                            Text(currentTimeString())
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan.opacity(0.5))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(LinearGradient(gradient: Gradient(colors: [neonCyan.opacity(0.6), neonCyan.opacity(0.1), neonCyan.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    )
                    .shadow(color: neonCyan.opacity(0.1), radius: 10)
                    .padding(.horizontal, 20)

                    // ═══ CENTRAL REACTOR / IDENTITY ═══
                    VStack(spacing: 24) {
                        CoreIdentityCircle(
                            avatarType: viewModel.avatarType,
                            avatarColor: viewModel.avatarColor,
                            backgroundTheme: viewModel.backgroundTheme,
                            size: 200
                        )
                        
                        // Core Status Badge
                        HStack(spacing: 12) {
                            Image(systemName: "link.circle.fill")
                                .foregroundColor(viewModel.avatarColor)
                                .font(.system(size: 16))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("NEURAL LINK: \(viewModel.avatarType.name.uppercased())")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(starkWhite)
                                Text("SYNCED: 100%")
                                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                    .foregroundColor(viewModel.avatarColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.avatarColor.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                        )
                        .shadow(color: viewModel.avatarColor.opacity(0.2), radius: 8)
                    }
                    .padding(.vertical, 10)
                    
                    // ═══ DIAGNOSTICS GRID ═══
                    HStack(spacing: 16) {
                        DiagnosticWidget(
                            title: "LIDAR ARRAY",
                            value: viewModel.lidarAvailable ? "ACTIVE" : "STANDBY",
                            statusColor: viewModel.lidarAvailable ? .green : .orange,
                            icon: "point.3.connected.trianglepath.dotted"
                        ) {
                            showingLidarConfig = true
                        }
                        DiagnosticWidget(
                            title: "BLUETOOTH",
                            value: "MONITORING",
                            statusColor: neonCyan,
                            icon: "antenna.radiowaves.left.and.right"
                        ) {
                            let urlStrings = ["App-Prefs:root=Bluetooth", "App-prefs:Bluetooth", UIApplication.openSettingsURLString]
                            for urlString in urlStrings {
                                if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                                    break
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // ═══ PERFORMANCE ANALYTICS ═══
                    Button(action: { showingAnalytics = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(neonCyan.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "chart.xyaxis.line")
                                            .foregroundColor(neonCyan)
                                    }
                                    Text("PERFORMANCE ANALYTICS")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                Text("GLOBAL DATA CENTER VISUALIZATION")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(neonCyan.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(neonCyan)
                                .shadow(color: neonCyan.opacity(0.5), radius: 5)
                        }
                        .padding(16)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(neonCyan.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: neonCyan.opacity(0.08), radius: 8)
                    }
                    .padding(.horizontal, 20)
                    
                    // ═══ SYSTEM ACTIVITY LOG (Terminal Style) ═══
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            HStack(spacing: 6) {
                                Circle().fill(Color.red).frame(width: 8, height: 8)
                                Circle().fill(Color.yellow).frame(width: 8, height: 8)
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                            }
                            Spacer()
                            Text("SYSTEM_LOG.terminal")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(starkWhite.opacity(0.7))
                            Spacer()
                            Image(systemName: "terminal.fill")
                                .foregroundColor(neonCyan.opacity(0.5))
                                .font(.system(size: 12))
                        }
                        .padding(12)
                        .background(Color(red: 0.1, green: 0.1, blue: 0.12))
                        
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(systemLogs) { log in
                                SystemLogEntry(time: log.time, msg: log.msg, type: log.type)
                            }
                            
                            // Blinking cursor line
                            HStack(spacing: 0) {
                                Text("root@kineprint:~$ ")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 14)
                                    .opacity(terminalCursor ? 1 : 0)
                                Spacer()
                            }
                            .padding(.vertical, 6)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.85))
                    }
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(neonCyan.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: neonCyan.opacity(0.05), radius: 8)
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 80)
                }
                .padding(.top, 20)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                statusPulse = true
            }
            withAnimation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                terminalCursor = false
            }
            // Header glitch effect every few seconds
            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                DispatchQueue.main.async {
                    headerGlitch = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        headerGlitch = false
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingAnalytics) {
             PerformanceAnalyticsView(isPresented: $showingAnalytics)
        }
        .alert("LiDAR Subsystem Config", isPresented: $showingLidarConfig) {
            Button("Run Diagnostics") {
                addLog(msg: "Initiating LiDAR diagnostics...", type: .normal)
                showingLidarDiagnostics = true
            }
            Button("Calibrate Matrix") {
                addLog(msg: "Executing spatial recalibration...", type: .normal)
                showingLidarCalibration = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The LiDAR depth matrix is currently \(viewModel.lidarAvailable ? "ACTIVE" : "in STANDBY"). Configure module settings internally here.")
        }
        .fullScreenCover(isPresented: $showingLidarDiagnostics) {
            LidarDiagnosticsView()
        }
        .fullScreenCover(isPresented: $showingLidarCalibration) {
            LidarCalibrationView()
        }
        .fullScreenCover(isPresented: $showingAbout) {
            AboutProtocolView()
        }
    }
    
    private func currentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func addLog(msg: String, type: SystemLogEntry.LogType) {
        let newLog = LogItem(time: currentTimeString(), msg: msg, type: type)
        withAnimation {
            systemLogs.append(newLog)
            if systemLogs.count > 5 {
                systemLogs.removeFirst(systemLogs.count - 5)
            }
        }
    }
}

struct DiagnosticWidget: View {
    let title: String
    let value: String
    let statusColor: Color
    let icon: String
    var action: (() -> Void)? = nil
    
    @State private var pulse = false
    private let neonCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle().fill(statusColor.opacity(0.15)).frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .foregroundColor(statusColor)
                        .font(.system(size: 14))
                }
                Spacer()
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusColor, radius: pulse ? 8 : 3)
                    .scaleEffect(pulse ? 1.3 : 1.0)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(statusColor)
                    .shadow(color: statusColor.opacity(0.5), radius: 3)
            }
            
            // Micro progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 3)
                    Rectangle().fill(statusColor).frame(width: geo.size.width * 0.75, height: 3)
                        .cornerRadius(2)
                }
            }
            .frame(height: 3)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: statusColor.opacity(0.08), radius: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

struct SystemLogEntry: View {
    let time: String
    let msg: String
    let type: LogType
    private let neonCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    
    enum LogType { case normal, success, error }
    
    var color: Color {
        switch type {
        case .normal: return .gray
        case .success: return .green
        case .error: return .red
        }
    }
    
    var prefix: String {
        switch type {
        case .normal: return ">"
        case .success: return "✓"
        case .error: return "✗"
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Text("[\(time)]")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(neonCyan.opacity(0.5))
            Text(prefix)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(msg)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(color.opacity(0.9))
            Spacer()
        }
        .padding(.vertical, 4)
    }
}


