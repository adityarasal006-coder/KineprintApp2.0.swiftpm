import SwiftUI

struct HomeDashboardView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @State private var showingResearch = false
    
    private let draftBlue = Color(red: 0.02, green: 0.08, blue: 0.15)
    private let neonCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    private let starkWhite = Color(red: 0.9, green: 0.95, blue: 1.0)

    var body: some View {
        ZStack {
            draftBlue.ignoresSafeArea()
            EngineeringGridBackground(cyanColor: neonCyan)
                .opacity(0.4)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NODE TERMINAL")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan.opacity(0.8))
                            Text("KINEPRINT_HUB")
                                .font(.system(size: 24, weight: .heavy, design: .monospaced))
                                .foregroundColor(starkWhite)
                            Text("WELCOME, \(viewModel.userName.uppercased())")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(neonCyan)
                        }
                        Spacer()
                        
                        // Status Indicator
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 6) {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                    .shadow(color: .green, radius: 4)
                                Text("SYS_ONLINE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            Text("V2.0.4-BUILD")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .border(neonCyan.opacity(0.3), width: 1)
                    .padding(.horizontal, 20)

                    // Central Radar / Core System Monitor
                    VStack(spacing: 24) {
                        CoreIdentityCircle(
                            avatarType: viewModel.avatarType,
                            avatarColor: viewModel.avatarColor,
                            backgroundTheme: viewModel.backgroundTheme,
                            size: 200
                        )
                        
                        // Core status
                        VStack(spacing: 2) {
                            Text("NEURAL LINK: \(viewModel.avatarType.name.uppercased())")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(starkWhite)
                            Text("SYNCED: 100%")
                                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                .foregroundColor(viewModel.avatarColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(viewModel.avatarColor.opacity(0.5), lineWidth: 1))
                    }
                    .padding(.vertical, 10)
                    
                    // Diagnostics Grid
                    HStack(spacing: 16) {
                        DiagnosticWidget(
                            title: "LIDAR ARRAY",
                            value: viewModel.lidarAvailable ? "ACTIVE" : "STANDBY",
                            statusColor: viewModel.lidarAvailable ? .green : .orange,
                            icon: "point.3.connected.trianglepath.dotted"
                        )
                        DiagnosticWidget(
                            title: "BLUETOOTH",
                            value: "MONITORING",
                            statusColor: neonCyan,
                            icon: "antenna.radiowaves.left.and.right"
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Database / Research Archive
                    Button(action: { showingResearch = true }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "server.rack")
                                        .foregroundColor(neonCyan)
                                    Text("FIELD DATA ARCHIVE")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                Text("\(viewModel.researchEntries.count) STRUCTURAL SCAN(S) LOGGED")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(neonCyan.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(neonCyan)
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(neonCyan.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Activity Log
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("RECENT SYSTEM ACTIVITY")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(starkWhite)
                            Spacer()
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        
                        VStack(spacing: 0) {
                            SystemLogEntry(time: "14:02:42", msg: "App Initialization Complete", type: .normal)
                            Divider().background(neonCyan.opacity(0.3))
                            SystemLogEntry(time: "14:02:44", msg: "LiDAR Matrix Calibrated", type: .success)
                            Divider().background(neonCyan.opacity(0.3))
                            SystemLogEntry(time: "14:02:45", msg: "Awaiting Operative Input...", type: .normal)
                        }
                        .padding()
                        .background(Color.black.opacity(0.2))
                    }
                    .border(neonCyan.opacity(0.3), width: 1)
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 80)
                }
                .padding(.top, 20)
            }
        }
        .sheet(isPresented: $showingResearch) {
             ResearchLibraryView(viewModel: viewModel)
        }
    }
}

struct DiagnosticWidget: View {
    let title: String
    let value: String
    let statusColor: Color
    let icon: String
    private let neonCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(neonCyan)
                Spacer()
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(statusColor)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.3))
        .border(neonCyan.opacity(0.3), width: 1)
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
    
    var body: some View {
        HStack {
            Text("[\(time)]")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(neonCyan.opacity(0.6))
            Text(msg)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(color)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

