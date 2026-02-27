import SwiftUI

// MARK: - Lidar Diagnostics View

@MainActor
struct LidarDiagnosticsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var progress: CGFloat = 0.0
    @State private var scanLogs: [String] = []
    @State private var isComplete = false
    @State private var threatLevel: Int = 0 // 0: Normal, 1: Threat, 2: Secure
    @State private var scannerAngle: Double = 0
    @State private var randomHexes: [String] = (0..<5).map { _ in "0x000" }
    
    private let neonCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    private let starkWhite = Color(red: 0.9, green: 0.95, blue: 1.0)
    private let draftBlue = Color(red: 0.02, green: 0.08, blue: 0.15)
    
    let allLogs = [
        "Initializing internal sandbox sweep...",
        "Scanning application core modules...",
        "Analyzing memory footprint parameters...",
        "WARNING: Malicious code injection detected!",
        "Isolating rogue data-thread [0xFE12]...",
        "Executing counter-measure logic...",
        "Threat purged. Re-aligning logic matrix...",
        "Diagnostics Complete: App Core Secure."
    ]
    
    var body: some View {
        ZStack {
            draftBlue.ignoresSafeArea()
            EngineeringGridBackground(cyanColor: neonCyan)
                .opacity(0.3)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("APP_CORE_DIAGNOSTICS")
                            .font(.system(size: 24, weight: .black, design: .monospaced))
                            .foregroundColor(threatLevel == 1 ? .red : neonCyan)
                            .glow(color: (threatLevel == 1 ? Color.red : neonCyan).opacity(0.5), radius: 5)
                        Text("SYS.ID // \(randomHexes[0])")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    TargetingBracket(color: neonCyan)
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 30)
                .padding(.top, 40)
                
                Spacer()
                
                // Advanced App-Core Scanner Widget
                ZStack {
                    // Outer spinning dashed ring
                    Circle()
                        .stroke((threatLevel == 1 ? Color.red : (threatLevel == 2 ? Color.green : neonCyan)).opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [10, 15]))
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(scannerAngle * (threatLevel == 1 ? 3.0 : 0.5)))
                    
                    // Middle solid ring
                    Circle()
                        .stroke((threatLevel == 1 ? Color.red : (threatLevel == 2 ? Color.green : neonCyan)).opacity(0.5), lineWidth: 1)
                        .frame(width: 250, height: 250)
                    
                    // Internal core threat visualizer
                    CoreThreatScanner(progress: progress, threatLevel: threatLevel)
                        .frame(width: 230, height: 230)
                    
                    // Rotating crosshair sweep
                    Path { path in
                        path.move(to: CGPoint(x: 140, y: 0))
                        path.addLine(to: CGPoint(x: 140, y: 280))
                        path.move(to: CGPoint(x: 0, y: 140))
                        path.addLine(to: CGPoint(x: 280, y: 140))
                    }
                    .stroke((threatLevel == 1 ? Color.red : (threatLevel == 2 ? Color.green : neonCyan)).opacity(0.4), lineWidth: 1)
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-scannerAngle * (threatLevel == 1 ? 2.5 : 1.0)))
                }
                .padding(.vertical, 30)
                .offset(x: threatLevel == 1 ? CGFloat.random(in: -4...4) : 0, y: threatLevel == 1 ? CGFloat.random(in: -4...4) : 0) // Overload shake
                
                // Live Status Reading
                HStack {
                    VStack(alignment: .leading) {
                        Text(threatLevel == 1 ? "STATUS: THREAT" : (isComplete ? "STATUS: SECURE" : "STATUS: SCANNING"))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(threatLevel == 1 ? .red : (isComplete ? .green : neonCyan))
                            .glow(color: threatLevel == 1 ? .red : .clear, radius: 5)
                        Text("MATRIX: \(String(format: "%.0f%%", progress * 100))")
                            .font(.system(size: 28, weight: .heavy, design: .monospaced))
                            .foregroundColor(starkWhite)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        ForEach(1..<4, id: \.self) { i in
                            Text("NODE_\(i): \(randomHexes[i])")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(neonCyan.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Terminal Logs Console
                VStack(alignment: .leading, spacing: 6) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(scanLogs.indices, id: \.self) { index in
                                    HStack(spacing: 8) {
                                        Text(">")
                                            .foregroundColor(logColor(for: index))
                                            .glow(color: logColor(for: index), radius: 2)
                                        Text(scanLogs[index])
                                            .foregroundColor(logColor(for: index).opacity(0.9))
                                        Spacer()
                                    }
                                    .font(.system(size: 12, design: .monospaced))
                                    .id(index)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: scanLogs.count) { _ in
                            if !scanLogs.isEmpty {
                                withAnimation {
                                    proxy.scrollTo(scanLogs.count - 1, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .frame(height: 120)
                .background(Color.black.opacity(0.6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(neonCyan.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Action Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: threatLevel == 1 ? "exclamationmark.triangle.fill" : (isComplete ? "lock.shield.fill" : "xmark.octagon.fill"))
                        Text(threatLevel == 1 ? "PURGE_MANUALLY" : (isComplete ? "SECURE_EXIT" : "ABORT_SCAN"))
                    }
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(isComplete ? .black : (threatLevel == 1 ? .red : neonCyan))
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(isComplete ? (threatLevel == 2 ? Color.green : neonCyan) : Color.clear)
                    .background(threatLevel == 1 ? Color.red.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(threatLevel == 1 ? Color.red : (isComplete ? Color.green : neonCyan), lineWidth: isComplete ? 0 : 2)
                            .padding(-4)
                    )
                    .shadow(color: threatLevel == 1 ? Color.red : (isComplete ? Color.green.opacity(0.5) : .clear), radius: threatLevel == 1 ? 15 : 10)
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            runDiagnostics()
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                scannerAngle = 360
            }
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                Task { @MainActor in
                    if !isComplete {
                        for i in 0..<5 {
                            randomHexes[i] = "0x" + String(format: "%04X", Int.random(in: 0...65535))
                        }
                    }
                }
            }
        }
    }
    
    private func logColor(for index: Int) -> Color {
        if index >= 3 && index <= 5 { return .red }
        if index >= 6 { return .green }
        return neonCyan
    }

    private func runDiagnostics() {
        var delay: Double = 0.5
        for (index, log) in allLogs.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring()) {
                    scanLogs.append(log)
                    progress = CGFloat(index + 1) / CGFloat(allLogs.count)
                    
                    if index >= 3 && index <= 5 {
                        threatLevel = 1
                    } else if index >= 6 {
                        threatLevel = 2
                    }
                    
                    if index == allLogs.count - 1 {
                        isComplete = true
                    }
                }
            }
            delay += (index >= 3 && index <= 5) ? 1.5 : 0.6
        }
    }
}

@MainActor
struct CoreThreatScanner: View {
    let progress: CGFloat
    let threatLevel: Int
    
    let neonCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    
    @State private var internalRotation: Double = 0
    @State private var alertPulse: CGFloat = 1.0
    
    var activeColor: Color {
        if threatLevel == 1 { return .red }
        if threatLevel == 2 { return .green }
        return neonCyan
    }
    
    var body: some View {
        ZStack {
            // Intense Background Pulse for Threats
            Circle()
                .fill(activeColor.opacity(threatLevel == 1 ? 0.3 : 0.05))
                .blur(radius: threatLevel == 1 ? 20 : 10)
                .frame(width: 220, height: 220)
                .scaleEffect(threatLevel == 1 ? alertPulse : 1.0)
                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: alertPulse)
            
            // J.A.R.V.I.S. Core Shape (Hexagon Network)
            Path { path in
                let center: CGPoint = CGPoint(x: 115, y: 115) 
                let radius: CGFloat = 85
                let twoPi: CGFloat = 2 * .pi
                
                for i in 0..<6 {
                    let angle: CGFloat = CGFloat(i) * (twoPi / 6)
                    let x: CGFloat = center.x + radius * cos(angle)
                    let y: CGFloat = center.y + radius * sin(angle)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                path.closeSubpath()
                
                // Starburst center lines
                for i in 0..<6 {
                    let angle: CGFloat = CGFloat(i) * (twoPi / 6)
                    let x: CGFloat = center.x + radius * cos(angle)
                    let y: CGFloat = center.y + radius * sin(angle)
                    path.move(to: center)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(activeColor.opacity(0.8), lineWidth: threatLevel == 1 ? 4 : 2)
            .shadow(color: activeColor, radius: 5)
            .rotationEffect(.degrees(internalRotation))
            
            // Threat Data Corruptions
            if threatLevel == 1 {
                ForEach(0..<20, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: CGFloat.random(in: 10...50), height: CGFloat.random(in: 2...6))
                        .offset(x: CGFloat.random(in: -90...90), y: CGFloat.random(in: -90...90))
                        .opacity(Double.random(in: 0.4...1.0))
                }
            }
            
            // Optical scanning sweep
            if threatLevel != 2 {
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, activeColor, .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 230, height: 4)
                    .offset(y: -115 + (progress * 230))
                    .shadow(color: activeColor, radius: 10)
            }
            
            // System Locked / Secured Hologram
            if threatLevel == 2 {
                Image(systemName: "checkmark.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.green)
                    .glow(color: .green, radius: 20)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .clipShape(Circle())
        .background(Color.black.opacity(0.4))
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                internalRotation = 360
            }
            alertPulse = 1.1
        }
        .onChange(of: threatLevel) { _ in
            if threatLevel == 1 {
                withAnimation(.linear(duration: 0.3).repeatForever(autoreverses: false)) {
                    internalRotation += 360 
                }
            } else if threatLevel == 2 {
                withAnimation(.spring()) {
                    internalRotation = 0 // Align structural matrix
                }
            }
        }
    }
}


// MARK: - Lidar Calibration View 

@MainActor
struct LidarCalibrationView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var scanPitch: Double = -45.0
    @State private var scanYaw: Double = 60.0
    @State private var scanRoll: Double = -30.0
    @State private var isCalibrated = false
    
    @State private var frameRotation = 0.0
    @State private var waveformOffset: CGFloat = 0.0
    
    private let neonCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    private let deepBlue = Color(red: 0.02, green: 0.08, blue: 0.15)
    
    var body: some View {
        ZStack {
            deepBlue.ignoresSafeArea()
            EngineeringGridBackground(cyanColor: neonCyan)
                .opacity(0.4)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    TargetingBracket(color: neonCyan)
                        .frame(width: 30, height: 30)
                    Spacer()
                    Text("SPATIAL_CALIBRATION")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(neonCyan)
                        .glow(color: neonCyan.opacity(0.5), radius: 5)
                    Spacer()
                    TargetingBracket(color: neonCyan)
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(180))
                }
                .padding(.horizontal, 30)
                .padding(.top, 40)
                
                Spacer()
                
                // Upgraded 3D Spatial Surface Detection
                SpatialDetectionSurface(pitch: $scanPitch, yaw: $scanYaw, roll: $scanRoll, isCalibrated: isCalibrated)
                    .frame(height: 350)
                
                // Animated Sine Wave Sync Display
                ZStack {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .border(neonCyan.opacity(0.3), width: 1)
                    
                    SineWave(frequency: isCalibrated ? 2 : 4, amplitude: isCalibrated ? 5 : 20, phase: waveformOffset)
                        .stroke(isCalibrated ? Color.green : neonCyan.opacity(0.8), lineWidth: 2)
                        .glow(color: isCalibrated ? .green : neonCyan, radius: 3)
                }
                .frame(height: 60)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
                
                // Cyberpunk styled calibration multi-bars
                VStack(spacing: 24) {
                    CyberCalibrationBar(title: "AXIS-X (PITCH)", value: $scanPitch, target: 0.0, color: .red)
                    CyberCalibrationBar(title: "AXIS-Y (YAW)", value: $scanYaw, target: 0.0, color: .blue)
                    CyberCalibrationBar(title: "AXIS-Z (ROLL)", value: $scanRoll, target: 0.0, color: .green)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // Confirm Overide Button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(isCalibrated ? "SYNC_BONDING_COMPLETE" : "FORCE_OVERRIDE")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(isCalibrated ? Color.green : neonCyan.opacity(0.8))
                        .cornerRadius(4) // squared cyberpunk edges
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isCalibrated ? Color.green : neonCyan, lineWidth: 2)
                                .padding(-4)
                        )
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startCalibrationSequence()
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                frameRotation = 360
            }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                waveformOffset = 100
            }
        }
    }
    
    private func startCalibrationSequence() {
        // Complex multi-stage animation for locking the rings
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 2.0)) {
                scanPitch = 15.0
                scanYaw = -20.0
                scanRoll = 10.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 2.0, dampingFraction: 0.6)) {
                scanPitch = 0.0
                scanYaw = 0.0
                scanRoll = 0.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            withAnimation(.easeIn(duration: 0.5)) {
                isCalibrated = true
            }
        }
    }
}

