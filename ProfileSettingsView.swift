#if canImport(SwiftUI)
import SwiftUI
#endif

#if os(iOS)

struct ProfileSettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    
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
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(neonCyan)
                            .font(.system(size: 24, weight: .bold))
                        
                        Spacer()
                        
                        Text("PROFILE & SETTINGS")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "doc.badge.plus")
                                .foregroundColor(neonCyan)
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // User Info Section
                            UserInfoSection(settingsManager: settingsManager)
                            
                            // Units Selection
                            UnitsSelectionSection(settingsManager: settingsManager)
                            
                            // Performance Mode
                            PerformanceModeSection(settingsManager: settingsManager)
                            
                            // Vector Visibility Toggles
                            VectorVisibilitySection(settingsManager: settingsManager)
                            
                            // Data Export
                            DataExportSection(settingsManager: settingsManager)
                            
                            // Calibration Reset
                            CalibrationResetSection(settingsManager: settingsManager)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }
                    
                    Spacer()
                }
            }
        .preferredColorScheme(.dark)
    }
}

struct UserInfoSection: View {
    @ObservedObject var settingsManager: SettingsManager
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("USER PROFILE")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            HStack {
                ZStack {
                    Circle()
                        .fill(neonCyan.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.fill")
                        .foregroundColor(neonCyan)
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preferred Name")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    TextField("Enter your name", text: $settingsManager.userName)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                        .padding(.vertical, 4)
                        .padding(.leading, 8)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
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

struct UnitsSelectionSection: View {
    @ObservedObject var settingsManager: SettingsManager
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("UNITS")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Measurement")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Picker("Units", selection: $settingsManager.measurementUnits) {
                        Text("Metric").tag(MeasurementUnits.metric)
                        Text("Imperial").tag(MeasurementUnits.imperial)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(neonCyan)
                }
                
                HStack {
                    Text("Temperature")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Picker("Temp", selection: $settingsManager.temperatureUnit) {
                        Text("Celsius").tag(TemperatureUnit.celsius)
                        Text("Fahrenheit").tag(TemperatureUnit.fahrenheit)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(neonCyan)
                }
            }
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

struct PerformanceModeSection: View {
    @ObservedObject var settingsManager: SettingsManager
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("PERFORMANCE MODE")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Rendering Quality")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Picker("Quality", selection: $settingsManager.renderingQuality) {
                        Text("High").tag(RenderingQuality.high)
                        Text("Balanced").tag(RenderingQuality.balanced)
                        Text("Efficient").tag(RenderingQuality.efficient)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(neonCyan)
                }
                
                HStack {
                    Text("LiDAR Density")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Picker("Density", selection: $settingsManager.lidarDensity) {
                        Text("Detailed").tag(LiDARDensity.detailed)
                        Text("Standard").tag(LiDARDensity.standard)
                        Text("Light").tag(LiDARDensity.light)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .accentColor(neonCyan)
                }
            }
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

struct VectorVisibilitySection: View {
    @ObservedObject var settingsManager: SettingsManager
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("VECTOR VISIBILITY")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                Toggle(isOn: $settingsManager.showVelocityVectors) {
                    HStack {
                        Text("Velocity Vectors")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(settingsManager.showVelocityVectors ? "ON" : "OFF")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: neonCyan))
                
                Toggle(isOn: $settingsManager.showAccelerationVectors) {
                    HStack {
                        Text("Acceleration Vectors")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(settingsManager.showAccelerationVectors ? "ON" : "OFF")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: neonCyan))
                
                Toggle(isOn: $settingsManager.showTrajectoryGhosting) {
                    HStack {
                        Text("Trajectory Ghosting")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(settingsManager.showTrajectoryGhosting ? "ON" : "OFF")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: neonCyan))
                
                Toggle(isOn: $settingsManager.showGridOverlay) {
                    HStack {
                        Text("Grid Overlay")
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(settingsManager.showGridOverlay ? "ON" : "OFF")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: neonCyan))
            }
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

struct DataExportSection: View {
    @ObservedObject var settingsManager: SettingsManager
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("DATA EXPORT")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                Button(action: { settingsManager.exportData() }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(neonCyan)
                        
                        Text("EXPORT MEASUREMENTS")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                }
                
                Button(action: { settingsManager.exportCalibration() }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(neonCyan)
                        
                        Text("EXPORT CALIBRATION")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                }
            }
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

struct CalibrationResetSection: View {
    @ObservedObject var settingsManager: SettingsManager
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("CALIBRATION")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            VStack(spacing: 10) {
                Button(action: { settingsManager.resetCalibration() }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.orange)
                        
                        Text("RESET CALIBRATION")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                }
                
                Button(action: { settingsManager.calibrateGyroscope() }) {
                    HStack {
                        Image(systemName: "gyroscope")
                            .foregroundColor(neonCyan)
                        
                        Text("CALIBRATE GYROSCOPE")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
                }
            }
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

// MARK: - Settings Models

enum TemperatureUnit: String, CaseIterable {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"
}

enum RenderingQuality: String, CaseIterable {
    case high = "High"
    case balanced = "Balanced"
    case efficient = "Efficient"
}

enum LiDARDensity: String, CaseIterable {
    case detailed = "Detailed"
    case standard = "Standard"
    case light = "Light"
}

class SettingsManager: ObservableObject {
    @Published var userName: String = "Engineering Student"
    @Published var measurementUnits: MeasurementUnits = .metric
    @Published var temperatureUnit: TemperatureUnit = .celsius
    @Published var renderingQuality: RenderingQuality = .balanced
    @Published var lidarDensity: LiDARDensity = .standard
    @Published var showVelocityVectors = true
    @Published var showAccelerationVectors = true
    @Published var showTrajectoryGhosting = true
    @Published var showGridOverlay = true
    
    func exportData() {
        // Simulate data export
        print("Exporting measurements data...")
    }
    
    func exportCalibration() {
        // Simulate calibration export
        print("Exporting calibration data...")
    }
    
    func resetCalibration() {
        // Simulate calibration reset
        print("Resetting calibration...")
    }
    
    func calibrateGyroscope() {
        // Simulate gyroscope calibration
        print("Calibrating gyroscope...")
    }
}
#endif

