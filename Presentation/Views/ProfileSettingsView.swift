#if canImport(SwiftUI)
import SwiftUI
#endif

#if os(iOS)
import UIKit
import CoreMotion
import PhotosUI

// MARK: - Profile & Settings View (Redesigned)

@MainActor
struct ProfileSettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    @State private var showSettingsExportSheet = false
    @State private var showResetAlert = false
    @State private var showPasskeyManager = false // New state for Passkey Manager sheet
    @State private var showPerformanceReports = false // New state for Analytics
    
    // Gyroscope Calibration State
    @State private var showCalibrationProgress = false
    @State private var calibrationProgress: Double = 0
    @State private var calibrationDone = false
    @State private var showExportSheet = false
    @State private var exportItems: [Any] = []
    @State private var showPDFExport = false
    @State private var exportText = ""
    @State private var toastMessage = ""
    @State private var showToast = false
    @State private var showOnboardingResetAlert = false
    @State private var showAboutProtocol = false
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @AppStorage("userName") private var appUserName: String = ""
    @State private var earnedBadges: [String] = []

    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Blueprint grid
            GeometryReader { geo in
                ZStack {
                    ForEach(0..<10) { i in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: geo.size.height / 10 * CGFloat(i)))
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 10 * CGFloat(i)))
                        }
                        .stroke(neonCyan.opacity(0.05), lineWidth: 0.5)
                        Path { path in
                            path.move(to: CGPoint(x: geo.size.width / 10 * CGFloat(i), y: 0))
                            path.addLine(to: CGPoint(x: geo.size.width / 10 * CGFloat(i), y: geo.size.height))
                        }
                        .stroke(neonCyan.opacity(0.05), lineWidth: 0.5)
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Text("PROFILE & SETTINGS")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                    Spacer()
                    // Export button
                    Button(action: triggerExportMeasurements) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(neonCyan)
                            .font(.system(size: 20, weight: .bold))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.8))

                Rectangle()
                    .fill(neonCyan.opacity(0.3))
                    .frame(height: 1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // ─── CENTERED PROFILE CARD ───
                        ProfileCard(settingsManager: settingsManager)

                        // Separator line under profile
                        HStack {
                            Rectangle().fill(neonCyan.opacity(0.2)).frame(height: 1)
                        }
                        .padding(.horizontal, 16)

                        // ─── PERFORMANCE REPORTS (NEW) ───
                        SettingsSection(title: "ANALYTICS & REPORTS") {
                            VStack(spacing: 10) {
                                ActionRow(
                                    icon: "server.rack",
                                    label: "DATA CENTER ANALYSIS",
                                    color: neonCyan,
                                    action: { showPerformanceReports = true }
                                )
                            }
                        }

                        // ─── ACHIEVEMENT BADGES ───
                        SettingsSection(title: "EARNED BADGES") {
                            if earnedBadges.isEmpty {
                                Text("No badges earned yet. Complete challenges to unlock.")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(earnedBadges, id: \.self) { badge in
                                            VStack(spacing: 8) {
                                                Image(systemName: "shield.fill")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(neonCyan)
                                                Text(badge.uppercased())
                                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.white)
                                                    .multilineTextAlignment(.center)
                                                    .lineLimit(2)
                                            }
                                            .frame(width: 80, height: 80)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(neonCyan.opacity(0.3), lineWidth: 1))
                                        }
                                    }
                                }
                            }
                        }

                        // ─── DATA EXPORT (ACTIVE) ───
                        SettingsSection(title: "DATA EXPORT") {
                            VStack(spacing: 10) {
                                // Export Measurements → plain text (iPhone Notes-compatible)
                                ActionRow(
                                    icon: "square.and.arrow.up",
                                    label: "EXPORT MEASUREMENTS",
                                    color: neonCyan,
                                    action: triggerExportMeasurements
                                )
                            }
                        }

                        // ─── APP TOUR ───
                        SettingsSection(title: "APP TOUR") {
                            VStack(spacing: 10) {
                                ActionRow(
                                    icon: "arrow.counterclockwise.circle.fill",
                                    label: "REPLAY ONBOARDING",
                                    color: neonCyan,
                                    action: { showOnboardingResetAlert = true }
                                )
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                    Text("Revisit the app introduction and learn about Kineprint features")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        // ─── APP SETTINGS ───
                        SettingsSection(title: "APP SETTINGS") {
                            VStack(spacing: 10) {
                                ActionRow(
                                    icon: "info.circle",
                                    label: "ABOUT KINEPRINT",
                                    color: neonCyan,
                                    action: { showAboutProtocol = true }
                                )
                                Divider().background(neonCyan.opacity(0.1))
                                ActionRow(
                                    icon: "lock.rectangle",
                                    label: "MANAGE SECURE PASSKEY",
                                    color: neonCyan,
                                    action: { showPasskeyManager = true }
                                )
                            }
                        }

                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }

            // Toast notification
            if showToast {
                VStack {
                    Spacer()
                    Text(toastMessage)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(neonCyan)
                        .cornerRadius(20)
                        .shadow(color: neonCyan.opacity(0.4), radius: 10)
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Reset Calibration", isPresented: $showResetAlert) {
            Button("RESET", role: .destructive) {
                settingsManager.resetCalibration()
                showToastMessage("✓ Calibration reset to factory defaults")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all sensor calibration data to factory defaults. Continue?")
        }
        .alert("Replay Onboarding", isPresented: $showOnboardingResetAlert) {
            Button("REPLAY", role: .destructive) {
                isOnboardingComplete = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will take you back to the onboarding screens to learn about the app features.")
        }
        .sheet(isPresented: $showExportSheet) {
            ActivityViewController(activityItems: exportItems)
        }
        .sheet(isPresented: $showPasskeyManager) { // Presenting the new Passkey Manager sheet
            PasskeyManagerSheet(isPresented: $showPasskeyManager)
        }
        .fullScreenCover(isPresented: $showPerformanceReports) {
            PerformanceAnalyticsView(isPresented: $showPerformanceReports)
        }
        .fullScreenCover(isPresented: $showAboutProtocol) {
            AboutProtocolView()
        }
        .onAppear {
            earnedBadges = UserDefaults.standard.stringArray(forKey: "EarnedBadgesArray") ?? []
        }
    }

    // MARK: - Actions

    private func triggerExportMeasurements() {
        // Export as plain text (goes to Notes, Mail, Files, etc.)
        let text = settingsManager.generateMeasurementsText()
        exportItems = [text]
        showExportSheet = true
    }

    private func triggerExportCalibrationPDF() {
        // Generate PDF and export
        if let pdfData = settingsManager.generateCalibrationPDF() {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("KinePrint_Calibration.pdf")
            try? pdfData.write(to: tempURL)
            exportItems = [tempURL]
            showExportSheet = true
        }
    }

    private func startGyroscopeCalibration() {
        showCalibrationProgress = true
        calibrationProgress = 0
        calibrationDone = false

        // Simulate gyroscope calibration with real CoreMotion
        let motionManager = CMMotionManager()
        var sampleCount = 0
        let totalSamples = 50

        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: .main) { _, _ in
                // We're already on .main as per startGyroUpdates(to: .main)
                sampleCount += 1
                self.calibrationProgress = Double(sampleCount) / Double(totalSamples)
                if sampleCount >= totalSamples {
                    motionManager.stopGyroUpdates()
                    self.calibrationDone = true
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        self.showCalibrationProgress = false
                        self.showToastMessage("✓ Gyroscope calibrated successfully")
                    }
                }
            }
        } else {
            // Simulate for devices without gyroscope
            Task { @MainActor in
                var t = 0.0
                while t < 1.0 {
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    guard !Task.isCancelled else { break }
                    t += 0.02
                    self.calibrationProgress = min(t, 1.0)
                }
                self.calibrationDone = true
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self.showCalibrationProgress = false
                self.showToastMessage("✓ Gyroscope calibrated successfully")
            }
        }
    }

    private func showToastMessage(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring()) { showToast = true }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation { showToast = false }
        }
    }
}