// MARK: - Reusable Sci-Fi Components

struct SineWave: Shape {
    var frequency: Double
    var amplitude: Double
    var phase: Double
    
    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(amplitude, phase) }
        set {
            amplitude = newValue.first
            phase = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = Double(rect.width)
        let height = Double(rect.height)
        let midHeight = height / 2
        
        let wavelength = width / frequency
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / wavelength
            let sine = sin(relativeX * 2 * .pi + (phase * 0.1))
            let y = amplitude * sine + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct CyberCalibrationBar: View {
    let title: String
    @Binding var value: Double
    let target: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("> " + title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(color.opacity(0.8))
                Spacer()
                Text(String(format: "%.2f°", value))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor((abs(value - target) < 0.1) ? .green : .white)
            }
            
            // Segmented Bar
            GeometryReader { geo in
                let isAligned = abs(value - target) < 0.1
                let alignmentColor = isAligned ? Color.green : color
                
                ZStack(alignment: .leading) {
                    // Background segments
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                        }
                    }
                    
                    // Fill segments
                    let percentage = 1.0 - min(abs(value - target) / 90.0, 1.0)
                    let filledCount = Int(percentage * 20.0)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<20, id: \.self) { i in
                            Rectangle()
                                .fill(i < filledCount ? alignmentColor : Color.clear)
                                .glow(color: alignmentColor, radius: i < filledCount ? 2 : 0)
                        }
                    }
                }
            }
            .frame(height: 12)
        }
    }
}

