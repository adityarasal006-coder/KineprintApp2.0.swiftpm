#if canImport(SwiftUI)
import SwiftUI
#endif

import AudioToolbox
import ARKit
import SceneKit
import Metal
import MetalKit
import Charts
import Combine
import Foundation
import CoreBluetooth
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - App Tabs


enum AppTab {
    case home
    case iot
    case ar
    case training
    case profile
}

// MARK: - Main View


struct KineprintView: View {
    @StateObject private var viewModel = KineprintViewModel()
    @State private var selectedTab: AppTab = .home
    @State private var showingARAnimation = false
    @State private var showExitConfirm = false
    @State private var showGoodbye = false
    private let speechSynth = AVSpeechSynthesizer()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // Root opaque layer
            
            if !viewModel.isOnboardingComplete {
                OnboardingView(viewModel: viewModel)
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    if selectedTab != .ar {
                        TopNavigationBar(viewModel: viewModel, showExitConfirm: $showExitConfirm)
                    }
                    
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
                    
                    CustomBottomToolbar(viewModel: viewModel, selectedTab: $selectedTab, startARAnimation: {
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
            // Exit Confirmation Overlay
            if showExitConfirm {
                ZStack {
                    Color.black.opacity(0.85)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { showExitConfirm = false } }
                    
                    VStack(spacing: 24) {
                        Image(systemName: "power.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(red: 0, green: 1, blue: 0.85))
                            .shadow(color: Color(red: 0, green: 1, blue: 0.85).opacity(0.5), radius: 10)
                        
                        VStack(spacing: 8) {
                            Text("TERMINATE SESSION?")
                                .font(.system(size: 18, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Text("Are you sure you want to exit the Kineprint environment?")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        HStack(spacing: 20) {
                            // NO Button
                            Button(action: {
                                let name = viewModel.userName
                                speak("\(name), let's continue!")
                                withAnimation {
                                    showExitConfirm = false
                                    selectedTab = .home
                                }
                            }) {
                                Text("NO")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 100, height: 44)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3), lineWidth: 1))
                            }
                            
                            // YES Button
                            Button(action: {
                                withAnimation {
                                    showExitConfirm = false
                                    showGoodbye = true
                                }
                                speakGoodbye()
                            }) {
                                Text("YES")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(width: 100, height: 44)
                                    .background(Color(red: 0, green: 1, blue: 0.85))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(30)
                    .background(Color.black)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0, green: 1, blue: 0.85).opacity(0.3), lineWidth: 1))
                    .padding(.horizontal, 20)
                }
                .transition(.opacity)
            }
            // Goodbye overlay
            if showGoodbye {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("👋")
                            .font(.system(size: 80))
                            .scaleEffect(showGoodbye ? 1.0 : 0.5)
                        
                        Text("SYSTEM LOGOFF")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text("GOODBYE \(viewModel.userName.uppercased()) BUDDY!")
                            .font(.system(size: 24, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color(red: 0, green: 1, blue: 0.85))
                            .shadow(color: Color(red: 0, green: 1, blue: 0.85).opacity(0.5), radius: 12)
                        
                        Text("Waiting for you to come back!")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .animation(.easeInOut, value: viewModel.isOnboardingComplete)
        .animation(.easeInOut, value: selectedTab)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showGoodbye)
        .onAppear {
            if viewModel.isOnboardingComplete {
                speakWelcomeBack()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                showGoodbye = false
                showExitConfirm = false
            } else if newPhase == .background {
                showGoodbye = false 
                showExitConfirm = false
            }
        }
    }
    
    // MARK: - Voice
    
    private var timeGreeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h >= 1 && h < 12 { return "Good Morning" }
        else if h >= 12 && h < 16 { return "Good Afternoon" }
        else { return "Good Evening" }
    }
    
    private func speakWelcomeBack() {
        let name = viewModel.userName.trimmingCharacters(in: .whitespaces)
        let text = "\(timeGreeting), \(name)!"
        speak(text)
    }
    
    private func speakGoodbye() {
        let name = viewModel.userName.trimmingCharacters(in: .whitespaces)
        speak("Goodbye \(name) buddy! Waiting for you to come back!")
    }
    
    private func speak(_ text: String) {
        speechSynth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        
        let voices = AVSpeechSynthesisVoice.speechVoices()
        // Prioritize "Samantha" or "Alex" for English, or any voice with "premium" or "enhanced"
        let preferredVoice = voices.first { $0.identifier.contains("premium") || $0.identifier.contains("enhanced") }
            ?? voices.first { $0.name == "Samantha" }
            ?? AVSpeechSynthesisVoice(language: "en-US")
        
        utterance.voice = preferredVoice
        utterance.rate = 0.45 // Natural speaking speed
        utterance.pitchMultiplier = 1.05 // Friendly, approachable tone
        utterance.volume = 0.9
        
        // Add a tiny bit of natural phrasing pause
        utterance.postUtteranceDelay = 0.1
        
        speechSynth.speak(utterance)
    }
}


struct ARScannerTab: View {
    @ObservedObject var viewModel: KineprintViewModel

