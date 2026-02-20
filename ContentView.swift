#if canImport(SwiftUI)
import SwiftUI
#endif

#if os(iOS)
import ARKit
import SceneKit
import Metal
import MetalKit
import Charts
import Combine
import Foundation
import CoreBluetooth
#if canImport(UIKit)
import UIKit
#endif

// MARK: - App Tabs

@available(iOS 16.0, *)
enum AppTab {
    case home
    case iot
    case ar
    case training
    case profile
}

// MARK: - Main View

@available(iOS 16.0, *)
struct KineprintView: View {
    @StateObject private var viewModel = KineprintViewModel()
    @State private var selectedTab: AppTab = .home
    @State private var showingARAnimation = false
    
    var body: some View {
        ZStack {
            if !viewModel.isOnboardingComplete {
                OnboardingView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    TopNavigationBar(viewModel: viewModel)
                    
                    ZStack {
                        switch selectedTab {
                        case .home:
                            HomeDashboardView(viewModel: viewModel)
                        case .iot:
                            IoTControlHubView()
                        case .ar:
                            ARScannerTab(viewModel: viewModel)
                        case .training:
                            LearningLabView()
                        case .profile:
                            ProfileSettingsView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    CustomBottomToolbar(selectedTab: $selectedTab, startARAnimation: {
                        showingARAnimation = true
                    })
                }
                .disabled(showingARAnimation)
                .opacity(viewModel.isBooting ? 0 : 1)
                
                if viewModel.isBooting {
                    BootSequenceView(viewModel: viewModel)
                        .transition(.opacity)
                }
                
                if showingARAnimation {
                    AROpeningAnimation {
                        showingARAnimation = false
                        selectedTab = .ar
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .animation(.easeInOut, value: viewModel.isOnboardingComplete)
        .animation(.easeInOut, value: selectedTab)
    }
}

@available(iOS 16.0, *)
struct ARScannerTab: View {
    @ObservedObject var viewModel: KineprintViewModel

    var body: some View {
        ZStack {
            ARCameraView(viewModel: viewModel)
            
            VStack(spacing: 0) {
                if viewModel.isScanning {
                    ScanningLine()
                }
                
                Spacer()
                
                HStack(alignment: .bottom) {
                    Spacer()
                    SidebarControls(viewModel: viewModel)
                        .padding(.trailing, 12)
                        .padding(.bottom, 16)
                }
                
                BottomDashboard(viewModel: viewModel)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
        }
    }
}

@available(iOS 16.0, *)
struct CustomBottomToolbar: View {
    @Binding var selectedTab: AppTab
    var startARAnimation: () -> Void
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "house.fill", label: "HOME", tab: .home, selectedTab: $selectedTab)
            TabBarButton(icon: "network", label: "IOT HUB", tab: .iot, selectedTab: $selectedTab)
            
            Button(action: {
                if selectedTab != .ar {
                    startARAnimation()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(neonCyan.opacity(0.1))
                        .frame(width: 60, height: 60)
                    Circle()
                        .stroke(neonCyan, lineWidth: selectedTab == .ar ? 3 : 1)
                        .frame(width: 60, height: 60)
                    Image(systemName: "arkit")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(neonCyan)
                }
                .offset(y: -15)
            }
            .frame(width: 80)
            
            TabBarButton(icon: "graduationcap.fill", label: "TRAIN", tab: .training, selectedTab: $selectedTab)
            TabBarButton(icon: "person.crop.circle.fill", label: "PROFILE", tab: .profile, selectedTab: $selectedTab)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(Color.black.opacity(0.85))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(neonCyan.opacity(0.3)),
            alignment: .top
        )
    }
}

@available(iOS 16.0, *)
struct TabBarButton: View {
    let icon: String
    let label: String
    let tab: AppTab
    @Binding var selectedTab: AppTab
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        Button(action: {
            selectedTab = tab
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            .foregroundColor(selectedTab == tab ? neonCyan : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

@available(iOS 16.0, *)
struct AROpeningAnimation: View {
    var onComplete: () -> Void
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 1.0
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                    path.move(to: CGPoint(x: geo.size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: geo.size.width / 2, y: geo.size.height))
                }
                .stroke(neonCyan.opacity(0.6), lineWidth: 2)
            }
            .scaleEffect(scale)
            .opacity(opacity)
            
            Circle()
                .stroke(neonCyan, lineWidth: 4)
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
                .opacity(opacity)
                
            Text("INITIALIZING SPATIAL MAPPING")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(neonCyan)
                .offset(y: 80)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                scale = 15.0
                opacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
        }
    }
}

// MARK: - Boot Sequence Overlay

@available(iOS 16.0, *)
struct BootSequenceView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @State private var bootProgress: CGFloat = 0
    @State private var terminalText: [String] = []
    
    let bootLogs = [
        "INITIALIZING CORE KINEMATICS...",
        "LOADING LIDAR MAPPING ENGINE...",
        "BUFFERING NEURAL PROCESSING UNIT...",
        "CONNECTING TO BIOMETRIC DATA...",
        "SYSTEM STABILIZED. WELCOME."
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(terminalText, id: \.self) { line in
                    Text(line)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.85))
                }
                
                Spacer()
                
                // Progress bar
                VStack(alignment: .leading, spacing: 4) {
                    Text("SYSTEM INITIALIZATION: \(Int(bootProgress * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(Color(red: 0, green: 1, blue: 0.85))
                            .frame(width: bootProgress * 300, height: 4)
                            .shadow(color: Color(red: 0, green: 1, blue: 0.85).opacity(0.5), radius: 5)
                    }
                    .frame(width: 300)
                }
                .padding(.bottom, 40)
            }
            .padding(40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            startBootAnimation()
        }
    }
    