struct TargetingBracket: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width
                let h = geo.size.height
                path.move(to: CGPoint(x: 0, y: h * 0.3))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: w * 0.3, y: 0))
                
                path.move(to: CGPoint(x: w, y: h * 0.3))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w * 0.7, y: 0))
                
                path.move(to: CGPoint(x: 0, y: h * 0.7))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: w * 0.3, y: h))
                
                path.move(to: CGPoint(x: w, y: h * 0.7))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w * 0.7, y: h))
            }
            .stroke(color, lineWidth: 2)
            .shadow(color: color, radius: 2)
        }
    }
}

struct SpatialDetectionSurface: View {
    @Binding var pitch: Double
    @Binding var yaw: Double
    @Binding var roll: Double
    var isCalibrated: Bool
    
    let neonCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    @State private var scanLineOffset: CGFloat = -160
    @State private var dataPoints = (0..<40).map { _ in CGPoint(x: CGFloat.random(in: 10...210), y: CGFloat.random(in: 10...310)) }
    
    var body: some View {
        ZStack {
            // A simulated 3D "page" or "surface plane" being detected
            ZStack {
                // Base Page Substrate
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .border(isCalibrated ? Color.green : neonCyan.opacity(0.6), width: 2)
                    .frame(width: 220, height: 320)
                    
                // Inner mesh grid for LiDAR scanning
                Path { path in
                    let w: CGFloat = 220
                    let h: CGFloat = 320
                    for i in 1..<8 {
                        let x = CGFloat(i) * w / 8
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: h))
                    }
                    for i in 1..<12 {
                        let y = CGFloat(i) * h / 12
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: w, y: y))
                    }
                }
                .stroke(isCalibrated ? Color.green.opacity(0.2) : neonCyan.opacity(0.2), lineWidth: 1)
                .frame(width: 220, height: 320)
                
                // Point cloud data simulating depth mapping
                ZStack {
                    ForEach(0..<dataPoints.count, id: \.self) { i in
                        Circle()
                            .fill(isCalibrated ? Color.green : neonCyan)
                            .frame(width: 3, height: 3)
                            .position(dataPoints[i])
                            .glow(color: isCalibrated ? .green : neonCyan, radius: 2)
                            .opacity(isCalibrated ? 1.0 : Double.random(in: 0.1...0.9))
                    }
                }
                .frame(width: 220, height: 320)
                
                // Active scanning optical sweep
                if !isCalibrated {
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, neonCyan.opacity(0.8), .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(width: 240, height: 3)
                        .shadow(color: neonCyan, radius: 10)
                        .offset(y: scanLineOffset)
                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: true), value: scanLineOffset)
                        .onAppear {
                            scanLineOffset = 160
                        }
                }
                
                // Secure anchor points at corners
                VStack {
                    HStack {
                        CornerTarget(color: isCalibrated ? .green : neonCyan)
                        Spacer()
                        CornerTarget(color: isCalibrated ? .green : neonCyan).rotationEffect(.degrees(90))
                    }
                    Spacer()
                    HStack {
                        CornerTarget(color: isCalibrated ? .green : neonCyan).rotationEffect(.degrees(-90))
                        Spacer()
                        CornerTarget(color: isCalibrated ? .green : neonCyan).rotationEffect(.degrees(180))
                    }
                }
                .frame(width: 240, height: 340)

                // Central precision reticle
                Image(systemName: "plus.viewfinder")
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(isCalibrated ? .green : neonCyan.opacity(0.6))
                    .scaleEffect(isCalibrated ? 1.2 : 1.0)
                    .animation(.spring(), value: isCalibrated)
            }
            // Reactive perspective transformation using calibration axes
            .rotation3DEffect(.degrees(pitch), axis: (x: 1, y: 0, z: 0))
            .rotation3DEffect(.degrees(yaw), axis: (x: 0, y: 1, z: 0))
            .rotation3DEffect(.degrees(roll), axis: (x: 0, y: 0, z: 1))
            .shadow(color: isCalibrated ? Color.green.opacity(0.3) : neonCyan.opacity(0.2), radius: isCalibrated ? 20 : 10)
        }
        .padding(.vertical, 40)
    }
}

struct CornerTarget: View {
    let color: Color
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 15))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 15, y: 0))
        }
        .stroke(color, lineWidth: 2)
        .frame(width: 15, height: 15)
        .shadow(color: color, radius: 2)
    }
}
