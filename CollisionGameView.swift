#if os(iOS)
import SwiftUI

// MARK: - Elastic Collision Game
// Concept: Conservation of Energy (KE) and Momentum. 
// Perfectly elastic collision: Both kinetic energy and momentum are conserved.

@available(iOS 16.0, *)
@MainActor
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
    @State private var timer: Timer?
    @State private var energyTransferred: Double = 0
    
    private var targetZone: (x: CGFloat, width: CGFloat) {
        let x = 280 + CGFloat(level) * 15
        return (x, 50.0)
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
                    onHint: { showHint.toggle() }
                )
                
                GeometryReader { geo in
                    ZStack {
                        GridBackground(color: neonPurple, size: geo.size)
                        
                        VStack(spacing: 0) {
                            // Energy Diagnostics
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("ENERGY_MONITOR")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonPurple)
                                    
                                    HUDDataRow(label: "INIT_KE", value: String(format: "%.1f J", 0.5 * m1 * v1 * v1))
                                    HUDDataRow(label: "TARGET_M", value: String(format: "%.1f kg", m2))
                                    HUDDataRow(label: "STATUS", value: isSimulating ? "COMPUTING" : "STABLE")
                                }
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .border(neonPurple.opacity(0.3), width: 1)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    ForEach(thinkingLog, id: \.self) { log in
                                        Text("> \(log)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(neonPurple.opacity(0.7))
                                    }
                                }
                                .frame(width: 150, alignment: .trailing)
                            }
                            .padding(16)
                            
                            if showHint {
                                FormulaCard(
                                    lines: ["v₂' = (2m₁) / (m₁+m₂) * v₁", "KE = ½mv²"],
                                    note: "In a perfectly elastic collision, no kinetic energy is lost to heat or sound."
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            Spacer()
                            
                            // Particle Track
                            ZStack(alignment: .leading) {
                                // Zone
                                Rectangle()
                                    .fill(neonPurple.opacity(0.2))
                                    .frame(width: targetZone.width, height: 60)
                                    .overlay(Rectangle().stroke(neonPurple, lineWidth: 1))
                                    .offset(x: targetZone.x, y: 0)
                                
                                // Particle 2
                                CollisionParticle(color: neonPurple, mass: m2, label: "ION_B")
                                    .offset(x: pos2, y: 0)
                                
                                // Particle 1
                                CollisionParticle(color: neonCyan, mass: m1, label: "ION_A")
                                    .offset(x: pos1, y: 0)
                            }
                            .frame(height: 100)
                            .padding(.horizontal, 20)
                            
                            Spacer()
                            
                            // Control Panel
                            VStack(spacing: 16) {
                                HStack(spacing: 15) {
                                    ScientificSlider(label: "ION_A_MASS", value: $m1, range: 1...10, unit: "u", color: neonCyan)
                                    ScientificSlider(label: "ION_B_MASS", value: $m2, range: 1...10, unit: "u", color: neonPurple)
                                }
                                ScientificSlider(label: "INITIAL_VELOCITY", value: $v1, range: 5...25, unit: "m/s", color: neonCyan)
                                
                                Button(action: executeCollision) {
                                    Text(isSimulating ? "SIMULATING..." : "GENERATE COLLISION")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(isSimulating ? Color.gray : neonPurple)
                                        .cornerRadius(10)
                                }
                                .disabled(isSimulating)
                            }
                            .padding(20)
                            .background(Color.black.opacity(0.6))
                        }
                        
                        if showResult {
                            ResultOverlay(accuracy: accuracy, onNext: nextLevel, onRetry: reset)
                        }
                    }
                }
            }
        }
    }
    
    private func executeCollision() {
        isSimulating = true
        updateLog("ION_A_LAUNCHED: \(String(format: "%.1f", v1)) m/s")
        
        var curV1 = v1
        var curV2: Double = 0
        let dt = 0.04
        
        timer = Timer.scheduledTimer(withTimeInterval: dt, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.linear(duration: dt)) {
                    if self.pos1 + 30 < self.pos2 {
                        self.pos1 += CGFloat(curV1 * 1.5)
                    } else if curV2 == 0 {
                        // Elastic Collision Formulas
                        let v2_final = (2 * self.m1 * curV1) / (self.m1 + self.m2)
                        let v1_final = (self.m1 - self.m2) / (self.m1 + self.m2) * curV1
                        
                        curV1 = v1_final
                        curV2 = v2_final
                        self.updateLog("ELASTIC_IMPACT: ENERGY_TRANSFERRED")
                    } else {
                        self.pos2 += CGFloat(curV2 * 1.5)
                        self.pos1 += CGFloat(curV1 * 1.5)
                        
                        curV2 *= 0.99
                        curV1 *= 0.99
                        
                        if abs(curV2) < 0.2 && abs(curV1) < 0.2 {
                            self.timer?.invalidate()
                            self.evaluate()
                        }
                    }
                }
            }
        }
    }
    
    private func evaluate() {
        let finalPos = pos2 + 15
        let center = targetZone.x + targetZone.width / 2
        let diff = abs(finalPos - center)
        
        accuracy = max(0, min(1.0, 1.0 - Double(diff / 80.0)))
        
        let pts = Int(accuracy * 100) * level
        totalScore += pts
        score = totalScore
        
        if accuracy > 0.8 { streak += 1 } else { streak = 0 }
        showResult = true
        isSimulating = false
    }
    
    private func nextLevel() {
        level = min(level + 1, 5)
        reset()
    }
    
    private func reset() {
        pos1 = 50
        pos2 = 200
        showResult = false
        accuracy = 0
        isSimulating = false
        updateLog("CORE_STABILIZED: READY")
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 4 { thinkingLog.removeFirst() }
        }
    }
}

@available(iOS 16.0, *)
struct CollisionParticle: View {
    let color: Color
    let mass: Double
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 30, height: 30)
                Circle()
                    .stroke(color, lineWidth: 2)
                    .frame(width: 30, height: 30)
                
                // Spark effect
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: 10, height: 10)
                    .blur(radius: 5)
            }
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

#endif
