#if os(iOS)
import SwiftUI

// MARK: - Stabilize Oscillation Game

@MainActor
@available(iOS 16.0, *)
struct OscillationGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonGreen = Color(red: 0.2, green: 1, blue: 0.4)
    private let neonPurple = Color(red: 0.7, green: 0.4, blue: 1.0)
    
    @State private var damping: Double = 0.5    // b: damping coefficient
    @State private var springK: Double = 4.0   // k: spring constant
    @State private var mass: Double = 1.0      // m: mass in kg
    @State private var amplitude: Double = 1.0
    @State private var phase = 0.0
    @State private var timer: Timer?
    @State private var elapsed = 0.0
    @State private var isRunning = false
    @State private var wavePoints: [Double] = []
    @State private var settled = false
    @State private var settleTolerance = 0.05
    @State private var level = 1
    @State private var totalScore = 0
    @State private var showHint = false
    @State private var showResult = false
    @State private var streak = 0
    @State private var currentAmplitude: Double = 1.0
    @State private var thinkingLog: [String] = ["SYSTEM_IDLE", "AWAITING_TUNING"]
    
    private var naturalFrequency: Double { sqrt(springK / mass) }
    private var criticalDamping: Double { 2.0 * sqrt(springK * mass) }
    private var dampingRatio: Double { damping / criticalDamping }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                GameHeader(
                    title: "STABILIZE OSCILLATION",
                    icon: "waveform.path",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { showHint.toggle() }
                )
                
                if showHint {
                    FormulaCard(lines: [
                        "x(t) = A·e^(-bt/2m)·cos(ωt + φ)",
                        "ω = √(k/m − b²/4m²)",
                        "ζ = b / (2√(km))  [damping ratio]",
                        "Critical damping: ζ = 1"
                    ], note: "Set b high enough so ζ ≥ 1 to stop oscillation without overshoot")
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Advanced Dynamic HUD
                ZStack {
                    GeometryReader { geo in
                        GridBackground(color: neonCyan, size: geo.size)
                    }
                    
                    VStack(alignment: .leading, spacing: 14) {
                        // Diagnostic Panel
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("SYSTEM_DIAGNOSTICS", systemImage: "waveform.path")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(neonCyan)
                                
                                DampingRatioHUD(ratio: dampingRatio)
                            }
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .border(neonCyan.opacity(0.3), width: 1)
                            
                            Spacer()
                            
                            // Thinking Log
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("SENSOR_FEED: ACTIVE")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                                
                                ForEach(thinkingLog, id: \.self) { log in
                                    Text("> \(log)")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(neonCyan.opacity(0.7))
                                }
                            }
                            .frame(width: 160, alignment: .trailing)
                        }
                        .padding(.horizontal)
                        
                        // Spring-Mass Stage
                        HStack(spacing: 20) {
                            SpringMassView(
                                displacement: currentAmplitude,
                                isSettled: settled,
                                color: neonCyan
                            )
                            .frame(width: 140)
                            
                            // Real-time Waveform (Scientist Style)
                            VStack(alignment: .leading) {
                                Text("WAVE_DECAY_ANALYSIS")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                WaveformView(points: wavePoints, settled: settled, color: neonCyan)
                                    .frame(height: 120)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Energy Monitor
                        EnergyMonitorView(displacement: currentAmplitude, k: springK, m: mass, v: 0)
                            .padding(.horizontal)
                        
                        // Controls
                        VStack(spacing: 16) {
                            ScientificSlider(label: "DAMPING_FORCE", value: $damping, range: 0.1...25, unit: "N·s/m", color: .purple)
                            ScientificSlider(label: "SPRING_STIFFNESS", value: $springK, range: 1...30, unit: "N/m", color: neonCyan)
                            ScientificSlider(label: "SYSTEM_MASS", value: $mass, range: 0.5...15, unit: "kg", color: neonGreen)
                        }
                        .padding(18)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(18)
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(neonCyan.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal)
                        .onChange(of: damping) { _ in resetSimulation() }
                        .onChange(of: springK) { _ in resetSimulation() }
                        .onChange(of: mass) { _ in resetSimulation() }
                        
                        // Action
                        if !showResult {
                            Button(action: isRunning ? stopTimer : startSimulation) {
                                Text(isRunning ? "RECORDING_DATA..." : "STABILIZE_HARMONIC_SYSTEM")
                                    .font(.system(size: 14, weight: .black, design: .monospaced))
                                    .foregroundColor(.black)
                                    .padding(.vertical, 18)
                                    .frame(maxWidth: .infinity)
                                    .background(isRunning ? Color.orange : neonCyan)
                                    .cornerRadius(12)
                                    .shadow(color: (isRunning ? Color.orange : neonCyan).opacity(0.3), radius: 10)
                            }
                            .padding(.horizontal)
                        }
                        
                        if showResult {
                            OscillationResultView(settled: settled, dampingRatio: dampingRatio, onRetry: resetAll, onNext: nextLevel)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showHint)
        .animation(.easeInOut(duration: 0.3), value: showResult)
        .onDisappear { stopTimer() }
    }
    
    private func startSimulation() {
        wavePoints = []; elapsed = 0; currentAmplitude = 1.0 + Double(level) * 0.3
        isRunning = true; showResult = false; settled = false
        updateLog("ENGAGING_SPRINT_LINK...")
        let initAmp = currentAmplitude
        let b = damping, k = springK, m = mass
        var newLocalElapsed = 0.0
        let settleTol = settleTolerance
        timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
            Task { @MainActor in
                newLocalElapsed += 0.04
                let t = newLocalElapsed
                let decay = exp(-b * t / (2 * m))
                let omega2 = k / m - (b * b) / (4 * m * m)
                let x: Double = omega2 > 0 ? initAmp * decay * cos(sqrt(omega2) * t) : initAmp * decay
                let newAmplitude = abs(x)
                let didSettle = newAmplitude < settleTol && t > 0.5
                let didTimeout = t > 12.0
                
                self.elapsed = t
                self.currentAmplitude = newAmplitude
                self.wavePoints.append(x)
                if self.wavePoints.count > 150 { self.wavePoints.removeFirst() }
                if didSettle {
                    self.settled = true
                    self.stopTimer()
                    self.updateLog("STABILITY_DETECTED: SUCCESS")
                    let pts = max(10, Int((1.0 - self.elapsed / 10.0) * 100)) * self.level
                    self.totalScore += pts
                    self.score = self.totalScore; self.streak += 1; self.showResult = true
                } else if didTimeout {
                    self.stopTimer()
                    self.updateLog("COMPUTE_TIMEOUT: FAILURE")
                    self.settled = false; self.streak = 0; self.showResult = true
                }
            }
        }
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 3 { thinkingLog.removeFirst() }
        }
    }
    
    private func stopTimer() { timer?.invalidate(); isRunning = false }
    private func resetSimulation() {
        stopTimer(); wavePoints = []; elapsed = 0; currentAmplitude = 1.0 + Double(level) * 0.3
        settled = false; showResult = false
    }
    private func resetAll() { level = max(1, level); resetSimulation() }
    private func nextLevel() { level = min(level + 1, 5); resetSimulation(); updateLog("RECONFIGURING_LEVEL_\(level)") }
}