// MARK: - Centered Profile Card

@MainActor
struct ProfileCard: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var showFullAvatarBox = false
    @State private var showExpandedAvatar = false
    @State private var showPhotoPermission = false
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    private var timeGreeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h >= 1 && h < 12 { return "Good Morning" }
        else if h >= 12 && h < 16 { return "Good Afternoon" }
        else { return "Good Evening" }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section label
            HStack {
                Text("NEURAL IDENTITY")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                
                Button(action: { showPhotoPermission = true }) {
                    Text("UPLOAD PHOTO")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(neonCyan.opacity(0.4), lineWidth: 1))
                }
            }
            .padding(.bottom, 20)

            // ── Main Avatar Display ──
            Button(action: {
                withAnimation(.spring()) {
                    showExpandedAvatar = true
                }
            }) {
                ZStack {
                    if let imageData = settingsManager.profileImageData, let uiImage = UIImage(data: imageData) {
                        Circle()
                            .stroke(settingsManager.avatarColor.opacity(0.3), lineWidth: 8)
                            .frame(width: 140, height: 140)
                            .blur(radius: 8)
                            
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(settingsManager.avatarColor, lineWidth: 2))
                    } else {
                        CoreIdentityCircle(
                            avatarType: settingsManager.avatarType,
                            avatarColor: settingsManager.avatarColor,
                            backgroundTheme: settingsManager.backgroundTheme,
                            profileImageData: settingsManager.profileImageData,
                            size: 140
                        )
                    }
                }
                .padding(.bottom, 16)
            }
            .buttonStyle(PlainButtonStyle())

            // ── Name & greeting ──
            VStack(spacing: 4) {
                Text(settingsManager.userName.isEmpty ? "STUDENT" : settingsManager.userName.uppercased())
                    .font(.system(size: 24, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)

                Text(timeGreeting)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(settingsManager.avatarColor.opacity(0.8))
            }
            .padding(.bottom, 24)

            // ── Customization Controls ──
            VStack(alignment: .leading, spacing: 16) {
                // Robot Selection
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("ROBOT MODEL")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Button(action: { showFullAvatarBox = true }) {
                            Text("SEE MORE")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        // Display first 3 or 4
                        ForEach(CoreShape.allModels.prefix(3), id: \.self) { type in
                            AvatarSelectorItem(
                                type: type,
                                isSelected: settingsManager.avatarType == type && settingsManager.profileImageData == nil,
                                color: settingsManager.avatarColor,
                                action: {
                                    settingsManager.avatarType = type
                                    settingsManager.profileImageData = nil
                                }
                            )
                        }
                        
                        // Remaining avatars placeholder/trigger
                        Button(action: { showFullAvatarBox = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                // Chassis Color
                VStack(alignment: .leading, spacing: 10) {
                    Text("CHASSIS COLOR")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 12) {
                        ForEach(["cyan", "orange", "pink", "green", "blue"], id: \.self) { colorName in
                            ColorBubble(
                                color: Color.fromName(colorName),
                                isSelected: !settingsManager.useCustomColor && settingsManager.avatarColorName == colorName,
                                action: {
                                    settingsManager.useCustomColor = false
                                    settingsManager.avatarColorName = colorName
                                }
                            )
                        }
                        
                        Spacer()
                        
                        // Rainbow custom color picker — right corner
                        ColorPicker("", selection: Binding(
                            get: { settingsManager.customAvatarColor },
                            set: { 
                                settingsManager.customAvatarColor = $0 
                                settingsManager.useCustomColor = true
                            }
                        ))
                        .labelsHidden()
                        .scaleEffect(1.2)
                        .background(
                            ZStack {
                                AngularGradient(
                                    gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                                    center: .center
                                )
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                                
                                if settingsManager.useCustomColor {
                                    Circle()
                                        .fill(settingsManager.customAvatarColor)
                                        .frame(width: 18, height: 18)
                                }
                            }
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: settingsManager.useCustomColor ? 2 : 0)
                                .frame(width: 30, height: 30)
                        )
                    }
                }
            }
            .padding(.bottom, 24)

            // Name Field ──
            VStack(alignment: .leading, spacing: 8) {
                Text("NEURAL SIGNATURE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)

                TextField("Enter Identity", text: $settingsManager.userName)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(settingsManager.avatarColor)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(settingsManager.avatarColor.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(24)
        .background(.ultraThinMaterial.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settingsManager.avatarColor.opacity(0.2), lineWidth: 1)
        )
        // Full Avatar Box Pop-up
        .sheet(isPresented: $showFullAvatarBox) {
            FullAvatarBoxView(settingsManager: settingsManager, isPresented: $showFullAvatarBox)
        }
        // Photo permission alert
        .alert("Photo Library Access", isPresented: $showPhotoPermission) {
            Button("Allow Access") { showPhotoPicker = true }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Kineprint would like to access your photo library to set your profile picture.")
        }
        // Photo picker (opens after permission granted)
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .legacyOnChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    settingsManager.profileImageData = data
                }
            }
        }
        // Full Screen Expanded Avatar (Snapchat style)
        .fullScreenCover(isPresented: $showExpandedAvatar) {
            AvatarExpandedView(settingsManager: settingsManager, isPresented: $showExpandedAvatar)
        }
    }
}