    func startBootAnimation() {
        for (index, log) in bootLogs.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.4) {
                withAnimation {
                    terminalText.append("> " + log)
                    bootProgress = CGFloat(index + 1) / CGFloat(bootLogs.count)
                }
                
                if index == bootLogs.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation {
                            viewModel.isBooting = false
                        }
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct ScanningLine: View {
    @State private var offset: CGFloat = -400
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color(red: 0, green: 1, blue: 0.85).opacity(0), 
                             Color(red: 0, green: 1, blue: 0.85).opacity(0.4), 
                             Color(red: 0, green: 1, blue: 0.85).opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 40)
            .offset(y: offset)
            .onAppear {
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    offset = 800
                }
            }
    }
}

// MARK: - Top Navigation Bar (Blueprint HUD Header)

@available(iOS 16.0, *)
struct TopNavigationBar: View {
    @ObservedObject var viewModel: KineprintViewModel
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                // App title & Greeting
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .foregroundColor(neonCyan)
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("KINEPRINT")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                    
                    Text("BUDDY ACTIVE: WELCOME, \(viewModel.userName.uppercased())")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan.opacity(0.6))
                        .padding(.leading, 2)
                }
                
                Spacer()
                
                // Status indicators
                HStack(spacing: 12) {
                    // LiDAR status
                    StatusPill(
                        icon: "lidar.topography",
                        label: viewModel.lidarAvailable ? "LiDAR" : "PLANE",
                        isActive: true,
                        color: neonCyan
                    )
                    
                    // Tracking status
                    StatusPill(
                        icon: "location.fill",
                        label: viewModel.trackingActive ? "TRACK" : "IDLE",
                        isActive: viewModel.trackingActive,
                        color: viewModel.trackingActive ? Color.green : Color.gray
                    )
                    
                    // Buddy status
                    StatusPill(
                        icon: "person.fill.questionmark",
                        label: buddyStatusLabel(viewModel.buddyStatus),
                        isActive: true,
                        color: buddyStatusColor(viewModel.buddyStatus)
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial.opacity(0.85))
            
            // Header bottom border
            Rectangle()
                .fill(neonCyan.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    private func buddyStatusLabel(_ status: BuddyStatus) -> String {
        switch status {
        case .idle: return "IDLE"
        case .tracking: return "ACTIVE"
        case .warning: return "CAUTION"
        case .providingInsight: return "INSIGHT"
        case .celebrating: return "SUCCESS"
        }
    }
    
    private func buddyStatusColor(_ status: BuddyStatus) -> Color {
        switch status {
        case .idle: return Color.gray
        case .tracking: return Color.green
        case .warning: return Color.orange
        case .providingInsight: return Color.blue
        case .celebrating: return Color.yellow
        }
    }
}

@available(iOS 16.0, *)
struct StatusPill: View {
    let icon: String
    let label: String
    let isActive: Bool
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .opacity(isActive ? 1.0 : 0.3)
            
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.9))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Sidebar Controls

@available(iOS 16.0, *)
struct SidebarControls: View {
    @ObservedObject var viewModel: KineprintViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            ControlButton(
                symbol: "arrow.triangle.branch",
                label: "Vectors",
                isActive: viewModel.showVectors,
                action: { viewModel.toggleVectors() }
            )
            
