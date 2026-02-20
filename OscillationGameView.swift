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
    
    private var naturalFrequency: Double { sqrt(springK / mass) }
    private var criticalDamping: Double { 2.0 * sqrt(springK * mass) }
    private var dampingRatio: Double { damping / criticalDamping }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Damping ratio display
                        HStack {
                            DampingRatioView(ratio: dampingRatio)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("AMPLITUDE")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text(String(format: "%.3f", currentAmplitude))
                                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                                    .foregroundColor(currentAmplitude < settleTolerance ? neonGreen : neonCyan)
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(neonCyan.opacity(0.15), lineWidth: 0.5))
                        
                        // Spring-mass visualization
                        SpringMassView(
                            displacement: currentAmplitude,
                            isSettled: settled,
                            color: neonCyan
                        )
                        
                        // Waveform
                        WaveformView(points: wavePoints, settled: settled, color: neonCyan)
                            .frame(height: 90)
                        
                        // Controls
                        VStack(spacing: 14) {
                            PhysicsSlider(label: "DAMPING COEFF (b)", value: $damping, range: 0.01...20, unit: "N·s/m", color: neonPurple)
                            PhysicsSlider(label: "SPRING CONSTANT (k)", value: $springK, range: 0.5...20, unit: "N/m", color: neonCyan)
                            PhysicsSlider(label: "MASS (m)", value: $mass, range: 0.5...10, unit: "kg", color: neonGreen)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(neonCyan.opacity(0.1), lineWidth: 0.5))
                        .onChange(of: damping) { _ in resetSimulation() }
                        .onChange(of: springK) { _ in resetSimulation() }
                        .onChange(of: mass) { _ in resetSimulation() }
                        
                        // Start button
                        if !showResult {
                            Button(action: isRunning ? stopTimer : startSimulation) {
                                HStack(spacing: 10) {
                                    Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 22))
                                    Text(isRunning ? "STOP" : "START SIMULATION")
                                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isRunning ? Color.orange : neonCyan)
                                .cornerRadius(14)
                                .shadow(color: neonCyan.opacity(0.3), radius: 10)
                            }
                        }
                        
                        if showResult {
                            OscillationResultView(settled: settled, dampingRatio: dampingRatio, onRetry: resetAll, onNext: nextLevel)
                        }
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(16)
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
        let initAmp = currentAmplitude
        let b = damping, k = springK, m = mass
        var newLocalElapsed = 0.0
        let settleTol = settleTolerance
        timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
            newLocalElapsed += 0.04
            let t = newLocalElapsed
            let decay = exp(-b * t / (2 * m))
            let omega2 = k / m - (b * b) / (4 * m * m)
            let x: Double = omega2 > 0 ? initAmp * decay * cos(sqrt(omega2) * t) : initAmp * decay
            let newAmplitude = abs(x)
            let didSettle = newAmplitude < settleTol && t > 0.5
            let didTimeout = t > 12.0
            DispatchQueue.main.async {
                elapsed = t
                currentAmplitude = newAmplitude
                wavePoints.append(x)
                if wavePoints.count > 150 { wavePoints.removeFirst() }
                if didSettle {
                    settled = true
                    stopTimer()
                    let pts = max(10, Int((1.0 - elapsed / 10.0) * 100)) * level
                    totalScore += pts
                    score = totalScore
                    streak += 1
                    showResult = true
                } else if didTimeout {
                    stopTimer()
                    settled = false; streak = 0
                    showResult = true
                }
            }
        }
    }
    
    private func stopTimer() { timer?.invalidate(); isRunning = false }
    
    private func resetSimulation() {
        stopTimer(); wavePoints = []; elapsed = 0; currentAmplitude = 1.0 + Double(level) * 0.3
        settled = false; showResult = false
    }
    
    private func resetAll() { level = max(1, level); resetSimulation() }
    private func nextLevel() { level = min(level + 1, 5); resetSimulation() }
}

