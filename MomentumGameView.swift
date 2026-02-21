#if os(iOS)
import SwiftUI

// MARK: - Momentum Transfer Game
// Concept: p = m * v. Transfer momentum to a target object to hit a precise mark.

@available(iOS 16.0, *)
@MainActor
struct MomentumGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonGreen = Color(red: 0.2, green: 1, blue: 0.4)
    private let neonYellow = Color(red: 1, green: 0.9, blue: 0.2)
    
    @State private var strikerMass: Double = 2.0
    @State private var strikerVelocity: Double = 5.0
    @State private var targetMass: Double = 5.0
    @State private var strikerPos: CGFloat = 50
    @State private var targetPos: CGFloat = 200
    @State private var isSimulating = false
    @State private var showResult = false
    @State private var accuracy: Double = 0.0
    @State private var level = 1
    @State private var showHint = false
    @State private var streak = 0
    @State private var totalScore = 0
    @State private var thinkingLog: [String] = ["CORE_INIT: MOMENTUM_LAB", "AWAITING_VECTOR_INPUT"]
    @State private var timer: Timer?
    @State private var finalPos: CGFloat = 0
    
    // Level target zone (x coordinate and width)
    private var targetZone: (x: CGFloat, width: CGFloat) {
        let x = 250 + CGFloat(level) * 20
        return (x, 60.0 - CGFloat(level) * 5)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                GameHeader(
                    title: "MOMENTUM_COLLIDER",
                    icon: "arrow.right.to.line.compact",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { showHint.toggle() }
                )
                
                GeometryReader { geo in
                    ZStack {
                        GridBackground(color: neonCyan, size: geo.size)
                        
                        VStack(spacing: 0) {
                            // Telemetry HUD
                            ScientificTelemetryHUD(
                                p: strikerMass * strikerVelocity,
                                m: strikerMass,
                                v: strikerVelocity,
                                logs: thinkingLog
                            )
                            .padding(16)
                            
                            if showHint {
                                FormulaCard(
                                    lines: ["p = m × v", "m₁v₁ + m₂v₂ = m₁v₁' + m₂v₂'"],
                                    note: "Momentum is a vector quantity. In a collision, total momentum is conserved."
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            Spacer()
                            
                            // Simulation Track
                            ZStack(alignment: .leading) {
                                // Track Line
                                Rectangle()
                                    .fill(neonCyan.opacity(0.1))
                                    .frame(height: 2)
                                    .offset(y: 40)
                                
                                // Target Zone
                                Rectangle()
                                    .fill(neonGreen.opacity(0.2))
                                    .frame(width: targetZone.width, height: 80)
                                    .overlay(
                                        Rectangle().stroke(neonGreen, lineWidth: 1)
                                    )
                                    .offset(x: targetZone.x, y: 0)
                                
                                // Target Object
                                MomentumObject(color: neonGreen, mass: targetMass, label: "OBJ_B")
                                    .offset(x: targetPos, y: 0)
                                
                                // Striker Object
                                MomentumObject(color: neonCyan, mass: strikerMass, label: "OBJ_A")
                                    .offset(x: strikerPos, y: 0)
                                    .overlay(
                                        // Velocity Vector Arrow
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(neonCyan)
                                            .offset(x: 40 + CGFloat(strikerVelocity * 5))
                                            .opacity(isSimulating ? 0 : 1)
                                    )
                            }
                            .frame(height: 120)
                            .padding(.horizontal, 20)
                            
                            Spacer()
                            
                            // Control Panel
                            VStack(spacing: 20) {
                                HStack(spacing: 20) {
                                    ScientificSlider(label: "MASS_A", value: $strikerMass, range: 1...10, unit: "kg", color: neonCyan)
                                    ScientificSlider(label: "VELOCITY_A", value: $strikerVelocity, range: 1...20, unit: "m/s", color: neonCyan)
                                }
                                
                                Button(action: launchStriker) {
                                    Text(isSimulating ? "COMPUTING..." : "INITIATE TRANSFER")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(isSimulating ? Color.gray : neonCyan)
                                        .cornerRadius(12)
                                        .shadow(color: neonCyan.opacity(0.3), radius: 10)
                                }
                                .disabled(isSimulating)
                            }
                            .padding(20)
                            .background(Color.black.opacity(0.6))
                            .overlay(Rectangle().frame(height: 1).foregroundColor(neonCyan.opacity(0.2)), alignment: .top)
                        }
                        
                        if showResult {
                            ResultOverlay(
                                accuracy: accuracy,
                                onNext: nextLevel,
                                onRetry: resetSim
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func launchStriker() {
        isSimulating = true
        updateLog("LAUNCH_INITIATED: p=\(String(format: "%.1f", strikerMass * strikerVelocity))")
        
        var currentV_A = strikerVelocity
        var v_B: Double = 0
        let dt = 0.05
        
        timer = Timer.scheduledTimer(withTimeInterval: dt, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.linear(duration: dt)) {
                    if self.strikerPos + 40 < self.targetPos {
                        self.strikerPos += CGFloat(currentV_A * 2.0)
                    } else if v_B == 0 {
                        // Collision Physics (Inelastic for simplicity of the game goal)
                        // Let's assume some momentum transfer
                        let totalP = self.strikerMass * currentV_A
                        v_B = totalP / (self.strikerMass + self.targetMass) // Conserving momentum
                        currentV_A = v_B // They move together in this "transfer" model
                        self.updateLog("COLLISION_DETECTED: TRANSFER_COMPLETE")
                    } else {
                        self.targetPos += CGFloat(v_B * 2.0)
                        self.strikerPos = self.targetPos - 40
                        
                        // Friction/Air resistance slowing them down
                        v_B *= 0.98
                        if v_B < 0.2 {
                            self.timer?.invalidate()
                            self.calculateAccuracy()
                        }
                    }
                }
            }
        }
    }
    
    private func calculateAccuracy() {
        let finalCenter = targetPos + 20
        let targetCenter = targetZone.x + targetZone.width / 2
        let distance = abs(finalCenter - targetCenter)
        
        accuracy = max(0, min(1.0, 1.0 - Double(distance / 100.0)))
        
        let pts = Int(accuracy * 100) * level
        totalScore += pts
        score = totalScore
        
        if accuracy > 0.8 {
            streak += 1
            updateLog("SUCCESS: OPTIMAL_TRANSFER")
        } else {
            streak = 0
            updateLog("FAILURE: SUBOPTIMAL_MOMENTUM")
        }
        
        showResult = true
        isSimulating = false
    }
    
    private func nextLevel() {
        level = min(level + 1, 5)
        resetSim()
    }
    
    private func resetSim() {
        strikerPos = 50
        targetPos = 200
        isSimulating = false
        showResult = false
        accuracy = 0
        updateLog("SYSTEM_RESET: AWAITING_INPUT")
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 4 { thinkingLog.removeFirst() }
        }
    }
}

@available(iOS 16.0, *)
struct MomentumObject: View {
    let color: Color
    let mass: Double
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 2)
                    .frame(width: 40, height: 40)
                
                Text("\(Int(mass))kg")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(color.opacity(0.6))
        }
    }
}

@available(iOS 16.0, *)
struct ScientificTelemetryHUD: View {
    let p: Double
    let m: Double
    let v: Double
    let logs: [String]
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DYNAMICS_STREAM")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
                
                HUDDataRow(label: "MOMENTUM", value: String(format: "%.2f kg·m/s", p))
                HUDDataRow(label: "MASS_A", value: String(format: "%.1f kg", m))
                HUDDataRow(label: "VEL_A", value: String(format: "%.1f m/s", v))
            }
            .padding(10)
            .background(Color.black.opacity(0.4))
            .border(neonCyan.opacity(0.3), width: 1)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                ForEach(logs, id: \.self) { log in
                    Text("> \(log)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(neonCyan.opacity(0.7))
                }
            }
            .frame(width: 150, alignment: .trailing)
        }
    }
}

#endif