            ControlButton(
                symbol: "point.topleft.down.to.point.bottomright.curvepath.fill",
                label: "Record",
                isActive: viewModel.recordingPath,
                action: { viewModel.recordPath() }
            )
            
            ControlButton(
                symbol: "pause.circle",
                label: "Freeze",
                isActive: viewModel.freezeFrameMode,
                action: { viewModel.freezeFrame() }
            )
            
            ControlButton(
                symbol: "trash",
                label: "Clear",
                isActive: false,
                action: { viewModel.clearData() }
            )
        }
    }
}

@available(iOS 16.0, *)
struct ControlButton: View {
    let symbol: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isActive ? neonCyan : .white.opacity(0.6))
                
                Text(label.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(isActive ? neonCyan : .white.opacity(0.5))
            }
            .frame(width: 56, height: 52)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(isActive ? 0.7 : 0.45))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isActive ? neonCyan : Color.white.opacity(0.15), lineWidth: isActive ? 1.5 : 0.5)
            )
        }
    }
}

// MARK: - Bottom Dashboard (Real-Time Physics Charts)

@available(iOS 16.0, *)
struct BottomDashboard: View {
    @ObservedObject var viewModel: KineprintViewModel
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 8) {
            // Header with live readouts
            HStack {
                Text("MOTION ANALYSIS")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // Live data readouts
                HStack(spacing: 14) {
                    DataReadout(
                        label: "VEL",
                        value: String(format: "%.2f", viewModel.currentSpeed),
                        unit: "m/s",
                        color: Color.red
                    )
                    
                    DataReadout(
                        label: "ACC",
                        value: String(format: "%.2f", viewModel.currentAccelMagnitude),
                        unit: "m/s²",
                        color: Color.blue
                    )
                    
                    DataReadout(
                        label: "DST",
                        value: String(format: "%.3f", viewModel.totalDistance),
                        unit: "m",
                        color: neonCyan
                    )
                }
            }
            .padding(.horizontal, 12)
            
            // Metric picker
            Picker("Metric", selection: $viewModel.selectedMetric) {
                Text("VELOCITY").tag(ChartMetric.velocity)
                Text("ACCEL").tag(ChartMetric.acceleration)
                Text("POSITION").tag(ChartMetric.position)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .scaleEffect(0.85)
            
            // Chart
            if !viewModel.chartData.isEmpty {
                Chart(viewModel.chartData.suffix(60)) { point in
                    LineMark(
                        x: .value("T", point.index),
                        y: .value("V", point.value)
                    )
                    .foregroundStyle(chartColor.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    
                    AreaMark(
                        x: .value("T", point.index),
                        y: .value("V", point.value)
                    )
                    .foregroundStyle(chartColor.opacity(0.08).gradient)
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .trailing) { _ in
                        AxisValueLabel()
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.gray)
                    }
                }
                .frame(height: 90)
                .padding(.horizontal, 8)
            } else {
                // Empty state
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 90)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 20))
                            .foregroundColor(neonCyan.opacity(0.4))
                        Text("Tap a surface to begin tracking")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(neonCyan.opacity(0.15), lineWidth: 0.5)
        )
    }
    
    private var chartColor: Color {
        switch viewModel.selectedMetric {
        case .velocity: return .red
        case .acceleration: return .blue
        case .position: return neonCyan
        }
    }
}

@available(iOS 16.0, *)
struct DataReadout: View {
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.7))
            
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundColor(color.opacity(0.6))
            }
        }
    }
}



// MARK: - Chart Data Types

enum ChartMetric: String, CaseIterable {
    case velocity
    case acceleration
    case position
}

enum AssistantStyle: String, CaseIterable {
    case quiet
    case guided
}

enum MeasurementUnits: String, CaseIterable {
    case metric
    case imperial
}

enum BuddyStatus {
    case idle
    case tracking
    case warning
    case providingInsight
    case celebrating
}

@available(iOS 16.0, *)
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}

// MARK: - ViewModel

@available(iOS 16.0, *)
@MainActor
class KineprintViewModel: ObservableObject {
    @Published var showVectors = true
    @Published var recordingPath = false
    @Published var freezeFrameMode = false
    @Published var trackingActive = false
    @Published var lidarAvailable = false
    @Published var isScanning = true
    
    // Personalization & State
    @AppStorage("userName") var userName: String = ""
    @AppStorage("isOnboardingComplete") var isOnboardingComplete: Bool = false
    @Published var assistantStyle: AssistantStyle = .guided
    @Published var measurementUnits: MeasurementUnits = .metric
    @Published var isBooting = true
    