// MARK: - Supporting Views

@MainActor
@available(iOS 16.0, *)
struct DampingRatioView: View {
    let ratio: Double
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var statusText: String {
        if ratio < 1.0 { return "UNDER-DAMPED" }
        else if ratio == 1.0 { return "CRITICAL" }
        else { return "OVER-DAMPED" }
    }
    var statusColor: Color {
        if ratio < 0.5 { return .red }
        else if ratio < 1.0 { return .orange }
        else { return .green }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DAMPING RATIO (ζ)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(String(format: "ζ = %.3f", ratio))
                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                .foregroundColor(neonCyan)
            Text(statusText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(statusColor)
        }
    }
}

@MainActor
@available(iOS 16.0, *)
struct SpringMassView: View {
    let displacement: Double
    let isSettled: Bool
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let baseY = 20.0
            let massY = baseY + 50.0 + displacement * 30.0
            
            ZStack {
                // Spring zigzag
                Path { path in
                    path.move(to: CGPoint(x: centerX, y: baseY))
                    let segments = 8
                    for i in 0..<segments {
                        let y = baseY + (massY - baseY - 20) / Double(segments) * Double(i + 1)
                        let xOffset: Double = (i % 2 == 0) ? 15 : -15
                        path.addLine(to: CGPoint(x: centerX + xOffset, y: y))
                    }
                    path.addLine(to: CGPoint(x: centerX, y: massY - 20))
                }
                .stroke(isSettled ? Color.green : color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                
                // Fixed ceiling
                Rectangle()
                    .fill(color.opacity(0.4))
                    .frame(width: 80, height: 4)
                    .position(x: centerX, y: baseY)
                
                // Mass block
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSettled ? Color.green : color)
                    .frame(width: 40, height: 30)
                    .position(x: centerX, y: massY)
                    .shadow(color: (isSettled ? Color.green : color).opacity(0.5), radius: 8)
                
                // Equilibrium line
                Path { p in
                    p.move(to: CGPoint(x: centerX - 60, y: baseY + 80))
                    p.addLine(to: CGPoint(x: centerX + 60, y: baseY + 80))
                }
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .frame(height: 140)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}

@MainActor
@available(iOS 16.0, *)
struct WaveformView: View {
    let points: [Double]
    let settled: Bool
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let mid = h / 2
            let scale = h / 3.5
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.03))
                
                // Zero line
                Path { p in
                    p.move(to: CGPoint(x: 0, y: mid))
                    p.addLine(to: CGPoint(x: w, y: mid))
                }
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                
                // Waveform
                if points.count > 1 {
                    Path { path in
                        let step = w / Double(max(points.count - 1, 1))
                        path.move(to: CGPoint(x: 0, y: mid - points[0] * scale))
                        for (i, val) in points.enumerated().dropFirst() {
                            path.addLine(to: CGPoint(x: Double(i) * step, y: mid - val * scale))
                        }
                    }
                    .stroke(settled ? Color.green : color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                }
            }
        }
    }
}

@MainActor
@available(iOS 16.0, *)
struct OscillationResultView: View {
    let settled: Bool
    let dampingRatio: Double
    let onRetry: () -> Void
    let onNext: () -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: settled ? "checkmark.seal.fill" : "exclamationmark.octagon.fill")
                .font(.system(size: 40))
                .foregroundColor(settled ? .green : .orange)
            Text(settled ? "SYSTEM STABILIZED! 🎉" : "STILL OSCILLATING")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(settled ? .green : .orange)
            Text(String(format: "Damping ratio ζ = %.3f", dampingRatio))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)
            HStack(spacing: 16) {
                Button(action: onRetry) {
                    Label("RETRY", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.gray).cornerRadius(10)
                }
                Button(action: onNext) {
                    Label("NEXT LEVEL", systemImage: "chevron.right.2")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(neonCyan).cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(neonCyan.opacity(0.15), lineWidth: 0.5))
    }
}
#endif