    var body: some View {
        ZStack {
            ARCameraView(viewModel: viewModel)
            
            VStack(spacing: 0) {
                // Top section: Motion Analysis relocated to the very top
                MotionAnalysisDashboard(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.top, 4) // Tight padding for maximum scanner space
                
                if viewModel.isScanning {
                    ScanningLine()
                }
                
                Spacer()
                
                // Sidebar controls
                HStack(alignment: .bottom) {
                    Spacer()
                    SidebarControls(viewModel: viewModel)
                        .padding(.trailing, 12)
                        .padding(.bottom, 16)
                }
                
                // Bottom section: ONLY capture button so it lowers naturally
                // The capture button has been naturally migrated to the main tab bar 
                // See `CustomBottomToolbar`
            }
            
            // Hacker Processing state
            if viewModel.isHackerProcessing {
                HackerProcessingAnimationView(viewModel: viewModel)
                    .transition(.opacity)
            } else if viewModel.showCapturedBlueprint, let entry = viewModel.lastScannedEntry {
                BlueprintDisplayView(viewModel: viewModel, entry: entry)
                    .transition(.opacity)
            } else if viewModel.isDeepScanning {
                // Legacy HUD
                DeepScanHUD(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
    }
}


struct CustomBottomToolbar: View {
    @ObservedObject var viewModel: KineprintViewModel
    @Binding var selectedTab: AppTab
    var startARAnimation: () -> Void
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "house.fill", label: "HOME", tab: .home, selectedTab: $selectedTab)
            TabBarButton(icon: "network", label: "IOT HUB", tab: .iot, selectedTab: $selectedTab)
            
            Button(action: {
                if selectedTab == .ar {
                    viewModel.captureBlueprintImage()
                } else {
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
                    Image(systemName: selectedTab == .ar ? "camera.viewfinder" : "arkit")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(neonCyan)
                }
                .offset(y: -15)
            }
            .frame(width: 80)
            
            TabBarButton(icon: "graduationcap.fill", label: "TRAIN", tab: .training, selectedTab: $selectedTab)
            
            // Profile Tab with Dynamic Avatar
            Button(action: { selectedTab = .profile }) {
                VStack(spacing: 4) {
                    Group {
                        if let data = viewModel.profileImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 22, height: 22)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(viewModel.avatarColor, lineWidth: selectedTab == .profile ? 1.5 : 0))
                        } else {
                            Image(systemName: viewModel.avatarType.icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedTab == .profile ? viewModel.avatarColor : .gray)
                        }
                    }
                    Text("PROFILE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundColor(selectedTab == .profile ? neonCyan : .gray)
                .frame(maxWidth: .infinity)
            }
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
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                onComplete()
            }
        }
    }
}

// MARK: - Matrix/Hacker Rain Boot Animation


