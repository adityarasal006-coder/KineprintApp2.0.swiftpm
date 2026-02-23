#if os(iOS)
import SwiftUI

// MARK: - Stabilize Oscillation Game

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
    @State private var accuracy: Double = 0.0
    @State private var thinkingLog: [String] = ["SYSTEM_IDLE: AWAITING_TUNING", "KINETIC_LINK: STANDBY"]
    
    private var naturalFrequency: Double { sqrt(springK / mass) }
    private var criticalDamping: Double { 2.0 * sqrt(springK * mass) }
    private var dampingRatio: Double { damping / criticalDamping }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                GameHeader(
                    title: "HARMONIC_STABILIZATION",
                    icon: "waveform.path",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { withAnimation { showHint.toggle() } }
                )
                
                ZStack {
                    GeometryReader { geo in
                        GridBackground(color: neonCyan, size: geo.size)
                    }
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if showHint {
                                FormulaCard(lines: [
                                    "ζ = b / (2√(km))",
                                    "Critical: ζ = 1"
                                ], note: "Objective: Reach equilibrium (ζ ≥ 1) as fast as possible.")
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // Analysis View
                            HStack(alignment: .top, spacing: 16) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "waveform.path.ecg")
                                            .foregroundColor(neonCyan)
                                        Text("DAMPING_RATIO").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(.gray)
                                    }
                                    
                                    Text(String(format: "ζ = %.3f", dampingRatio))
                                        .font(.system(size: 20, weight: .black, design: .monospaced))
                                        .foregroundColor(dampingRatio >= 1.0 ? neonGreen : .orange)
                                    
                                    Text(dampingRatio < 1.0 ? "UNDERDAMPED" : (dampingRatio > 1.0 ? "OVERDAMPED" : "CRITICAL"))
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(dampingRatio >= 1.0 ? neonGreen : .orange)
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("LIVE_CALCULATION")
                                        .font(.system(size: 8, weight: .black, design: .monospaced))
                                        .foregroundColor(.gray)
                                    
                                    ForEach(thinkingLog, id: \.self) { log in
                                        Text("> \(log)")
                                            .font(.system(size: 7, design: .monospaced))
                                            .foregroundColor(neonCyan.opacity(0.6))
                                    }
                                }
                                .frame(width: 140, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            
                            // Visualization
                            HStack(spacing: 16) {
                                SpringMassView(displacement: currentAmplitude, isSettled: settled, color: neonCyan)
                                    .frame(width: 120)
                                    .cornerRadius(16)
                                
                                VStack(alignment: .leading) {
                                    Text("DECAY_PLOTTING")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                    WaveformView(points: wavePoints, settled: settled, color: neonCyan)
                                        .frame(height: 120)
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            // Controls
                            VStack(spacing: 16) {
                                ScientificSlider(label: "DAMPING_FORCE (b)", value: $damping, range: 0.1...25, unit: "N·s/m", color: .purple)
                                ScientificSlider(label: "SPRING_STIFF (k)", value: $springK, range: 1...30, unit: "N/m", color: neonCyan)
                                ScientificSlider(label: "SYSTEM_MASS (m)", value: $mass, range: 0.5...15, unit: "kg", color: neonGreen)
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(24)
                            .padding(.horizontal, 16)
                            .onChange(of: damping) { _ in resetSimulation() }
                            .onChange(of: springK) { _ in resetSimulation() }
                            .onChange(of: mass) { _ in resetSimulation() }
                            
                            if !showResult {
                                Button(action: isRunning ? stopTimer : startSimulation) {
                                    HStack {
                                        Image(systemName: isRunning ? "stop.fill" : "play.fill")
                                        Text(isRunning ? "RECORDING..." : "INITIALIZE_EQUILIBRIUM")
                                    }
                                    .font(.system(size: 14, weight: .black, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(isRunning ? Color.orange : neonCyan)
                                    .cornerRadius(14)
                                    .shadow(color: (isRunning ? Color.orange : neonCyan).opacity(0.3), radius: 10)
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            if showResult {
                                ResultOverlay(accuracy: accuracy, onNext: nextLevel, onRetry: resetSimulation)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            Spacer().frame(height: 40)
                        }
                        .padding(.top, 20)
                    }
                }
            }
        }
    }
    
    private func startSimulation() {
        wavePoints = []; elapsed = 0; currentAmplitude = 1.0 + Double(level) * 0.3
        isRunning = true; showResult = false; settled = false
        updateLog("ENGAGING_MECHANICAL_LINK")
        let initAmp = currentAmplitude
        let b = damping, k = springK, m = mass
        var newLocalElapsed = 0.0
        
        Task { @MainActor in
            while isRunning {
                try? await Task.sleep(nanoseconds: 40_000_000) // 0.04s
                guard !Task.isCancelled && isRunning else { break }
                
                newLocalElapsed += 0.04
                let t = newLocalElapsed
                let decay = exp(-b * t / (2 * m))
                let omega2 = k / m - (b * b) / (4 * m * m)
                let x: Double = omega2 > 0 ? initAmp * decay * cos(sqrt(omega2) * t) : initAmp * decay
                let newAmplitude = abs(x)
                let didSettle = newAmplitude < settleTolerance && t > 0.5
                
                self.elapsed = t
                self.currentAmplitude = newAmplitude
                self.wavePoints.append(x)
                if self.wavePoints.count > 100 { self.wavePoints.removeFirst() }
                
                if didSettle {
                    self.settled = true
                    self.isRunning = false
                    updateLog("STATUS: SETTLED")
                    let timeAcc = max(0, 1.0 - (t / 10.0))
                    let dampAcc = dampingRatio >= 0.9 && dampingRatio <= 1.1 ? 1.0 : 0.7
                    self.accuracy = (timeAcc + dampAcc) / 2.0
                    
                    self.totalScore += Int(accuracy * 100) * level
                    self.score = totalScore
                    self.streak += 1
                    withAnimation(.spring()) { self.showResult = true }
                } else if t > 10.0 {
                    self.isRunning = false
                    updateLog("STATUS: TIMEOUT")
                    self.accuracy = 0.1
                    self.streak = 0
                    withAnimation(.spring()) { self.showResult = true }
                }
            }
        }
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 4 { thinkingLog.removeFirst() }
        }
    }
    
    private func stopTimer() { isRunning = false }
    private func resetSimulation() {
        stopTimer(); wavePoints = []; elapsed = 0; currentAmplitude = 1.0 + Double(level) * 0.3
        settled = false; showResult = false; updateLog("SIM_RECALIBRATED")
    }
    private func nextLevel() { level = min(level + 1, 10); resetSimulation() }
}

struct SpringMassView: View {
    let displacement: Double
    let isSettled: Bool
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let baseY = 15.0
            let targetY = geo.size.height - 40.0
            let currentY = baseY + (targetY - baseY) * 0.5 + displacement * 40.0
            
            ZStack {
                // Background
                Color.black.opacity(0.4)
                
                // Spring
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: baseY))
                    let loops = 12
                    let step = (currentY - 15 - baseY) / CGFloat(loops)
                    for i in 0..<loops {
                        let y = baseY + 5 + step * CGFloat(i)
                        let offset: CGFloat = i % 2 == 0 ? 15 : -15
                        path.addLine(to: CGPoint(x: centerX + offset, y: y + step/2))
                    }
                    path.addLine(to: CGPoint(x: centerX, y: currentY - 15))
                }
                .stroke(isSettled ? Color.green : color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                
                // Top Plate
                Rectangle().fill(color.opacity(0.6)).frame(width: 40, height: 4).position(x: centerX, y: baseY)
                
                // Mass
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSettled ? Color.green : color)
                    Text("MASS")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                }
                .frame(width: 40, height: 30)
                .position(x: centerX, y: currentY)
                .shadow(color: (isSettled ? Color.green : color).opacity(0.5), radius: 8)
            }
        }
    }
}

struct WaveformView: View {
    let points: [Double]
    let settled: Bool
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let mid = geo.size.height / 2
            let scale = geo.size.height / 3
            
            Path { path in
                path.move(to: CGPoint(x: 0, y: mid))
                path.addLine(to: CGPoint(x: geo.size.width, y: mid))
            }
            .stroke(Color.white.opacity(0.05), lineWidth: 1)
            
            if points.count > 1 {
                Path { path in
                    let step = geo.size.width / CGFloat(max(1, points.count - 1))
                    path.move(to: CGPoint(x: 0, y: mid - CGFloat(points[0]) * scale))
                    for (i, val) in points.enumerated().dropFirst() {
                        path.addLine(to: CGPoint(x: CGFloat(i) * step, y: mid - CGFloat(val) * scale))
                    }
                }
                .stroke(settled ? Color.green : color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                .shadow(color: (settled ? Color.green : color).opacity(0.3), radius: 2)
            }
        }
    }
}
#endif
