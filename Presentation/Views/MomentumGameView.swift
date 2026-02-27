#if os(iOS)
import SwiftUI

// MARK: - Momentum Transfer Game
// Concept: p = m * v. Transfer momentum to a target object to hit a precise mark.

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
    @State private var finalPos: CGFloat = 0
    @State private var canvasWidth: CGFloat = 300
    @State private var showCalcOverlay = true
    @State private var showBadgeOverlay = false
    
    // Level target zone (x coordinate and width)
    private var targetZone: (x: CGFloat, width: CGFloat) {
        let x = 200 + CGFloat(level) * 15
        return (x, max(40, 70.0 - CGFloat(level) * 5))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                GameHeader(
                    title: "MOMENTUM_TRANSFER",
                    icon: "arrow.right.to.line.compact",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { withAnimation { showHint.toggle() } }
                )
                
                ZStack {
                    GeometryReader { geo in
                        GridBackground(color: neonCyan, size: geo.size)
                            .onAppear { canvasWidth = geo.size.width }
                    }
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if showHint {
                                FormulaCard(
                                    lines: [
                                        "p = m × v",
                                        "m₁v₁ + m₂v₂ = m₁v₁' + m₂v₂'"
                                    ],
                                    note: "Momentum is conserved. Transfer momentum to move OBJ_B into the target zone."
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // Telemetry HUD
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "slider.horizontal.3")
                                            .foregroundColor(neonCyan)
                                        Text("DYNAMICS_STREAM").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        HUDDataRow(label: "MOMENTUM (p)", value: String(format: "%.1f kg·m/s", strikerMass * strikerVelocity))
                                        HUDDataRow(label: "MASS_A", value: String(format: "%.1f kg", strikerMass))
                                        HUDDataRow(label: "VEL_A", value: String(format: "%.1f m/s", strikerVelocity))
                                    }
                                    .padding(10)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(neonCyan.opacity(0.2), lineWidth: 1))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("COLLISION_MONITOR")
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonGreen)
                                    ForEach(thinkingLog, id: \.self) { log in
                                        Text("> \(log)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(neonCyan.opacity(0.7))
                                    }
                                }
                                .frame(width: 140, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            
                            // Simulation Track
                            ZStack(alignment: .leading) {
                                // Track Base
                                Rectangle()
                                    .fill(LinearGradient(colors: [.clear, neonCyan.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                                    .frame(height: 2)
                                    .offset(y: 35)
                                
                                // Target Zone
                                Rectangle()
                                    .fill(neonGreen.opacity(0.15))
                                    .frame(width: targetZone.width, height: 70)
                                    .overlay(Rectangle().stroke(neonGreen.opacity(0.5), lineWidth: 1))
                                    .overlay(
                                        Text("ACCEPTABLE_RANGE")
                                            .font(.system(size: 6, weight: .bold, design: .monospaced))
                                            .foregroundColor(neonGreen)
                                            .offset(y: 45)
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
                                        HStack(spacing: 0) {
                                            Rectangle().fill(neonCyan).frame(width: CGFloat(strikerVelocity * 3), height: 2)
                                            Image(systemName: "play.fill").font(.system(size: 8)).foregroundColor(neonCyan).offset(x: -2)
                                        }
                                        .offset(x: 20 + CGFloat(strikerVelocity * 1.5), y: 0)
                                        .opacity(isSimulating || strikerVelocity == 0 ? 0 : 1)
                                    )
                            }
                            .frame(height: 120)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            
                            // Control Panel
                            VStack(spacing: 20) {
                                ScientificSlider(label: "STRIKER_MASS (kg)", value: $strikerMass, range: 1...10, unit: "kg", color: .purple)
                                ScientificSlider(label: "STRIKER_VELOCITY (m/s)", value: $strikerVelocity, range: 1...20, unit: "m/s", color: neonCyan)
                                
                                if !showResult {
                                    Button(action: launchStriker) {
                                        HStack {
                                            Image(systemName: isSimulating ? "network" : "bolt.fill")
                                            Text(isSimulating ? "COMPUTING_TRANSFER..." : "INITIATE_COLLISION")
                                        }
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .background(isSimulating ? Color.gray : neonCyan)
                                        .cornerRadius(14)
                                        .shadow(color: isSimulating ? .clear : neonCyan.opacity(0.3), radius: 10)
                                    }
                                    .disabled(isSimulating)
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(24)
                            .padding(.horizontal, 16)
                            
                            if showResult {
                                ResultOverlay(accuracy: accuracy, onNext: nextLevel, onRetry: resetSim)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .padding(.horizontal, 16)
                            }
                            
                            // Step Calculation Box
                            GameCalcOverlay(
                                title: "MOMENTUM_CALC",
                                steps: momentumCalcSteps,
                                isVisible: $showCalcOverlay
                            )
                            .padding(.horizontal, 16)
                            
                            Spacer().frame(height: 40)
                        }
                        .padding(.top, 20)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showBadgeOverlay) {
            BadgeEarnedOverlay(badgeName: "Momentum Master") {
                showBadgeOverlay = false
                level = 1
                targetMass = Double.random(in: 2.0...8.0)
                resetSim()
            }
        }
    }
    
    private var momentumCalcSteps: [(label: String, value: String)] {
        let pA = strikerMass * strikerVelocity
        let vB_after = (2 * strikerMass * strikerVelocity) / (strikerMass + targetMass)
        let vA_after = ((strikerMass - targetMass) / (strikerMass + targetMass)) * strikerVelocity
        return [
            (label: "p_A = m_A × v_A", value: "\(String(format: "%.1f", strikerMass)) × \(String(format: "%.1f", strikerVelocity)) = \(String(format: "%.1f", pA)) kg·m/s"),
            (label: "p_B = m_B × 0", value: "0 kg·m/s"),
            (label: "p_total", value: "\(String(format: "%.1f", pA)) kg·m/s"),
            (label: "v_B' (elastic)", value: "\(String(format: "%.2f", vB_after)) m/s"),
            (label: "v_A' (elastic)", value: "\(String(format: "%.2f", vA_after)) m/s"),
            (label: "p_conservation", value: "\(String(format: "%.1f", strikerMass * vA_after + targetMass * vB_after)) kg·m/s ✓"),
        ]
    }
    
    private func launchStriker() {
        isSimulating = true
        showResult = false
        updateLog("LAUNCH_INIT: p=\(String(format: "%.1f", strikerMass * strikerVelocity))")
        
        Task { @MainActor in
            var currentV_A = strikerVelocity
            var v_B: Double = 0
            _ = 0.05
            
            while isSimulating {
                try? await Task.sleep(nanoseconds: 30_000_000)
                guard !Task.isCancelled && isSimulating else { break }
                
                withAnimation(.linear(duration: 0.03)) {
                    if self.strikerPos + 40 < self.targetPos {
                        self.strikerPos += CGFloat(currentV_A * 2.5)
                    } else if v_B == 0 {
                        // Collision Physics (Inelastic for simplicity)
                        let totalP = self.strikerMass * currentV_A
                        v_B = totalP / (self.strikerMass + self.targetMass)
                        currentV_A = v_B
                        self.updateLog("IMPACT: MOMENTUM_SHARED")
                    } else {
                        self.targetPos += CGFloat(v_B * 2.5)
                        self.strikerPos = self.targetPos - 40
                        
                        v_B *= 0.98
                        if v_B < 0.2 || self.targetPos > canvasWidth {
                            self.calculateAccuracy()
                        }
                    }
                }
            }
        }
    }
    
    private func calculateAccuracy() {
        isSimulating = false
        let finalCenter = targetPos + 20
        let targetCenter = targetZone.x + targetZone.width / 2
        let maxDist = targetZone.width / 2 + 30
        let distance = abs(finalCenter - targetCenter)
        
        accuracy = max(0, min(1.0, 1.0 - Double(distance / maxDist)))
        
        let pts = Int(accuracy * 100) * level
        totalScore += pts
        score = totalScore
        
        if accuracy > 0.7 {
            streak += 1
            updateLog("SUCCESS: OPTIMAL_TRANSFER")
        } else {
            streak = 0
            updateLog("FAILURE: SUBOPTIMAL_REST")
        }
        
        withAnimation(.spring()) { showResult = true }
    }
    
    private func nextLevel() {
        if level >= 10 {
            GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 4, badge: "Momentum Master")
            showResult = false
            showBadgeOverlay = true
        } else {
            level += 1
            if level > 3 {
                GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 4, badge: "Momentum Master")
            }
            targetMass = Double.random(in: 2.0...8.0)
            resetSim()
        }
    }
    
    private func resetSim() {
        strikerPos = 50
        targetPos = 180
        isSimulating = false
        withAnimation { showResult = false }
        accuracy = 0
        updateLog("SYS_RESET: AWAITING_INPUT")
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 4 { thinkingLog.removeFirst() }
        }
    }
}

struct MomentumObject: View {
    let color: Color
    let mass: Double
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color, lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .shadow(color: color.opacity(0.4), radius: 6)
                
                Text("\(Int(mass))kg")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.6))
                .cornerRadius(4)
        }
    }
}

#endif
