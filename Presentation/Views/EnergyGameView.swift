#if os(iOS)
import SwiftUI

// MARK: - Kinetic Energy Game
// Concept: KE = 1/2 * m * v². Mastering the relationship between speed and energy.

struct EnergyGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonRed = Color(red: 1, green: 0.2, blue: 0.3)
    private let neonYellow = Color(red: 1, green: 0.9, blue: 0.2)
    
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
    @State private var showCalcOverlay = true
    @State private var showBadgeOverlay = false
    
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
                    onHint: { withAnimation { showHint.toggle() } }
                )
                
                ZStack {
                    GeometryReader { geo in
                        GridBackground(color: neonRed, size: geo.size)
                    }
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if showHint {
                                FormulaCard(
                                    lines: ["KE = ½mv²"],
                                    note: "Doubling velocity quadruples the kinetic energy. Mass has a linear relationship."
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // Energy HUD
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "bolt.circle.fill")
                                            .foregroundColor(neonRed)
                                        Text("POWER_TELEMETRY").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        HUDDataRow(label: "CUR_KE", value: String(format: "%.1f J", currentKE))
                                        HUDDataRow(label: "TARGET_KE", value: String(format: "%.1f J", requiredEnergy))
                                        
                                        let loadRatio = (currentKE/requiredEnergy)*100
                                        HUDDataRow(label: "GRID_LOAD", value: String(format: "%.0f%%", loadRatio))
                                    }
                                    .padding(10)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(neonRed.opacity(0.2), lineWidth: 1))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("CAPACITOR_CORE_v2")
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonCyan)
                                    ForEach(thinkingLog, id: \.self) { log in
                                        Text("> \(log)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(neonRed.opacity(0.8))
                                    }
                                }
                                .frame(width: 140, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            
                            // Visual Capacitor / Energy Well
                            ZStack {
                                // Background Battery Cell
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.black.opacity(0.8))
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(LinearGradient(colors: [neonRed.opacity(0.6), neonRed.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 4)
                                }
                                .frame(width: 130, height: 260)
                                .shadow(color: neonRed.opacity(0.3), radius: 20)
                                
                                // Filling Level
                                VStack {
                                    Spacer()
                                    let fillRatio = min(currentKE / (requiredEnergy * 1.3), 1.0)
                                    let isOptimal = currentKE >= requiredEnergy * 0.9 && currentKE <= requiredEnergy * 1.1
                                    
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(LinearGradient(colors: [isOptimal ? neonCyan : neonRed, (isOptimal ? neonCyan : neonRed).opacity(0.5)], startPoint: .top, endPoint: .bottom))
                                        .frame(width: 110, height: CGFloat(fillRatio) * 240)
                                        .shadow(color: (isOptimal ? neonCyan : neonRed).opacity(0.6), radius: 15)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentKE)
                                }
                                .frame(width: 130, height: 260)
                                
                                // Target Line
                                let targetRatio = requiredEnergy / (requiredEnergy * 1.3)
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 150, height: 2)
                                    .offset(y: 130 - CGFloat(targetRatio) * 260)
                                    .overlay(
                                        HStack {
                                            Text("TARGET_LOAD")
                                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.black.opacity(0.8))
                                                .cornerRadius(4)
                                            Spacer()
                                        }
                                        .offset(x: 170, y: 130 - CGFloat(targetRatio) * 260)
                                    )
                                    .shadow(color: .white, radius: 4)
                                
                                if isSimulating {
                                    // Lightning effects
                                    ForEach(0..<6, id: \.self) { _ in
                                        LightningBolt()
                                            .stroke(neonCyan, lineWidth: 2)
                                            .frame(width: 60, height: 120)
                                            .offset(x: CGFloat.random(in: -50...50), y: CGFloat.random(in: -100...100))
                                            .shadow(color: neonCyan, radius: 8)
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                            
                            // Control Panel
                            VStack(spacing: 20) {
                                ScientificSlider(label: "TEST_MASS (kg)", value: $mass, range: 1...20, unit: "kg", color: .purple)
                                ScientificSlider(label: "TEST_VELOCITY (m/s)", value: $velocity, range: 1...30, unit: "m/s", color: neonCyan)
                                
                                if !showResult {
                                    let isOptimal = currentKE >= requiredEnergy * 0.9 && currentKE <= requiredEnergy * 1.1
                                    Button(action: pulseGrid) {
                                        HStack {
                                            Image(systemName: isSimulating ? "bolt.batteryblock.fill" : "bolt.fill")
                                            Text(isSimulating ? "DISCHARGING..." : "PULSE_GRID")
                                        }
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundColor(isOptimal ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 18)
                                        .background(isSimulating ? Color.gray : (isOptimal ? neonCyan : neonRed))
                                        .cornerRadius(14)
                                        .shadow(color: isSimulating ? .clear : (isOptimal ? neonCyan.opacity(0.4) : neonRed.opacity(0.3)), radius: 10)
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
                                title: "ENERGY_CALC",
                                steps: [
                                    (label: "m", value: String(format: "%.1f", mass) + " kg"),
                                    (label: "v", value: String(format: "%.1f", velocity) + " m/s"),
                                    (label: "v²", value: String(format: "%.1f", velocity * velocity)),
                                    (label: "KE = ½mv²", value: String(format: "%.1f", currentKE) + " J"),
                                    (label: "Target KE", value: String(format: "%.1f", requiredEnergy) + " J"),
                                    (label: "Δ Energy", value: String(format: "%.1f", abs(currentKE - requiredEnergy)) + " J"),
                                ],
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
            BadgeEarnedOverlay(badgeName: "Energy Harvester") {
                showBadgeOverlay = false
                level = 1
                resetParams()
            }
        }
    }
    
    private func pulseGrid() {
        isSimulating = true
        showResult = false
        updateLog("INITIATING_DISCHARGE...")
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
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
        
        withAnimation(.spring()) { showResult = true }
    }
    
    private func nextLevel() {
        if level >= 10 {
            GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 7, badge: "Energy Harvester")
            showResult = false
            showBadgeOverlay = true
        } else {
            level += 1
            if level > 3 {
                GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 7, badge: "Energy Harvester")
            }
            resetParams()
        }
    }
    
    private func resetParams() {
        withAnimation { showResult = false }
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

struct LightningBolt: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let startX = rect.midX + CGFloat.random(in: -10...10)
        path.move(to: CGPoint(x: startX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + CGFloat.random(in: 0...10), y: rect.midY - CGFloat.random(in: 0...10)))
        path.addLine(to: CGPoint(x: rect.maxX - CGFloat.random(in: 0...10), y: rect.midY + CGFloat.random(in: 0...10)))
        path.addLine(to: CGPoint(x: rect.midX + CGFloat.random(in: -10...10), y: rect.maxY))
        return path
    }
}

#endif