struct BootSequenceView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @State private var columns: [MatrixColumn] = []
    @State private var bootProgress: CGFloat = 0
    @State private var terminalLines: [String] = []
    @State private var showWelcome = false
    @State private var isMatrixRunning = false

    private let neonGreen = Color(red: 0.1, green: 1.0, blue: 0.2)
    private let brightGreen = Color(red: 0.6, green: 1.0, blue: 0.6)
    private let columnCount = 28

    private let bootMessages = [
        "> ACCESSING NEURAL CORE...",
        "> INJECTING KINEMATIC ENGINE...",
        "> BREACHING LiDAR FIREWALL...",
        "> DECRYPTING MOTION SENSORS...",
        "> OVERRIDING PHYSICS MODULE...",
        "> SYSTEM COMPROMISED. WELCOME."
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Matrix rain columns
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ForEach(columns.indices, id: \.self) { i in
                        MatrixColumnView(column: columns[i], screenHeight: geo.size.height)
                            .frame(width: geo.size.width / CGFloat(columnCount))
                    }
                }
            }
            .ignoresSafeArea()

            // Terminal overlay
            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(terminalLines, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(line.contains("COMPROMISED") || line.contains("WELCOME") ? brightGreen : neonGreen)
                            .shadow(color: neonGreen.opacity(0.8), radius: 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    Text("SYSTEM BREACH: \(Int(bootProgress * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(neonGreen.opacity(0.7))
                        .shadow(color: neonGreen.opacity(0.5), radius: 3)

                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(colors: [neonGreen, brightGreen], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: bootProgress * g.size.width, height: 6)
                                .shadow(color: neonGreen.opacity(0.9), radius: 6)
                                .animation(.linear(duration: 0.15), value: bootProgress)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }

            // Welcome flash
            if showWelcome {
                VStack(spacing: 12) {
                    Text("ACCESS GRANTED")
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundColor(brightGreen)
                        .shadow(color: neonGreen.opacity(1.0), radius: 20)
                    Text("KINEPRINT SYSTEMS ONLINE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(neonGreen.opacity(0.8))
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            spawnColumns()
            startBootSequence()
        }
    }

    private func spawnColumns() {
        columns = (0..<columnCount).map { _ in
            MatrixColumn(
                chars: Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#$%&!?"),
                speed: Double.random(in: 0.04...0.12),
                startDelay: Double.random(in: 0...1.5),
                length: Int.random(in: 6...20),
                currentRow: 0,
                opacity: Double.random(in: 0.4...1.0)
            )
        }

        isMatrixRunning = true
        Task { @MainActor in
            while isMatrixRunning {
                try? await Task.sleep(nanoseconds: 70_000_000) // 0.07s
                guard !Task.isCancelled && isMatrixRunning else { break }
                for i in columns.indices {
                    columns[i].advance()
                }
            }
        }
    }

    private func startBootSequence() {
        let total = bootMessages.count
        Task { @MainActor in
            for (idx, msg) in bootMessages.enumerated() {
                try? await Task.sleep(nanoseconds: 550_000_000) // 0.55s
                withAnimation(.easeIn(duration: 0.2)) {
                    terminalLines.append(msg)
                    bootProgress = CGFloat(idx + 1) / CGFloat(total)
                }
            }
            
            try? await Task.sleep(nanoseconds: 400_000_000) // 0.4s
            withAnimation(.spring()) { showWelcome = true }
            
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s
            isMatrixRunning = false
            withAnimation(.easeOut(duration: 0.6)) {
                viewModel.isBooting = false
            }
        }
    }
}

// MARK: - Matrix Column Model

struct MatrixColumn {
    var chars: [Character]
    var speed: Double
    var startDelay: Double
    var length: Int
    var currentRow: Int
    var opacity: Double
    var displayChars: [Character] = []
    var isActive = false
    private var delayCounter = 0.0

    init(chars: [Character], speed: Double, startDelay: Double, length: Int, currentRow: Int, opacity: Double) {
        self.chars = chars
        self.speed = speed
        self.startDelay = startDelay
        self.length = length
        self.currentRow = currentRow
        self.opacity = opacity
    }

    mutating func advance() {
        if !isActive {
            delayCounter += 0.07
            if delayCounter >= startDelay { isActive = true }
            return
        }
        currentRow += 1
        // Refresh random chars in the column
        if displayChars.count < length {
            displayChars.append(chars.randomElement() ?? "0")
        } else {
            displayChars.removeFirst()
            displayChars.append(chars.randomElement() ?? "0")
        }
        if currentRow > 40 {
            currentRow = 0
            displayChars.removeAll()
        }
    }
}


struct MatrixColumnView: View {
    let column: MatrixColumn
    let screenHeight: CGFloat
    private let charHeight: CGFloat = 20
    private let neonGreen = Color(red: 0.1, green: 1.0, blue: 0.2)
    private let brightGreen = Color(red: 0.7, green: 1.0, blue: 0.7)

    var body: some View {
        VStack(spacing: 0) {
            // Offset for the column's current position
            Spacer().frame(height: CGFloat(column.currentRow) * charHeight)
            ForEach(column.displayChars.indices, id: \.self) { i in
                let isHead = i == column.displayChars.count - 1
                Text(String(column.displayChars[i]))
                    .font(.system(size: 14, weight: isHead ? .heavy : .regular, design: .monospaced))
                    .foregroundColor(isHead ? brightGreen : neonGreen.opacity(column.opacity * Double(i + 1) / Double(column.displayChars.count + 1)))
                    .shadow(color: neonGreen.opacity(isHead ? 0.9 : 0.3), radius: isHead ? 6 : 2)
                    .frame(height: charHeight)
            }
            Spacer()
        }
        .opacity(column.isActive ? 1 : 0)
    }
}


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


struct TopNavigationBar: View {
    @ObservedObject var viewModel: KineprintViewModel
    @Binding var showExitConfirm: Bool
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    private var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 1 && hour < 12 {
            return "Good Morning"       // 1:00 AM – 11:59 AM
        } else if hour >= 12 && hour < 16 {
            return "Good Afternoon"     // 12:00 PM – 3:59 PM
        } else {
            return "Good Evening"       // 4:00 PM – 12:59 AM
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                // App title
                VStack(alignment: .leading, spacing: 2) {
                    Text("KINEPRINT")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                    
                    Text("\(timeBasedGreeting), \(viewModel.userName.uppercased())")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.avatarColor.opacity(0.7))
                        .padding(.leading, 2)
                }
                
                Spacer()
                
                // Clean system status
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.trackingActive ? Color.green : neonCyan)
                        .frame(width: 8, height: 8)
                        .shadow(color: (viewModel.trackingActive ? Color.green : neonCyan).opacity(0.6), radius: 4)
                    
                    Text(viewModel.trackingActive ? "TRACKING" : "READY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.trackingActive ? Color.green : neonCyan)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            Capsule()
                                .stroke((viewModel.trackingActive ? Color.green : neonCyan).opacity(0.3), lineWidth: 0.5)
                        )
                )
                
                // Exit Button
                Button(action: { withAnimation { showExitConfirm = true } }) {
                    Image(systemName: "power")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.red.opacity(0.8))
                        .padding(8)
                        .background(Circle().fill(Color.red.opacity(0.1)))
                }
                .padding(.leading, 8)
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
}

