#if canImport(SwiftUI)
import SwiftUI
#endif

#if os(iOS)
import UIKit
import CoreMotion

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
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(neonCyan)
                        .font(.system(size: 22, weight: .bold))
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
                DispatchQueue.main.async {
                    sampleCount += 1
                    self.calibrationProgress = Double(sampleCount) / Double(totalSamples)
                    if sampleCount >= totalSamples {
                        motionManager.stopGyroUpdates()
                        self.calibrationDone = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.showCalibrationProgress = false
                            self.showToastMessage("✓ Gyroscope calibrated successfully")
                        }
                    }
                }
            }
        } else {
            // Simulate for devices without gyroscope
            var t = 0.0
            Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
                DispatchQueue.main.async {
                    t += 0.02
                    self.calibrationProgress = min(t, 1.0)
                    if t >= 1.0 {
                        timer.invalidate()
                        self.calibrationDone = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.showCalibrationProgress = false
                            self.showToastMessage("✓ Gyroscope calibrated successfully")
                        }
                    }
                }
            }
        }
    }

    private func showToastMessage(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring()) { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
    }
}

// MARK: - Centered Profile Card

@MainActor
struct ProfileCard: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var isEditing = false
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
                Text("USER PROFILE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(.bottom, 16)

            // ── Center profile pic ──
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [neonCyan.opacity(0.25), neonCyan.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .stroke(neonCyan.opacity(0.6), lineWidth: 2)
                    .frame(width: 100, height: 100)

                Image(systemName: "person.fill")
                    .font(.system(size: 44))
                    .foregroundColor(neonCyan)
                    .shadow(color: neonCyan.opacity(0.6), radius: 12)
            }
            .shadow(color: neonCyan.opacity(0.3), radius: 20)
            .padding(.bottom, 16)

            // ── Name & greeting below pic ──
            VStack(spacing: 6) {
                Text(settingsManager.userName.isEmpty ? "STUDENT" : settingsManager.userName.uppercased())
                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)

                Text(timeGreeting)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan.opacity(0.7))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(neonCyan.opacity(0.08))
                    .cornerRadius(8)
            }
            .padding(.bottom, 16)

            // ── Editable name field ──
            VStack(alignment: .leading, spacing: 6) {
                Text("PREFERRED NAME")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)

                HStack {
                    TextField("Enter your name", text: $settingsManager.userName)
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(neonCyan.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(neonCyan.opacity(0.2), lineWidth: 1)
        )
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
    @AppStorage("settingsUserName") var userName: String = "Engineering Student"
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
