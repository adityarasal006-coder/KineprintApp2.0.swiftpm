import SwiftUI

// MARK: - Elastic Collision Game
// Concept: Conservation of Energy (KE) and Momentum. 
// Perfectly elastic collision: Both kinetic energy and momentum are conserved.

struct CollisionGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonPurple = Color(red: 0.7, green: 0.2, blue: 1.0)
    private let neonYellow = Color(red: 1, green: 0.9, blue: 0.2)
    
    @State private var m1: Double = 3.0
    @State private var m2: Double = 3.0
    @State private var v1: Double = 10.0
    @State private var pos1: CGFloat = 50
    @State private var pos2: CGFloat = 200
    @State private var isSimulating = false
    @State private var showResult = false
    @State private var accuracy: Double = 0.0
    @State private var level = 1
    @State private var showHint = false
    @State private var streak = 0
    @State private var totalScore = 0
    @State private var thinkingLog: [String] = ["SYS_INIT: COLLISION_LAB", "ANALYZING_ELASTIC_MODULUS"]
    @State private var energyTransferred: Double = 0
    @State private var canvasWidth: CGFloat = 300
    @State private var curV1: Double = 0
    @State private var curV2: Double = 0
    @State private var showCalcOverlay = true
    @State private var showBadgeOverlay = false
    
    private var targetZone: (x: CGFloat, width: CGFloat) {
        let x = 200 + CGFloat(level) * 15
        return (x, max(30, 60.0 - CGFloat(level) * 5))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                GameHeader(
                    title: "ELASTIC_COLLISION_CORE",
                    icon: "arrow.up.and.down.and.sparkles",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { withAnimation { showHint.toggle() } }
                )
                
                ZStack {
                    GeometryReader { geo in
                        GridBackground(color: neonPurple, size: geo.size)
                            .onAppear { canvasWidth = geo.size.width }
                    }
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if showHint {
                                FormulaCard(
                                    lines: [
                                        "v₂' = (2m₁) / (m₁+m₂) * v₁",
                                        "KE = ½mv²"
                                    ],
                                    note: "In a perfectly elastic collision, no kinetic energy is lost. Both momentum and KE are conserved."
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // Energy Diagnostics HUD
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "bolt.horizontal.circle")
                                            .foregroundColor(neonPurple)
                                        Text("ENERGY_MONITOR").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        HUDDataRow(label: "INIT_KE", value: String(format: "%.1f J", 0.5 * m1 * v1 * v1))
                                        HUDDataRow(label: "VEL_A (cur)", value: String(format: "%.1f m/s", isSimulating ? curV1 : v1))
                                        HUDDataRow(label: "VEL_B (cur)", value: String(format: "%.1f m/s", isSimulating ? curV2 : 0))
                                    }
                                    .padding(10)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(neonPurple.opacity(0.2), lineWidth: 1))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("STATUS: " + (isSimulating ? "COMPUTING" : "STABLE"))
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundColor(isSimulating ? neonYellow : .green)
                                    ForEach(thinkingLog, id: \.self) { log in
                                        Text("> \(log)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(neonPurple.opacity(0.7))
                                    }
                                }
                                .frame(width: 140, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            
                            // Particle Track
                            ZStack(alignment: .leading) {
                                // Base Line
                                Rectangle()
                                    .fill(LinearGradient(colors: [.clear, neonPurple.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                                    .frame(height: 2)
                                    .offset(y: 30)
                                
                                // Target Zone
                                Rectangle()
                                    .fill(neonYellow.opacity(0.15))
                                    .frame(width: targetZone.width, height: 60)
                                    .overlay(Rectangle().stroke(neonYellow.opacity(0.5), lineWidth: 1))
                                    .overlay(
                                        Text("ACCEPTABLE_RANGE")
                                            .font(.system(size: 6, weight: .bold, design: .monospaced))
                                            .foregroundColor(neonYellow)
                                            .offset(y: 40)
                                    )
                                    .offset(x: targetZone.x, y: 0)
                                
                                // Particle 2
                                CollisionParticle(color: neonYellow, mass: m2, label: "ION_B")
                                    .offset(x: pos2, y: 0)
                                
                                // Particle 1
                                CollisionParticle(color: neonCyan, mass: m1, label: "ION_A")
                                    .offset(x: pos1, y: 0)
                                    .overlay(
                                        // Velocity Vector Arrow
                                        HStack(spacing: 0) {
                                            Rectangle().fill(neonCyan).frame(width: CGFloat(v1 * 2), height: 2)
                                            Image(systemName: "play.fill").font(.system(size: 8)).foregroundColor(neonCyan).offset(x: -2)
                                        }
                                        .offset(x: 15 + CGFloat(v1), y: 0)
                                        .opacity(isSimulating || v1 == 0 ? 0 : 1)
                                    )
                            }
                            .frame(height: 100)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            
                            // Control Panel
                            VStack(spacing: 20) {
                                ScientificSlider(label: "ION_A_MASS (u)", value: $m1, range: 1...10, unit: "u", color: neonCyan)
                                ScientificSlider(label: "ION_B_MASS (u)", value: $m2, range: 1...10, unit: "u", color: neonYellow)
                                ScientificSlider(label: "INITIAL_VELOCITY (m/s)", value: $v1, range: 5...25, unit: "m/s", color: neonCyan)
                                
                                if !showResult {
                                    Button(action: executeCollision) {
                                        HStack {
                                            Image(systemName: isSimulating ? "network" : "bolt.horizontal.fill")
                                            Text(isSimulating ? "SIMULATING_IMPACT..." : "GENERATE_COLLISION")
                                        }
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .background(isSimulating ? Color.gray : neonPurple)
                                        .cornerRadius(14)
                                        .shadow(color: isSimulating ? .clear : neonPurple.opacity(0.4), radius: 10)
                                    }
                                    .disabled(isSimulating)
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(24)
                            .padding(.horizontal, 16)
                            
                            if showResult {
                                ResultOverlay(accuracy: accuracy, onNext: nextLevel, onRetry: resetParams)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .padding(.horizontal, 16)
                            }
                            
                            // Step Calculation Box
                            GameCalcOverlay(
                                title: "COLLISION_CALC",
                                steps: {
                                    let ke_initial = 0.5 * m1 * v1 * v1
                                    let v1f = ((m1 - m2) / (m1 + m2)) * v1
                                    let v2f = (2 * m1 / (m1 + m2)) * v1
                                    let ke_final = 0.5 * m1 * v1f * v1f + 0.5 * m2 * v2f * v2f
                                    return [
                                        (label: "KE_i = ½ m₁v₁²", value: String(format: "%.1f", ke_initial) + " J"),
                                        (label: "p_i = m₁v₁", value: String(format: "%.1f", m1 * v1) + " kg·m/s"),
                                        (label: "v1' (elastic)", value: String(format: "%.2f", v1f) + " m/s"),
                                        (label: "v2' (elastic)", value: String(format: "%.2f", v2f) + " m/s"),
                                        (label: "KE_f", value: String(format: "%.1f", ke_final) + " J"),
                                        (label: "KE conserved?", value: abs(ke_initial - ke_final) < 0.1 ? "✓ YES" : "✗ NO"),
                                    ]
                                }(),
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
            BadgeEarnedOverlay(badgeName: "Collision Analyst") {
                showBadgeOverlay = false
                level = 1
                resetParams()
            }
        }
    }
    
    private func executeCollision() {
        isSimulating = true
        showResult = false
        updateLog("ION_A_LAUNCHED: \(String(format: "%.1f", v1)) m/s")
        curV1 = v1
        curV2 = 0
        
        Task { @MainActor in
            let _ = 0.04
            while isSimulating {
                try? await Task.sleep(nanoseconds: 30_000_000)
                guard !Task.isCancelled && isSimulating else { break }
                
                withAnimation(.linear(duration: 0.03)) {
                    if self.pos1 + 30 < self.pos2 {
                        self.pos1 += CGFloat(curV1 * 1.5)
                    } else if curV2 == 0 {
                        // Elastic Collision Formulas
                        let v2_final = (2 * self.m1 * curV1) / (self.m1 + self.m2)
                        let v1_final = (self.m1 - self.m2) / (self.m1 + self.m2) * curV1
                        
                        curV1 = v1_final
                        curV2 = v2_final
                        self.updateLog("ELASTIC_IMPACT: ENERGY_EXCHANGED")
                    } else {
                        self.pos2 += CGFloat(curV2 * 1.5)
                        self.pos1 += CGFloat(curV1 * 1.5)
                        
                        curV2 *= 0.985
                        curV1 *= 0.985
                        
                        let isStopped = abs(curV2) < 0.2 && abs(curV1) < 0.2
                        let isOutOfBounds = self.pos2 > canvasWidth || self.pos1 > canvasWidth || self.pos1 < -30
                        
                        if isStopped || isOutOfBounds {
                            self.evaluate()
                        }
                    }
                }
            }
        }
    }
    
    private func evaluate() {
        isSimulating = false
        let finalPos = pos2 + 15
        let center = targetZone.x + targetZone.width / 2
        let maxDist = targetZone.width / 2 + 20
        let diff = abs(finalPos - center)
        
        accuracy = max(0, min(1.0, 1.0 - Double(diff / maxDist)))
        let pts = Int(accuracy * 100) * level
        totalScore += pts
        score = totalScore
        
        if accuracy > 0.7 {
            streak += 1
            updateLog("SUCCESS: OPTIMAL_ELASTICITY")
        } else {
            streak = 0
            updateLog("FAILURE: TARGET_MISSED")
        }
        
        withAnimation(.spring()) { showResult = true }
    }
    
    private func nextLevel() {
        if level >= 10 {
            GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 5, badge: "Collision Analyst")
            showResult = false
            showBadgeOverlay = true
        } else {
            level += 1
            if level > 3 {
                GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 5, badge: "Collision Analyst")
            }
            resetParams()
        }
    }
    
    private func resetParams() {
        pos1 = 50
        pos2 = 200
        withAnimation { showResult = false }
        accuracy = 0
        isSimulating = false
        curV1 = 0
        curV2 = 0
        updateLog("CORE_STABILIZED: READY")
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 4 { thinkingLog.removeFirst() }
        }
    }
}

struct CollisionParticle: View {
    let color: Color
    let mass: Double
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 30, height: 30)
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 30, height: 30)
                    .shadow(color: color.opacity(0.5), radius: 6)
                
                // Spark effect
                Circle()
                    .fill(color.opacity(0.4))
                    .frame(width: 8, height: 8)
                    .blur(radius: 4)
                
                Text("\(Int(mass))u")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(color)
                    .offset(y: 22)
            }
            
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.8))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.6))
                .cornerRadius(4)
                .offset(y: 10)
        }
    }
}