// MARK: - Sidebar Controls


struct SidebarControls: View {
    @ObservedObject var viewModel: KineprintViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            // Master Toggle (First Icon + Chevron)
            HStack(spacing: 4) {
                Button(action: {
                    withAnimation(.spring()) {
                        viewModel.isSidebarExpanded.toggle()
                    }
                }) {
                    Image(systemName: viewModel.isSidebarExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0, green: 1, blue: 0.85))
                        .padding(6)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                
                ControlButton(
                    symbol: "arrow.triangle.branch",
                    label: "Vectors",
                    isActive: viewModel.showVectors,
                    action: { viewModel.toggleVectors() }
                )
            }
            
            if viewModel.isSidebarExpanded {
                VStack(spacing: 10) {
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
                    
                    ControlButton(
                        symbol: "target",
                        label: "Scan",
                        isActive: viewModel.isDeepScanning,
                        action: { viewModel.initiateDeepScan() }
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
}
// MARK: - Deep Scan HUD


struct DeepScanHUD: View {
    @ObservedObject var viewModel: KineprintViewModel
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DEEP SCAN IN PROGRESS")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        Text("IDENTIFYING MATERIAL COMPOSITION...")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text("\(Int(viewModel.deepScanProgress * 100))%")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                }
                .padding(20)
                .background(Color.black.opacity(0.8))
                
                Spacer()
                
                if let entry = viewModel.lastScannedEntry {
                    VStack(spacing: 20) {
                        Text("OBJECT ANALYSIS COMPLETE")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                            .shadow(color: .green.opacity(0.5), radius: 10)
                        
                        HStack(spacing: 30) {
                            // Blueprint Preview
                            VStack(spacing: 8) {
                                Text("BLUEPRINT")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                ZStack {
                                    Rectangle().stroke(neonCyan.opacity(0.4), lineWidth: 1)
                                        .frame(width: 120, height: 120)
                                    // Simulated blueprint lines
                                    ForEach(0..<4) { i in
                                        Path { p in
                                            p.move(to: CGPoint(x: 10, y: 30 * i + 10))
                                            p.addLine(to: CGPoint(x: 110, y: 30 * i + 10))
                                        }
                                        .stroke(neonCyan.opacity(0.2), lineWidth: 0.5)
                                    }
                                    Image(systemName: "square.dashed")
                                        .font(.system(size: 60))
                                        .foregroundColor(neonCyan.opacity(0.6))
                                }
                            }
                            
                            // Details
                            VStack(alignment: .leading, spacing: 12) {
                                ScanDetailRow(label: "NAME", value: entry.title)
                                ScanDetailRow(label: "SIZE", value: entry.dimensions)
                                ScanDetailRow(label: "MAT", value: entry.material)
                                ScanDetailRow(label: "MASS", value: entry.mass)
                                ScanDetailRow(label: "QUAL", value: entry.scanQuality)
                            }
                        }
                        .padding(20)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(neonCyan.opacity(0.3), lineWidth: 1))
                        
                        Text("SAVED TO RESEARCH FOLDER")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan.opacity(0.6))
                    }
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Scanning Ring
                    ZStack {
                        Circle()
                            .stroke(neonCyan.opacity(0.2), lineWidth: 2)
                            .frame(width: 200, height: 200)
                        Circle()
                            .trim(from: 0, to: viewModel.deepScanProgress)
                            .stroke(neonCyan, lineWidth: 4)
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "viewfinder")
                            .font(.system(size: 60))
                            .foregroundColor(neonCyan)
                    }
                    .padding(.bottom, 140)
                }
            }
        }
    }
}


