#if os(iOS)
import SwiftUI

// MARK: - Centripetal Force Game
// Concept: Fc = (m * v^2) / r. Balancing rotation parameters for stable orbit.

@available(iOS 16.0, *)
@MainActor
struct CentripetalGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonAmber = Color(red: 1, green: 0.7, blue: 0.2)
    
    @State private var radius: Double = 100.0
    @State private var velocity: Double = 5.0
    @State private var mass: Double = 2.0
    @State private var angle: Double = 0
    @State private var isSimulating = false
    @State private var showResult = false
    @State private var accuracy: Double = 0.0
    @State private var level = 1
    @State private var showHint = false
    @State private var streak = 0
    @State private var totalScore = 0
    @State private var thinkingLog: [String] = ["ORBIT_CORE: ACTIVE", "SCANNING_RADIAL_VECTORS"]
    @State private var timer: Timer?
    
    // Required Force for the level
    private var requiredForce: Double {
        return 10.0 + Double(level) * 15.0
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                GameHeader(
                    title: "CENTRIPETAL_SYNC",
                    icon: "rotate.right.fill",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { showHint.toggle() }
                )
                
                GeometryReader { geo in
                    ZStack {
                        GridBackground(color: neonAmber, size: geo.size)
                        
                        VStack(spacing: 0) {
                            // Orbital Telemetry
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("RADIAL_ANALYSIS")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonAmber)
                                    
                                    HUDDataRow(label: "T_FORCE", value: String(format: "%.1f N", (mass * velocity * velocity) / max(radius/20.0, 1.0)))
                                    HUDDataRow(label: "TARGET_F", value: String(format: "%.1f N", requiredForce))
                                    HUDDataRow(label: "V_ANGULAR", value: String(format: "%.2f rad/s", velocity / max(radius/20.0, 1.0)))
                                }
                                .padding(10)
                                .background(Color.black.opacity(0.4))
                                .border(neonAmber.opacity(0.3), width: 1)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    ForEach(thinkingLog, id: \.self) { log in
                                        Text("> \(log)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(neonAmber.opacity(0.7))
                                    }
                                }
                                .frame(width: 150, alignment: .trailing)
                            }
                            .padding(16)
                            
                            if showHint {
                                FormulaCard(
                                    lines: ["Fç = (m × v²) / r", "a_c = v² / r"],
                                    note: "Centripetal force is the net force causing circular motion, directed toward the center."
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            Spacer()
                            
                            // Orbital Workspace
                            ZStack {
                                // Pivot
                                Circle()
                                    .fill(neonAmber)
                                    .frame(width: 10, height: 10)
                                    .shadow(color: neonAmber, radius: 5)
                                
                                // Target Orbit Path
                                Circle()
                                    .stroke(neonAmber.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                    .frame(width: CGFloat(requiredForce * 6), height: CGFloat(requiredForce * 6))
                                
                                // Connection String
                                Path { p in
                                    p.move(to: CGPoint(x: geo.size.width/2, y: geo.size.height/2))
                                    let endX = geo.size.width/2 + CGFloat(cos(angle) * (radius * 1.5))
                                    let endY = geo.size.height/2 + CGFloat(sin(angle) * (radius * 1.5))
                                    p.addLine(to: CGPoint(x: endX, y: endY))
                                }
                                .stroke(neonCyan.opacity(0.4), lineWidth: 1)
                                
                                // Mass
                                Circle()
                                    .stroke(neonCyan, lineWidth: 2)
                                    .background(Circle().fill(neonCyan.opacity(0.2)))
                                    .frame(width: 24, height: 24)
                                    .offset(x: CGFloat(radius * 1.5))
                                    .rotationEffect(.radians(angle))
                                    .overlay(
                                        // Velocity Vector
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(neonCyan)
                                            .rotationEffect(.degrees(90))
                                            .offset(x: CGFloat(radius * 1.5), y: -20)
                                            .rotationEffect(.radians(angle))
                                    )
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            Spacer()
                            
                            // Control Panel
                            VStack(spacing: 16) {
                                ScientificSlider(label: "RADIUS", value: $radius, range: 40...150, unit: "m", color: neonAmber)
                                ScientificSlider(label: "VELOCITY", value: $velocity, range: 1...15, unit: "m/s", color: neonCyan)
                                
                                Button(action: toggleSimulation) {
                                    Text(isSimulating ? "STABILIZING..." : "START ROTATION")
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .padding(.vertical, 14)
                                        .frame(maxWidth: .infinity)
                                        .background(isSimulating ? Color.orange : neonCyan)
                                        .cornerRadius(10)
                                }
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
    
    private func toggleSimulation() {
        if isSimulating {
            stopSim()
            evaluate()
        } else {
            startSim()
        }
    }
    
    private func startSim() {
        isSimulating = true
        updateLog("ROTATION_ENGAGED")
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            Task { @MainActor in
                let angularVel = self.velocity / max(self.radius/20.0, 1.0)
                self.angle += angularVel * 0.05
            }
        }
    }
    
    private func stopSim() {
        timer?.invalidate()
        isSimulating = false
        updateLog("ROTATION_HALTED")
    }
    
    private func evaluate() {
        let currentF = (mass * velocity * velocity) / max(radius/20.0, 1.0)
        let diff = abs(currentF - requiredForce)
        accuracy = max(0, min(1.0, 1.0 - (diff / requiredForce)))
        
        let pts = Int(accuracy * 100) * level
        totalScore += pts
        score = totalScore
        
        if accuracy > 0.8 { streak += 1 } else { streak = 0 }
        showResult = true
    }
    
    private func nextLevel() {
        level = min(level + 1, 5)
        reset()
    }
    
    private func reset() {
        showResult = false
        accuracy = 0
        angle = 0
        updateLog("GYRO_STABILIZED")
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 4 { thinkingLog.removeFirst() }
        }
    }
}

#endif
