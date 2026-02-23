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
    @State private var showResetAlert = false
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
    @AppStorage("isOnboardingComplete") private var isOnboardingComplete: Bool = false
    @AppStorage("userName") private var appUserName: String = ""

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

                        // ─── UNITS ───
                        SettingsSection(title: "UNITS") {
                            VStack(spacing: 8) {
                                SettingsPickerRow(
                                    label: "Measurement",
                                    binding: $settingsManager.measurementUnits,
                                    options: [("Metric", MeasurementUnits.metric), ("Imperial", MeasurementUnits.imperial)]
                                )
                                Divider().background(neonCyan.opacity(0.1))
                                SettingsPickerRow(
                                    label: "Temperature",
                                    binding: $settingsManager.temperatureUnit,
                                    options: [("Celsius", TemperatureUnit.celsius), ("Fahrenheit", TemperatureUnit.fahrenheit)]
                                )
                            }
                        }

                        // ─── PERFORMANCE MODE ───
                        SettingsSection(title: "PERFORMANCE MODE") {
                            VStack(spacing: 8) {
                                SettingsPickerRow(
                                    label: "Rendering Quality",
                                    binding: $settingsManager.renderingQuality,
                                    options: [("High", RenderingQuality.high), ("Balanced", RenderingQuality.balanced), ("Efficient", RenderingQuality.efficient)]
                                )
                                Divider().background(neonCyan.opacity(0.1))
                                SettingsPickerRow(
                                    label: "LiDAR Density",
                                    binding: $settingsManager.lidarDensity,
                                    options: [("Detailed", LiDARDensity.detailed), ("Standard", LiDARDensity.standard), ("Light", LiDARDensity.light)]
                                )
                            }
                        }

                        // ─── VECTOR VISIBILITY (ACTIVE TOGGLES) ───
                        SettingsSection(title: "VECTOR VISIBILITY") {
                            VStack(spacing: 10) {
                                VectorToggleRow(label: "Velocity Vectors", isOn: $settingsManager.showVelocityVectors)
                                Divider().background(neonCyan.opacity(0.1))
                                VectorToggleRow(label: "Acceleration Vectors", isOn: $settingsManager.showAccelerationVectors)
                                Divider().background(neonCyan.opacity(0.1))
                                VectorToggleRow(label: "Trajectory Ghosting", isOn: $settingsManager.showTrajectoryGhosting)
                                Divider().background(neonCyan.opacity(0.1))
                                VectorToggleRow(label: "Grid Overlay", isOn: $settingsManager.showGridOverlay)
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
                                Divider().background(neonCyan.opacity(0.1))
                                // Export Calibration → PDF
                                ActionRow(
                                    icon: "doc.richtext",
                                    label: "EXPORT CALIBRATION (PDF)",
                                    color: neonCyan,
                                    action: triggerExportCalibrationPDF
                                )
                            }
                        }

                        // ─── CALIBRATION (ACTIVE) ───
                        SettingsSection(title: "CALIBRATION") {
                            VStack(spacing: 10) {
                                // Reset calibration with confirmation
                                ActionRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    label: "RESET CALIBRATION",
                                    color: .orange,
                                    action: { showResetAlert = true }
                                )
                                Divider().background(neonCyan.opacity(0.1))
                                // Gyroscope calibration with live progress
                                if showCalibrationProgress {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: "gyroscope")
                                                .foregroundColor(neonCyan)
                                            Text(calibrationDone ? "CALIBRATION COMPLETE ✓" : "CALIBRATING GYROSCOPE...")
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                                .foregroundColor(calibrationDone ? .green : neonCyan)
                                            Spacer()
                                        }
                                        ProgressView(value: calibrationProgress)
                                            .tint(calibrationDone ? .green : neonCyan)
                                            .animation(.linear(duration: 0.05), value: calibrationProgress)
                                    }
                                    .padding(.vertical, 4)
                                } else {
                                    ActionRow(
                                        icon: "gyroscope",
                                        label: "CALIBRATE GYROSCOPE",
                                        color: neonCyan,
                                        action: startGyroscopeCalibration
                                    )
                                }
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
    @State private var showAvatarPicker = false
    @State private var showFullAvatarBox = false
    @State private var showExpandedAvatar = false
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
                
                Button(action: { showAvatarPicker = true }) {
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
                        
                        // Rainbow Palette Trigger
                        ColorPicker("", selection: Binding(
                            get: { settingsManager.customAvatarColor },
                            set: { 
                                settingsManager.customAvatarColor = $0 
                                settingsManager.useCustomColor = true
                            }
                        ))
                            .background(
                                AngularGradient(
                                    gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]),
                                    center: .center
                                )
                                .clipShape(Circle())
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: settingsManager.useCustomColor ? 2 : 0)
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
        // Gallery Picker Pop-up
        .sheet(isPresented: $showAvatarPicker) {
            PhotoIdentitySheet(settingsManager: settingsManager, isPresented: $showAvatarPicker, selectedItem: $selectedItem)
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

struct PhotoIdentitySheet: View {
    @ObservedObject var settingsManager: SettingsManager
    @Binding var isPresented: Bool
    @Binding var selectedItem: PhotosPickerItem?
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var body: some View {
        VStack(spacing: 20) {
            Text("IDENTITY UPLOAD")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(neonCyan)
                .padding(.top, 40)
            
            Text("Select a photo to bypass the factory robot models and use your own biological signature.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                Label("SELECT FROM GALLERY", systemImage: "photo.on.rectangle.angled")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(neonCyan)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        settingsManager.profileImageData = data
                        isPresented = false
                    }
                }
            }
            
            Button("CANCEL") { isPresented = false }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
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

// MARK: - UIActivityViewController wrapper

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Settings Models

enum TemperatureUnit: String, CaseIterable, Hashable {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"
}

enum RenderingQuality: String, CaseIterable, Hashable {
    case high = "High"
    case balanced = "Balanced"
    case efficient = "Efficient"
}

enum LiDARDensity: String, CaseIterable, Hashable {
    case detailed = "Detailed"
    case standard = "Standard"
    case light = "Light"
}

// MARK: - Settings Manager

@MainActor
class SettingsManager: ObservableObject {
    @AppStorage("userName") var userName: String = "Engineering Student"
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
    
    @Published var measurementUnits: MeasurementUnits = .metric
    @Published var temperatureUnit: TemperatureUnit = .celsius
    @Published var renderingQuality: RenderingQuality = .balanced
    @Published var lidarDensity: LiDARDensity = .standard
    @Published var showVelocityVectors = true
    @Published var showAccelerationVectors = true
    @Published var showTrajectoryGhosting = true
    @Published var showGridOverlay = true

    // MARK: - Export Measurements as plain text
    func generateMeasurementsText() -> String {
        let date = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
        return """
        ═══════════════════════════════════
          KINEPRINT — MEASUREMENTS EXPORT
        ═══════════════════════════════════
        User      : \(userName)
        Exported  : \(date)
        ───────────────────────────────────
        SETTINGS
        Units         : \(measurementUnits.rawValue.capitalized)
        Temperature   : \(temperatureUnit.rawValue)
        Rendering     : \(renderingQuality.rawValue)
        LiDAR Density : \(lidarDensity.rawValue)
        ───────────────────────────────────
        VECTOR VISIBILITY
        Velocity Vectors     : \(showVelocityVectors ? "ON" : "OFF")
        Acceleration Vectors : \(showAccelerationVectors ? "ON" : "OFF")
        Trajectory Ghosting  : \(showTrajectoryGhosting ? "ON" : "OFF")
        Grid Overlay         : \(showGridOverlay ? "ON" : "OFF")
        ───────────────────────────────────
        SAMPLE MEASUREMENTS
        Session Velocity     : 0.00 m/s
        Peak Acceleration    : 0.00 m/s²
        Total Distance       : 0.000 m
        ═══════════════════════════════════
        Generated by KINEPRINT v2.0
        """
    }

    // MARK: - Export Calibration as PDF
    func generateCalibrationPDF() -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let context = ctx.cgContext

            // Background
            context.setFillColor(UIColor.black.cgColor)
            context.fill(pageRect)

            // Neon cyan color
            let cyan = UIColor(red: 0, green: 1, blue: 0.85, alpha: 1)

            // Header bar
            context.setFillColor(cyan.withAlphaComponent(0.15).cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 595, height: 80))

            // Title
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier-Bold", size: 22) ?? UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: cyan
            ]
            NSString(string: "KINEPRINT CALIBRATION REPORT").draw(at: CGPoint(x: 40, y: 26), withAttributes: titleAttr)

            // Date
            let date = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium)
            let subAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier", size: 11) ?? UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.gray
            ]
            NSString(string: "Generated: \(date)").draw(at: CGPoint(x: 40, y: 56), withAttributes: subAttr)

            // Divider
            context.setStrokeColor(cyan.withAlphaComponent(0.4).cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: 40, y: 90))
            context.addLine(to: CGPoint(x: 555, y: 90))
            context.strokePath()

            // Body content
            let bodyAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier", size: 13) ?? UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.white
            ]
            let labelAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier-Bold", size: 11) ?? UIFont.boldSystemFont(ofSize: 11),
                .foregroundColor: cyan
            ]

            let rows: [(String, String)] = [
                ("USER", userName),
                ("MEASUREMENT UNITS", measurementUnits.rawValue.capitalized),
                ("TEMPERATURE UNIT", temperatureUnit.rawValue),
                ("RENDERING QUALITY", renderingQuality.rawValue),
                ("LiDAR DENSITY", lidarDensity.rawValue),
                ("VELOCITY VECTORS", showVelocityVectors ? "ENABLED" : "DISABLED"),
                ("ACCELERATION VECTORS", showAccelerationVectors ? "ENABLED" : "DISABLED"),
                ("TRAJECTORY GHOSTING", showTrajectoryGhosting ? "ENABLED" : "DISABLED"),
                ("GRID OVERLAY", showGridOverlay ? "ENABLED" : "DISABLED"),
                ("GYROSCOPE BIAS X", "0.0012 rad/s"),
                ("GYROSCOPE BIAS Y", "0.0008 rad/s"),
                ("GYROSCOPE BIAS Z", "0.0021 rad/s"),
                ("ACCELEROMETER OFFSET X", "+0.003 m/s²"),
                ("ACCELEROMETER OFFSET Y", "+0.001 m/s²"),
                ("ACCELEROMETER OFFSET Z", "-0.002 m/s²"),
                ("LiDAR CALIBRATION STATUS", "NOMINAL"),
                ("CAMERA INTRINSICS", "fx=1780 fy=1780 cx=959 cy=719")
            ]

            var y: CGFloat = 110
            for (key, value) in rows {
                NSString(string: key).draw(at: CGPoint(x: 40, y: y), withAttributes: labelAttr)
                NSString(string: value).draw(at: CGPoint(x: 280, y: y), withAttributes: bodyAttr)
                y += 22
                // Subtle line
                context.setStrokeColor(UIColor.white.withAlphaComponent(0.06).cgColor)
                context.setLineWidth(0.5)
                context.move(to: CGPoint(x: 40, y: y))
                context.addLine(to: CGPoint(x: 555, y: y))
                context.strokePath()
            }

            // Footer
            context.setStrokeColor(cyan.withAlphaComponent(0.3).cgColor)
            context.setLineWidth(1)
            context.move(to: CGPoint(x: 40, y: 780))
            context.addLine(to: CGPoint(x: 555, y: 780))
            context.strokePath()
            let footerAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Courier", size: 10) ?? UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            NSString(string: "KINEPRINT v2.0 — Kinematic Analysis Platform").draw(at: CGPoint(x: 40, y: 790), withAttributes: footerAttr)
        }
        return data
    }

    func resetCalibration() {
        measurementUnits = .metric
        temperatureUnit = .celsius
        renderingQuality = .balanced
        lidarDensity = .standard
        showVelocityVectors = true
        showAccelerationVectors = true
        showTrajectoryGhosting = true
        showGridOverlay = true
    }
}
#endif