struct ScanDetailRow: View {
    let label: String
    let value: String
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(neonCyan)
        }
    }
}

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


struct MotionAnalysisDashboard: View {
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
                .frame(height: 50)
                .padding(.horizontal, 8)
            } else {
                // Empty state
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 50)
                    
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


struct ChartDataPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}


struct ResearchEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let title: String
    let dimensions: String
    let material: String
    let blueprintData: String // Simulated blueprint string
    let mass: String
    let scanQuality: String
    var imagePath: String? = nil
}


struct ResearchPaper: Identifiable, Codable {
    let id: UUID
    let date: Date
    let title: String
    let content: String
}

// MARK: - ViewModel


@MainActor
class KineprintViewModel: ObservableObject {
    @Published var showVectors = true
    @Published var recordingPath = false
    @Published var freezeFrameMode = false
    @Published var trackingActive = false
    @Published var lidarAvailable = false
    @Published var isScanning = true
    @Published var isDeepScanning = false
    @Published var deepScanProgress: CGFloat = 0
    @Published var lastScannedEntry: ResearchEntry?
    @Published var researchEntries: [ResearchEntry] = []
    @Published var publishedPapers: [ResearchPaper] = []
    @Published var isSidebarExpanded = false
    
    // New processing states
    @Published var isHackerProcessing = false
    @Published var showCapturedBlueprint = false
    
    var onCaptureBlueprint: (() -> UIImage?)? = nil
    
    // Personalization & State
    @AppStorage("userName") var userName: String = ""
    @AppStorage("avatarType") var avatarType: CoreShape = .sphere
    @AppStorage("avatarColorName") var avatarColorName: String = "cyan"
    @AppStorage("customAvatarColorHex") var customAvatarColorHex: String = "#00FFFF"
    @AppStorage("profileImageData") var profileImageData: Data?
    @AppStorage("useCustomColor") var useCustomColor: Bool = false
    @AppStorage("avatarBgStyle") var avatarBgStyle: String = AvatarBackgroundTheme.nebulaVoid.rawValue
    
    var backgroundTheme: AvatarBackgroundTheme {
        get { AvatarBackgroundTheme(rawValue: avatarBgStyle) ?? .nebulaVoid }
        set { avatarBgStyle = newValue.rawValue }
    }
    
    var customAvatarColor: Color {
        get { Color(hex: customAvatarColorHex) }
        set { customAvatarColorHex = newValue.toHex() }
    }
    
    var avatarColor: Color {
        useCustomColor ? customAvatarColor : Color.fromName(avatarColorName)
    }
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

    // MARK: - Research & Deep Scan
    
    func initiateDeepScan() {
        isDeepScanning = true
        deepScanProgress = 0
        
        Task { @MainActor in
            while isDeepScanning {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
                guard !Task.isCancelled else { break }
                
                self.deepScanProgress += 0.02
                if self.deepScanProgress >= 1.0 {
                    self.completeDeepScan()
                    break
                }
            }
        }
    }
    