    // Chart data
    @Published var selectedMetric: ChartMetric = .velocity
    @Published var chartData: [ChartDataPoint] = []
    
    // Live readouts
    @Published var currentSpeed: Double = 0
    @Published var currentAccelMagnitude: Double = 0
    @Published var totalDistance: Double = 0
    
    // Buddy system
    @Published var buddyMessage: String = "Ready to assist."
    @Published var buddyStatus: BuddyStatus = .idle
    
    // Internal data storage
    private var velocityHistory: [Double] = []
    private var accelerationHistory: [Double] = []
    private var positionHistory: [Double] = []
    private var dataIndex: Int = 0
    private var lastPosition: SIMD3<Float>?
    
    private let physicsEngine = PhysicsEngine.shared
    
    init() {
        if ARWorldTrackingConfiguration.isSupported {
            lidarAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        } else {
            lidarAvailable = false
        }
    }
    
    func completeOnboarding(with name: String) {
        self.userName = name
        self.isOnboardingComplete = true
        self.isBooting = true // Trigger boot animation after onboarding
    }
    
    func toggleVectors() {
        showVectors.toggle()
    }
    
    func recordPath() {
        recordingPath.toggle()
    }
    
    func freezeFrame() {
        freezeFrameMode.toggle()
    }
    
    func clearData() {
        chartData = []
        velocityHistory = []
        accelerationHistory = []
        positionHistory = []
        dataIndex = 0
        currentSpeed = 0
        currentAccelMagnitude = 0
        totalDistance = 0
        lastPosition = nil
        trackingActive = false
    }
    
    func startTrackingObject(at position: SIMD3<Float>) {
        trackingActive = true
        lastPosition = position
    }
    
    func updateTrackedObject(position: SIMD3<Float>, velocity: SIMD3<Float>, acceleration: SIMD3<Float>) {
        guard trackingActive else { return }
        
        let speed = Double(length(velocity))
        let accelMag = Double(length(acceleration))
        let posY = Double(position.y)
        
        // Update live readouts
        currentSpeed = speed
        currentAccelMagnitude = accelMag
        
        // Accumulate distance
        if let last = lastPosition {
            totalDistance += Double(length(position - last))
        }
        lastPosition = position
        
        // Store history
        velocityHistory.append(speed)
        accelerationHistory.append(accelMag)
        positionHistory.append(posY)
        
        // Trim to last 200 samples
        if velocityHistory.count > 200 { velocityHistory.removeFirst() }
        if accelerationHistory.count > 200 { accelerationHistory.removeFirst() }
        if positionHistory.count > 200 { positionHistory.removeFirst() }
        
        dataIndex += 1
        
        // Update chart based on selected metric
        updateChartData()
        
        // Update buddy system
        updateBuddySystem(speed: speed, acceleration: accelMag)
    }
    
    private func updateBuddySystem(speed: Double, acceleration: Double) {
        // Update buddy status based on tracking data
        if speed > 0.5 && acceleration > 0.5 {
            buddyStatus = .tracking
            buddyMessage = "Detecting dynamic motion. Velocity: \(String(format: "%.2f", speed)) m/s"
        } else if speed < 0.1 && acceleration < 0.1 {
            buddyStatus = .idle
            buddyMessage = "Object appears stationary. Stable position detected."
        } else if acceleration > 5.0 {
            buddyStatus = .warning
            buddyMessage = "High acceleration detected! \(String(format: "%.2f", acceleration)) m/s²"
        } else if speed > 2.0 {
            buddyStatus = .providingInsight
            buddyMessage = "Fast movement detected. Consider slowing down for precision."
        } else {
            buddyStatus = .tracking
            buddyMessage = "Tracking in progress. All systems nominal."
        }
        
        // Adjust message based on assistant style
        if assistantStyle == .guided {
            switch buddyStatus {
            case .tracking:
                buddyMessage += " Continue smooth movements."
            case .warning:
                buddyMessage += " Exercise caution."
            case .providingInsight:
                buddyMessage += " Tip: Smooth motions yield better data."
            default:
                break
            }
        }
    }
    
    func updateChartData() {
        let source: [Double]
        switch selectedMetric {
        case .velocity: source = velocityHistory
        case .acceleration: source = accelerationHistory
        case .position: source = positionHistory
        }
        
        chartData = source.enumerated().map { ChartDataPoint(index: $0.offset, value: $0.element) }
    }
    
    func stopTracking() {
        trackingActive = false
    }
}
#endif
