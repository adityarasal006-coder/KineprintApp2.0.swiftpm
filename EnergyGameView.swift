#if os(iOS)
import SwiftUI

// MARK: - Kinetic Energy Game
// Concept: KE = 1/2 * m * v². Mastering the relationship between speed and energy.

@available(iOS 16.0, *)
@MainActor
struct EnergyGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonRed = Color(red: 1, green: 0.2, blue: 0.3)
    
    @State private var mass: Double = 5.0
    @State private var velocity: Double = 10.0
    @State private var isSimulating = false
    @State private var showResult = false
    @State private var accuracy: Double = 0.0
    @State private var level = 1
    @State private var showHint = false
    @State private var streak = 0
    @State private var totalScore = 0
    @State private var thinkingLog: [String] = ["ENERGY_GRID: ONLINE", "MONITORING_JOULE_OUTPUT"]
    @State private var dischargeProgress: Double = 0
    
    // Required Joules for the level
    private var requiredEnergy: Double {
        return 200.0 + Double(level) * 300.0
    }
    
    private var currentKE: Double {
        0.5 * mass * velocity * velocity
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                GameHeader(
                    title: "KINETIC_HARVEST",
                    icon: "bolt.batteryblock.fill",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { showHint.toggle() }
                )
                
                GeometryReader { geo in
                    ZStack {
                        GridBackground(color: neonRed, size: geo.size)
                        
                        VStack(spacing: 0) {
                            // Energy HUD
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("POWER_TELEMETRY")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonRed)
                                    
                                    HUDDataRow(label: "CUR_KE", value: String(format: "%.1f J", currentKE))
                                    HUDDataRow(label: "TARGET_KE", value: String(format: "%.1f J", requiredEnergy))
                                    HUDDataRow(label: "GRID_LOAD", value: "\(Int((currentKE/requiredEnergy)*100))%")
                                }
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .border(neonRed.opacity(0.3), width: 1)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    ForEach(thinkingLog, id: \.self) { log in
                                        Text("> \(log)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(neonRed.opacity(0.7))
                                    }
                                }
                                .frame(width: 150, alignment: .trailing)
                            }
                            .padding(16)
                            
                            if showHint {
                                FormulaCard(
                                    lines: ["KE = ½mv²"],
                                    note: "Doubling velocity quadruples the kinetic energy. Mass has a linear relationship."
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            Spacer()
                            
                            // Visual Capacitor / Energy Well
                            ZStack {
                                // Background Battery Cell
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(neonRed.opacity(0.3), lineWidth: 4)
                                    .frame(width: 120, height: 240)
                                
                                // Filling Level
                                VStack {
                                    Spacer()
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(currentKE > requiredEnergy * 1.1 ? Color.orange : (currentKE > requiredEnergy * 0.9 ? neonCyan : neonRed.opacity(0.6)))
                                        .frame(width: 100, height: CGFloat(min(currentKE / (requiredEnergy * 1.2), 1.0)) * 220)
                                        .shadow(color: neonRed.opacity(0.5), radius: 10)
                                }
                                .frame(width: 120, height: 240)
                                
                                // Target Line
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 130, height: 2)
                                    .offset(y: 120 - CGFloat(requiredEnergy / (requiredEnergy * 1.2)) * 220)
                                    .overlay(
                                        Text("TARGET_LOAD")
                                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                            .offset(x: 80)
                                    )
                                
                                if isSimulating {
                                    // Lightning effects
                                    ForEach(0..<5) { i in
                                        LightningBolt()
                                            .stroke(neonCyan, lineWidth: 2)
                                            .frame(width: 50, height: 100)
                                            .offset(x: CGFloat.random(in: -60...60), y: CGFloat.random(in: -100...100))
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Control Panel
                            VStack(spacing: 20) {
                                ScientificSlider(label: "TEST_MASS", value: $mass, range: 1...20, unit: "kg", color: .gray)
                                ScientificSlider(label: "TEST_VELOCITY", value: $velocity, range: 1...30, unit: "m/s", color: neonCyan)
                                
                                Button(action: pulseGrid) {
                                    Text(isSimulating ? "CHARGING..." : "PULSE GRID")
                                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(isSimulating ? Color.gray : (currentKE > requiredEnergy * 0.9 && currentKE < requiredEnergy * 1.1 ? neonCyan : neonRed))
                                        .cornerRadius(12)
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
    
    private func pulseGrid() {
        isSimulating = true
        updateLog("INITIATING_DISCHARGE...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSimulating = false
            evaluate()
        }
    }
    
    private func evaluate() {
        let diff = abs(currentKE - requiredEnergy)
        accuracy = max(0, min(1.0, 1.0 - (diff / requiredEnergy)))
        
        let pts = Int(accuracy * 100) * level
        totalScore += pts
        score = totalScore
        
        if accuracy > 0.85 {
            streak += 1
            updateLog("STABLE_TRANSFER: GRID_ENERGIZED")
        } else {
            streak = 0
            updateLog("ERROR: LOAD_MISMATCH")
        }
        showResult = true
    }
    
    private func nextLevel() {
        level = min(level + 1, 5)
        reset()
    }
    
    private func reset() {
        showResult = false
        accuracy = 0
        updateLog("RECALIBRATING_GRID")
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 4 { thinkingLog.removeFirst() }
        }
    }
}

@available(iOS 16.0, *)
struct LightningBolt: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

#endif
