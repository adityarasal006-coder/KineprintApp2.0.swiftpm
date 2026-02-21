#if os(iOS)
import SwiftUI

// MARK: - Optimize Velocity Game

@MainActor
@available(iOS 16.0, *)
struct VelocityGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonGreen = Color(red: 0.2, green: 1, blue: 0.4)
    private let neonRed = Color(red: 1, green: 0.3, blue: 0.3)
    
    @State private var force: Double = 10.0         // N
    @State private var mass: Double = 5.0           // kg
    @State private var friction: Double = 2.0       // N
    @State private var isRunning = false
    @State private var objectX: Double = 0.0
    @State private var currentVelocity: Double = 0.0
    @State private var showResult = false
    @State private var hitTarget = false
    @State private var level = 1
    @State private var totalScore = 0
    @State private var showHint = false
    @State private var streak = 0
    @State private var timer: Timer?
    
    // Level-based target velocity
    private var targetVelocity: Double { 3.0 + Double(level) * 1.5 }
    private var tolerance: Double { 0.4 }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                GameHeader(
                    title: "OPTIMIZE VELOCITY",
                    icon: "speedometer",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { showHint.toggle() }
                )
                
                if showHint {
                    FormulaCard(lines: [
                        "a = (F − f) / m",
                        "v = u + a·t",
                        "Fnet = F − friction"
                    ], note: "Adjust Force, Mass, Friction to reach the TARGET velocity")
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Advanced Scientific HUD Area
                        ZStack {
                            // Grid background
                            GeometryReader { geo in
                                GridBackground(color: neonCyan, size: geo.size)
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                // Prediction Panel
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Label("SIMULATION_PARAMS", systemImage: "terminal")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(neonCyan)
                                        
                                        Text(String(format: "TARGET_V: %.2f m/s", targetVelocity))
                                            .font(.system(size: 14, weight: .black, design: .monospaced))
                                            .foregroundColor(neonCyan)
                                        
                                        Text("ENVIRONMENT: VACUUM_DEFAULT")
                                            .font(.system(size: 7, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(12)
                                    .background(Color.black.opacity(0.6))
                                    .border(neonCyan.opacity(0.3), width: 1)
                                    
                                    Spacer()
                                    
                                    // Real-time calculation readout
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("COMPUTED_ACCEL")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(.gray)
                                        Text(String(format: "%.3f m/s²", max(0, (force - friction) / mass)))
                                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                                            .foregroundColor(neonGreen)
                                        Text("F_NET = F - f")
                                            .font(.system(size: 7, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Simulation Track (Scientist Style)
                                ZStack(alignment: .leading) {
                                    // Track markers
                                    HStack(spacing: 0) {
                                        ForEach(0..<13) { i in
                                            VStack {
                                                Rectangle().fill(neonCyan.opacity(0.2)).frame(width: 1, height: 10)
                                                Text("\(i)m").font(.system(size: 6, design: .monospaced)).foregroundColor(.gray)
                                            }
                                            if i < 12 { Spacer() }
                                        }
                                    }
                                    .padding(.horizontal, 18)
                                    
                                    // Target zone highlighting
                                    let targetFrac = min(1.0, targetVelocity / 15.0)
                                    GeometryReader { geo in
                                        let targetX = geo.size.width * targetFrac * 0.85
                                        
                                        // Glowing target line
                                        Rectangle()
                                            .fill(neonGreen.opacity(0.4))
                                            .frame(width: 4, height: 40)
                                            .blur(radius: 2)
                                            .position(x: targetX, y: 20)
                                        
                                        // Object with Vectors
                                        VStack(spacing: 0) {
                                            // Force Vector Arrow
                                            if !isRunning {
                                                HStack(spacing: 0) {
                                                    Spacer().frame(width: 20)
                                                    Image(systemName: "arrow.right")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(neonCyan)
                                                        .scaleEffect(x: CGFloat(force / 10.0), y: 1.0, anchor: .leading)
                                                    Text("F")
                                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                        .foregroundColor(neonCyan)
                                                }
                                                .frame(width: 40, alignment: .leading)
                                            }
                                            
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(isRunning ? neonCyan : Color.gray)
                                                    .frame(width: 30, height: 30)
                                                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.5), lineWidth: 0.5))
                                                
                                                Text("\(Int(mass))kg")
                                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.black)
                                            }
                                            
                                            // Velocity Label during run
                                            if isRunning {
                                                Text("\(String(format: "%.1f", currentVelocity))")
                                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                    .foregroundColor(neonCyan)
                                                    .padding(.top, 2)
                                            }
                                        }
                                        .position(x: geo.size.width * objectX * 0.9 + 15, y: 20)
                                    }
                                }
                                .frame(height: 70)
                                
                                // Parameter Control blackboard
                                VStack(spacing: 20) {
                                    ScientificSlider(label: "INPUT_FORCE", value: $force, range: 1...40, unit: "N", color: neonCyan)
                                    ScientificSlider(label: "OBJECT_MASS", value: $mass, range: 1...25, unit: "kg", color: .purple)
                                    ScientificSlider(label: "FRICTION_COEFF", value: $friction, range: 0...15, unit: "N", color: .red)
                                }
                                .padding(20)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(neonCyan.opacity(0.1), lineWidth: 1))
                                .padding(.horizontal)
                                
                                // Action Button
                                if !showResult {
                                    Button(action: launchSimulation) {
                                        Text(isRunning ? "PROCESSING_SIMULATION..." : "EXECUTE_KINETIC_LINK")
                                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                            .foregroundColor(.black)
                                            .padding(.vertical, 18)
                                            .frame(maxWidth: .infinity)
                                            .background(isRunning ? Color.gray : neonCyan)
                                            .cornerRadius(12)
                                            .shadow(color: neonCyan.opacity(0.4), radius: 10)
                                    }
                                    .padding(.horizontal)
                                    .disabled(isRunning)
                                }
                                
                                // Result Card
                                if showResult {
                                    VelocityResultView(hit: hitTarget, current: currentVelocity, target: targetVelocity, onNext: nextLevel, onRetry: retryLevel)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                        .padding(.horizontal)
                                }
                                
                                Spacer().frame(height: 20)
                            }
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showHint)
        .animation(.easeInOut(duration: 0.3), value: showResult)
        .onDisappear { timer?.invalidate() }
    }
    
    private func launchSimulation() {
        objectX = 0; currentVelocity = 0; isRunning = true; showResult = false
        let accel = max(0.0, (force - friction) / mass)
        let dt = 0.05
        var elapsed = 0.0
        let maxTime = 3.0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: dt, repeats: true) { t in
            Task { @MainActor in
                elapsed += dt
                let newVelocity = accel * elapsed
                let newX = min(0.9, 0.5 * accel * elapsed * elapsed / 12.0)
                let shouldStop = elapsed >= maxTime || newX >= 0.9
                if shouldStop { t.invalidate() }
                
                self.currentVelocity = newVelocity
                self.objectX = newX
                if shouldStop {
                    self.isRunning = false
                    let diff = abs(newVelocity - self.targetVelocity)
                    self.hitTarget = diff <= self.tolerance
                    if self.hitTarget { self.totalScore += 100 * self.level; self.streak += 1 } else { self.streak = 0 }
                    self.score = self.totalScore
                    self.showResult = true
                }
            }
        }
    }
    
    private func nextLevel() { level = min(level + 1, 6); retryLevel() }
    private func retryLevel() { showResult = false; objectX = 0; currentVelocity = 0 }
}

// MARK: - Supporting Views

@available(iOS 16.0, *)
struct VelocityResultView: View {
    let hit: Bool
    let current: Double
    let target: Double
    let onNext: () -> Void
    let onRetry: () -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: hit ? "checkmark.seal.fill" : "xmark.octagon.fill")
                .font(.system(size: 40))
                .foregroundColor(hit ? .green : .red)
            Text(hit ? "TARGET_ACHIEVED" : "COMPUTATION_MISMATCH")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(hit ? .green : .red)
            
            Text(hit ? "+\(100) UNITS RECORDED" : "DELTA: \(String(format: "%.2f", abs(current - target))) m/s")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
            
            HStack(spacing: 16) {
                Button(action: onRetry) {
                    Label("RECALIBRATE", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                Button(action: onNext) {
                    Label("NEXT_EXP", systemImage: "chevron.right.2")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(neonCyan)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(neonCyan.opacity(0.3), lineWidth: 1))
    }
}
#endif
