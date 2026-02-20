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
                        // Target display
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("TARGET VELOCITY")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text(String(format: "%.1f m/s", targetVelocity))
                                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                                    .foregroundColor(neonCyan)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("CURRENT")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text(String(format: "%.2f m/s", currentVelocity))
                                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                                    .foregroundColor(isRunning ? neonGreen : .white)
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(neonCyan.opacity(0.15), lineWidth: 0.5))
                        
                        // Simulation track
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.04))
                                .frame(height: 60)
                            
                            // Target zone
                            let targetFrac = min(1.0, targetVelocity / 12.0)
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(neonGreen.opacity(0.25))
                                    .frame(width: geo.size.width * 0.08, height: 60)
                                    .offset(x: geo.size.width * targetFrac * 0.85)
                                Text("TARGET")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(neonGreen)
                                    .offset(x: geo.size.width * targetFrac * 0.85, y: -10)
                                
                                // Object
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isRunning ? neonCyan : Color.gray)
                                        .frame(width: 36, height: 40)
                                    Image(systemName: "cube.fill")
                                        .foregroundColor(.black)
                                        .font(.system(size: 16))
                                }
                                .offset(x: geo.size.width * objectX * 0.9 - 18, y: 10)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(neonCyan.opacity(0.2), lineWidth: 0.5))
                        .padding(.vertical, 4)
                        
                        // Sliders
                        VStack(spacing: 16) {
                            PhysicsSlider(label: "FORCE (F)", value: $force, range: 1...30, unit: "N", color: neonCyan)
                            PhysicsSlider(label: "MASS (m)", value: $mass, range: 1...20, unit: "kg", color: Color(red: 0.8, green: 0.5, blue: 1.0))
                            PhysicsSlider(label: "FRICTION (f)", value: $friction, range: 0...15, unit: "N", color: neonRed)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(neonCyan.opacity(0.1), lineWidth: 0.5))
                        
                        // Calculated acceleration display
                        let accel = max(0, (force - friction) / mass)
                        HStack {
                            VStack(alignment: .leading) {
                                Text("CALCULATED ACCELERATION")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text(String(format: "a = (%.0fN − %.0fN) / %.0fkg = %.2f m/s²", force, friction, mass, accel))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(neonCyan)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                        
                        // Launch button
                        if !showResult {
                            Button(action: launchSimulation) {
                                HStack(spacing: 10) {
                                    Image(systemName: isRunning ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 22))
                                    Text(isRunning ? "RUNNING..." : "LAUNCH SIMULATION")
                                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isRunning ? Color.gray : neonCyan)
                                .cornerRadius(14)
                                .shadow(color: isRunning ? .clear : neonCyan.opacity(0.4), radius: 12)
                            }
                            .disabled(isRunning)
                        }
                        
                        // Result
                        if showResult {
                            VelocityResultView(hit: hitTarget, current: currentVelocity, target: targetVelocity, onNext: nextLevel, onRetry: retryLevel)
                        }
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(16)
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
            elapsed += dt
            let newVelocity = accel * elapsed
            let newX = min(0.9, 0.5 * accel * elapsed * elapsed / 12.0)
            let shouldStop = elapsed >= maxTime || newX >= 0.9
            if shouldStop { t.invalidate() }
            DispatchQueue.main.async {
                currentVelocity = newVelocity
                objectX = newX
                if shouldStop {
                    isRunning = false
                    let diff = abs(newVelocity - targetVelocity)
                    hitTarget = diff <= tolerance
                    if hitTarget { totalScore += 100 * level; streak += 1 } else { streak = 0 }
                    score = totalScore
                    showResult = true
                }
            }
        }
    }
    
    private func nextLevel() { level = min(level + 1, 6); retryLevel() }
    private func retryLevel() { showResult = false; objectX = 0; currentVelocity = 0 }
}

// MARK: - Supporting Views

@MainActor
@available(iOS 16.0, *)
struct PhysicsSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text(String(format: "%.1f %@", value, unit))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
            Slider(value: $value, in: range)
                .tint(color)
        }
    }
}

@MainActor
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
            Text(hit ? "TARGET HIT! +\(100)pts" : "WIDE BY \(String(format: "%.2f", abs(current - target))) m/s")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(hit ? .green : .red)
            
            HStack(spacing: 16) {
                Button(action: onRetry) {
                    Label("RETRY", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.gray)
                        .cornerRadius(10)
                }
                Button(action: onNext) {
                    Label("NEXT LEVEL", systemImage: "chevron.right.2")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(neonCyan)
                        .cornerRadius(10)
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