    private func completeDeepScan() {
        let newEntry = ResearchEntry(
            id: UUID(),
            date: Date(),
            title: "OBJECT_\(Int.random(in: 1000...9999))",
            dimensions: "\(Double.random(in: 10...50).formatted(.number.precision(.fractionLength(1)))) x \(Double.random(in: 10...50).formatted(.number.precision(.fractionLength(1)))) x \(Double.random(in: 5...20).formatted(.number.precision(.fractionLength(1)))) cm",
            material: ["AISI 304 Stainless", "6061 Aluminum", "ABS Polymer", "Carbon Fiber Composite"].randomElement() ?? "Metal Alloy",
            blueprintData: "RAW_BLUEPRINT_VECTOR_\(UUID().uuidString.prefix(8))",
            mass: "\(Double.random(in: 0.2...5.0).formatted(.number.precision(.fractionLength(2)))) kg",
            scanQuality: "98.4% NOMINAL"
        )
        
        researchEntries.append(newEntry)
        lastScannedEntry = newEntry
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.isDeepScanning = false
            self.lastScannedEntry = nil
        }
    }
    
    func cloneEntry(_ entry: ResearchEntry) {
        let cloned = ResearchEntry(
            id: UUID(),
            date: Date(),
            title: entry.title + "_CLONE",
            dimensions: entry.dimensions,
            material: entry.material,
            blueprintData: entry.blueprintData,
            mass: entry.mass,
            scanQuality: entry.scanQuality
        )
        researchEntries.append(cloned)
    }
    
    // MARK: - Papers
    
    func publishPaper(title: String, content: String) {
        let paper = ResearchPaper(id: UUID(), date: Date(), title: title, content: content)
        publishedPapers.append(paper)
    }
    
    // MARK: - Capture & Blueprint Flow
    
    func captureBlueprintImage() {
        // Trigger haptic
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        // Take snapshot immediately
        let snapshot = onCaptureBlueprint?()
        
        isHackerProcessing = true
        showCapturedBlueprint = false
        
        // Let processing animation run for ~2.5 seconds, then show blueprint
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            self.generateBlueprintResult(image: snapshot)
            withAnimation(.easeOut(duration: 0.5)) {
                self.isHackerProcessing = false
                self.showCapturedBlueprint = true
            }
        }
    }
    
    private func saveImageLocally(_ image: UIImage, id: UUID) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = getDocumentsDirectory().appendingPathComponent("\(id.uuidString).jpg")
        try? data.write(to: filename)
        return filename.path
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    private func generateBlueprintResult(image: UIImage?) {
        guard let img = image, let cgImg = img.cgImage else {
            generateMockBlueprintResult()
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImg, options: [:])
        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                self?.generateMockBlueprintResult()
                return
            }
            
            let label = topResult.identifier.replacingOccurrences(of: "_", with: " ").capitalized
            let confidence = topResult.confidence
            
            // Heuristic for material
            var material = "Composite"
            let l = label.lowercased()
            if l.contains("person") || l.contains("human") || l.contains("face") { material = "Biological Tissue" }
            else if l.contains("metal") || l.contains("steel") { material = "Industrial Alloy" }
            else if l.contains("wood") { material = "Organic Cellulose" }
            else if l.contains("plastic") { material = "High-Density Polymer" }
            
            DispatchQueue.main.async {
                let newId = UUID()
                let savedPath = self?.saveImageLocally(img, id: newId)
                
                let newEntry = ResearchEntry(
                    id: newId,
                    date: Date(),
                    title: label.uppercased(),
                    dimensions: "\(Double.random(in: 10...150).formatted(.number.precision(.fractionLength(2))))W x \(Double.random(in: 10...150).formatted(.number.precision(.fractionLength(2))))H cm",
                    material: material,
                    blueprintData: "VEC_\(UUID().uuidString.prefix(10))",
                    mass: "\(Double.random(in: 0.1...70.0).formatted(.number.precision(.fractionLength(2)))) kg",
                    scanQuality: "\(String(format: "%.1f", confidence * 100))% PRECISION",
                    imagePath: savedPath
                )
                
                self?.researchEntries.insert(newEntry, at: 0)
                self?.lastScannedEntry = newEntry
                NotificationManager.shared.scheduleScanCompleteNotification(itemName: newEntry.title)
            }
        }
        
        do {
            try handler.perform([request])
        } catch {
            generateMockBlueprintResult()
        }
    }
    
    private func generateMockBlueprintResult() {
        let newEntry = ResearchEntry(
            id: UUID(),
            date: Date(),
            title: "UNKNOWN_ASSET",
            dimensions: "45.2W x 32.1H cm",
            material: "Organic-Synthetic Hybrid",
            blueprintData: "RAW_BLUEPRINT_VECTOR",
            mass: "1.24 kg",
            scanQuality: "88.2% ESTIMATED"
        )
        researchEntries.insert(newEntry, at: 0)
        lastScannedEntry = newEntry
    }

    func dismissBlueprintView() {
        showCapturedBlueprint = false
    }
}