// MARK: - Supporting Views

@available(iOS 16.0, *)
struct DampingRatioHUD: View {
    let ratio: Double
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("RATIO_ZETA: \(String(format: "%.3f", ratio))")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(neonCyan)
            Text(ratio < 1.0 ? "STATUS: UNDERDAMPED" : (ratio == 1.0 ? "STATUS: CRITICAL" : "STATUS: OVERDAMPED"))
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(ratio < 1.0 ? .orange : .green)
        }
    }
}

@available(iOS 16.0, *)
struct EnergyMonitorView: View {
    let displacement: Double
    let k: Double
    let m: Double
    let v: Double
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        let potential = 0.5 * k * displacement * displacement
        VStack(alignment: .leading, spacing: 4) {
            Text("ENERGY_DYNAMICS (Joules)")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(neonCyan)
                        .frame(width: geo.size.width * min(1.0, potential / 20.0))
                }
            }
            .frame(height: 6)
        }
    }
}

@available(iOS 16.0, *)
struct SpringMassView: View {
    let displacement: Double
    let isSettled: Bool
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let baseY = 10.0
            let massY = baseY + 60.0 + displacement * 40.0
            
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: baseY))
                    for i in 0..<10 {
                        let y = baseY + (massY - baseY - 20) / 10.0 * Double(i + 1)
                        let xOffset: Double = (i % 2 == 0) ? 12 : -12
                        path.addLine(to: CGPoint(x: centerX + xOffset, y: y))
                    }
                    path.addLine(to: CGPoint(x: centerX, y: massY - 20))
                }
                .stroke(isSettled ? Color.green : color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                
                Rectangle().fill(color.opacity(0.4)).frame(width: 60, height: 2).position(x: centerX, y: baseY)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSettled ? Color.green : color)
                    .frame(width: 32, height: 24)
                    .position(x: centerX, y: massY)
                    .shadow(color: (isSettled ? Color.green : color).opacity(0.5), radius: 6)
            }
        }
        .frame(height: 140)
        .background(Color.black.opacity(0.3))
        .border(Color.white.opacity(0.1))
    }
}

@available(iOS 16.0, *)
struct WaveformView: View {
    let points: [Double]
    let settled: Bool
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let mid = h / 2, scale = h / 3.0
            
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: mid))
                    p.addLine(to: CGPoint(x: w, y: mid))
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                
                if points.count > 1 {
                    Path { path in
                        let step = w / Double(max(points.count - 1, 1))
                        path.move(to: CGPoint(x: 0, y: mid - points[0] * scale))
                        for (i, val) in points.enumerated().dropFirst() {
                            path.addLine(to: CGPoint(x: Double(i) * step, y: mid - val * scale))
                        }
                    }
                    .stroke(settled ? Color.green : color, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct OscillationResultView: View {
    let settled: Bool
    let dampingRatio: Double
    let onRetry: () -> Void
    let onNext: () -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            Text(settled ? "SYSTEM_STABLE" : "UNSTABLE_EQUILIBRIUM")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(settled ? .green : .orange)
            
            HStack(spacing: 16) {
                Button(action: onRetry) {
                    Text("RE-TUNE").font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white).padding(10).background(Color.white.opacity(0.1)).cornerRadius(6)
                }
                Button(action: onNext) {
                    Text("CONTINUE").font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black).padding(10).background(neonCyan).cornerRadius(6)
                }
            }
        }
        .padding(16).background(Color.black.opacity(0.8)).overlay(RoundedRectangle(cornerRadius: 12).stroke(neonCyan.opacity(0.3), lineWidth: 1))
    }
}
#endif