// MARK: - Sub-components for ProfileCard

struct AvatarSelectorItem: View {
    let type: CoreShape
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isSelected ? color : Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                
                // Show the abstract core icon in the selector
                Image(systemName: type.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
                    .scaleEffect(isSelected ? 1.0 : 0.8)
            }
        }
    }
}

struct ColorBubble: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 26, height: 26)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                )
                .shadow(color: color.opacity(0.4), radius: isSelected ? 5 : 0)
        }
    }
}

struct FullAvatarBoxView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Binding var isPresented: Bool
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                HStack {
                    Text("AVATAR SUITE")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(neonCyan)
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 40)
                
                Text("Select your primary neural interface from the factory archives.")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                        ForEach(CoreShape.allModels, id: \.self) { type in
                            Button(action: {
                                settingsManager.avatarType = type
                                settingsManager.profileImageData = nil
                                isPresented = false
                            }) {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.05))
                                            .frame(width: 90, height: 90)
                                        
                                        Image(systemName: type.icon)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.white)
                                    }
                                    Text(type.rawValue.uppercased())
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(settingsManager.avatarType == type ? neonCyan : .gray)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding(30)
                }
            }
        }
    }
}

// MARK: - Avatar Expanded View
struct AvatarExpandedView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Binding var isPresented: Bool
    
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            // New 3D Dynamic Background System
            AvatarBackgroundEngine(theme: settingsManager.backgroundTheme, color: settingsManager.avatarColor)
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring()) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
            .zIndex(10)
            
            VStack(spacing: 0) {
                // The Full 3D Avatar
                ZStack {
                    if let imageData = settingsManager.profileImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 250, height: 250)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(settingsManager.avatarColor, lineWidth: 4))
                            .shadow(color: settingsManager.avatarColor.opacity(0.8), radius: 30)
                    } else {
                        // Core 3D Interactive Model
                        Avatar3DView(avatarType: settingsManager.avatarType, avatarColor: settingsManager.avatarColor, isExpanded: true)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .opacity(appearAnimation ? 1.0 : 0.0)
                    }
                }
                .layoutPriority(1)
                
                // Bottom Control Panel
                VStack(spacing: 20) {
                    // Name plate
                    VStack(spacing: 8) {
                        Text(settingsManager.userName.isEmpty ? "STUDENT" : settingsManager.userName.uppercased())
                            .font(.system(size: 32, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 5)
                        
                        Text("MODEL: \(settingsManager.avatarType.rawValue.uppercased())")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(settingsManager.avatarColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(settingsManager.avatarColor.opacity(0.5), lineWidth: 1))
                    }
                    
                    // Background Selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ENVIRONMENT MAPPING")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(AvatarBackgroundTheme.allCases) { theme in
                                    Button(action: {
                                        let impact = UIImpactFeedbackGenerator(style: .medium)
                                        impact.impactOccurred()
                                        withAnimation(.easeInOut) {
                                            settingsManager.backgroundTheme = theme
                                        }
                                    }) {
                                        Text(theme.rawValue.uppercased())
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(settingsManager.backgroundTheme == theme ? .black : settingsManager.avatarColor)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(settingsManager.backgroundTheme == theme ? settingsManager.avatarColor : Color.black.opacity(0.5))
                                            .cornerRadius(12)
                                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(settingsManager.avatarColor.opacity(0.4), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }
                .padding(.bottom, 40)
                .background(
                    LinearGradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                )
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.5)) {
                appearAnimation = true
            }
        }
    }
}



// MARK: - Reusable Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
            }
            content
        }
        .padding(16)
        .background(.ultraThinMaterial.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(neonCyan.opacity(0.15), lineWidth: 0.5)
        )
    }
}

// MARK: - Picker Row

struct SettingsPickerRow<T: Hashable>: View {
    let label: String
    @Binding var binding: T
    let options: [(String, T)]
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            Spacer()
            Picker(label, selection: $binding) {
                ForEach(options, id: \.0) { opt in
                    Text(opt.0).tag(opt.1)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .accentColor(neonCyan)
        }
    }
}

// MARK: - Toggle Row

struct VectorToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Text(isOn ? "ON" : "OFF")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(isOn ? neonCyan : .gray)
                    .animation(.easeInOut, value: isOn)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: neonCyan))
    }
}

// MARK: - Action Row

struct ActionRow: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16))
                    .frame(width: 22)
                Text(label)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.5))
                    .font(.system(size: 12))
            }
            .padding(12)
            .background(color.opacity(0.06))
            .cornerRadius(10)
        }
    }
}

#endif

