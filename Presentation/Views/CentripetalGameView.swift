#if os(iOS)
import SwiftUI

// MARK: - Centripetal Force Game
// Concept: Fc = (m * v^2) / r. Balancing rotation parameters for stable orbit.

@MainActor
struct CentripetalGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonAmber = Color(red: 1, green: 0.7, blue: 0.2)
    private let neonPurple = Color(red: 0.7, green: 0.2, blue: 1.0)
    
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
    @State private var showCalcOverlay = true
    @State private var showBadgeOverlay = false
    
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
                    onHint: { withAnimation { showHint.toggle() } }
                )
                
                ZStack {
                    GeometryReader { geo in
                        GridBackground(color: neonAmber, size: geo.size)
                    }
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if showHint {
                                FormulaCard(
                                    lines: ["Fç = (m × v²) / r", "a_c = v² / r"],
                                    note: "Centripetal force is the net force causing circular motion, directed toward the center."
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // Orbital Telemetry HUD
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "viewfinder.circle")
                                            .foregroundColor(neonAmber)
                                        Text("RADIAL_ANALYSIS").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(.gray)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        let currentF = (mass * velocity * velocity) / max(radius/20.0, 1.0)
                                        HUDDataRow(label: "T_FORCE", value: String(format: "%.1f N", currentF))
                                        HUDDataRow(label: "TARGET_F", value: String(format: "%.1f N", requiredForce))
                                        HUDDataRow(label: "V_ANGULAR", value: String(format: "%.2f rad/s", velocity / max(radius/20.0, 1.0)))
                                    }
                                    .padding(10)
                                    .background(Color.white.opacity(0.04))
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(neonAmber.opacity(0.2), lineWidth: 1))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("ORBITAL_STATUS: " + (isSimulating ? "ROTATING" : "HOLD"))
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundColor(isSimulating ? .green : neonAmber)
                                    ForEach(thinkingLog, id: \.self) { log in
                                        Text("> \(log)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(neonAmber.opacity(0.8))
                                    }
                                }
                                .frame(width: 140, alignment: .trailing)
                            }
                            .padding(.horizontal, 16)
                            
                            // Orbital Workspace
                            ZStack {
                                GeometryReader { geo in
                                    // Target Orbit Path
                                    Circle()
                                        .stroke(neonAmber.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                        .frame(width: CGFloat(requiredForce * 3), height: CGFloat(requiredForce * 3))
                                        .position(x: geo.size.width/2, y: geo.size.height/2)
                                    
                                    // Connection String
                                    Path { p in
                                        p.move(to: CGPoint(x: geo.size.width/2, y: geo.size.height/2))
                                        let endX = geo.size.width/2 + CGFloat(cos(angle) * (radius * 1.5))
                                        let endY = geo.size.height/2 + CGFloat(sin(angle) * (radius * 1.5))
                                        p.addLine(to: CGPoint(x: endX, y: endY))
                                    }
                                    .stroke(neonCyan.opacity(isSimulating ? 0.8 : 0.4), style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                                    
                                    // Pivot
                                    Circle()
                                        .fill(neonAmber)
                                        .frame(width: 12, height: 12)
                                        .shadow(color: neonAmber, radius: 8)
                                        .position(x: geo.size.width/2, y: geo.size.height/2)
                                    
                                    // Mass (Orbiting object)
                                    ZStack {
                                        Circle()
                                            .fill(neonCyan.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                        Circle()
                                            .stroke(neonCyan, lineWidth: 2)
                                            .frame(width: 32, height: 32)
                                            .shadow(color: neonCyan.opacity(0.5), radius: 6)
                                        Text("\(Int(mass))kg")
                                            .font(.system(size: 8, weight: .black, design: .monospaced))
                                            .foregroundColor(neonCyan)
                                    }
                                    .rotationEffect(.radians(angle))
                                    .offset(x: CGFloat(radius * 1.5))
                                    .position(x: geo.size.width/2, y: geo.size.height/2)
                                    .rotationEffect(.radians(angle))
                                    .overlay(
                                        // Velocity Vector arrow
                                        GeometryReader { __ in
                                            if !isSimulating {
                                                Image(systemName: "arrow.up")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(neonCyan)
                                                    .offset(y: -40)
                                                    .rotationEffect(.radians(angle + .pi/2))
                                                    .position(
                                                        x: geo.size.width/2 + CGFloat(cos(angle) * (radius * 1.5)),
                                                        y: geo.size.height/2 + CGFloat(sin(angle) * (radius * 1.5))
                                                    )
                                            }
                                        }
                                    )
                                    
                                    // Display Force Readout near mass
                                    let currentF = (mass * velocity * velocity) / max(radius/20.0, 1.0)
                                    Text("\(String(format: "%.1f", currentF)) N")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonCyan)
                                        .padding(4)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(4)
                                        .position(
                                            x: geo.size.width/2 + CGFloat(cos(angle) * (radius * 1.5)) + 30,
                                            y: geo.size.height/2 + CGFloat(sin(angle) * (radius * 1.5)) + 30
                                        )
                                }
                            }
                            .frame(height: 300)
                            .padding(.vertical, 10)
                            
                            // Control Panel
                            VStack(spacing: 20) {
                                ScientificSlider(label: "RADIUS_R (m)", value: $radius, range: 40...150, unit: "m", color: neonAmber)
                                ScientificSlider(label: "VELOCITY_V (m/s)", value: $velocity, range: 1...15, unit: "m/s", color: neonCyan)
                                ScientificSlider(label: "MASS_M (kg)", value: $mass, range: 1...10, unit: "kg", color: .purple)
                                
                                if !showResult {
                                    Button(action: toggleSimulation) {
                                        HStack {
                                            Image(systemName: isSimulating ? "stop.fill" : "play.fill")
                                            Text(isSimulating ? "HALT_ROTATION" : "START_ROTATION")
                                        }
                                        .font(.system(size: 14, weight: .black, design: .monospaced))
                                        .foregroundColor(.black)
                                        .padding(.vertical, 18)
                                        .frame(maxWidth: .infinity)
                                        .background(isSimulating ? Color.red : neonCyan)
                                        .cornerRadius(14)
                                        .shadow(color: isSimulating ? Color.red.opacity(0.4) : neonCyan.opacity(0.4), radius: 10)
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(24)
                            .padding(.horizontal, 16)
                            
                            if showResult {
                                ResultOverlay(accuracy: accuracy, onNext: nextLevel, onRetry: reset)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .padding(.horizontal, 16)
                            }
                            
                            // Step Calculation Box
                            GameCalcOverlay(
                                title: "CENTRIPETAL_CALC",
                                steps: {
                                    let fc = mass * velocity * velocity / max(radius / 100.0, 0.1)
                                    let omega = velocity / max(radius / 100.0, 0.1)
                                    let period = 2 * .pi / max(omega, 0.01)
                                    return [
                                        (label: "r (meters)", value: String(format: "%.2f", radius / 100.0) + " m"),
                                        (label: "Fc = mv²/r", value: String(format: "%.1f", fc) + " N"),
                                        (label: "ω = v/r", value: String(format: "%.2f", omega) + " rad/s"),
                                        (label: "T = 2π/ω", value: String(format: "%.2f", period) + " s"),
                                        (label: "Target Fc", value: String(format: "%.1f", requiredForce) + " N"),
                                        (label: "ΔF (error)", value: String(format: "%.1f", abs(fc - requiredForce)) + " N"),
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
            BadgeEarnedOverlay(badgeName: "Centripetal Commander") {
                showBadgeOverlay = false
                level = 1
                reset()
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
        showResult = false
        updateLog("ROTATION_ENGAGED")
        Task { @MainActor in
            while isSimulating {
                try? await Task.sleep(nanoseconds: 20_000_000) // 0.02s
                guard !Task.isCancelled && isSimulating else { break }
                let angularVel = self.velocity / max(self.radius/20.0, 1.0)
                // Add easing parameter for visual speed consistency
                self.angle += angularVel * 0.04
            }
        }
    }
    
    private func stopSim() {
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
        
        if accuracy > 0.8 {
            streak += 1
            updateLog("STABLE_ORBIT: LOCKED")
        } else {
            streak = 0
            updateLog("ORBIT_DECAY: UNSTABLE")
        }
        
        withAnimation(.spring()) { showResult = true }
    }
    
    private func nextLevel() {
        if level >= 10 {
            GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 6, badge: "Centripetal Commander")
            showResult = false
            showBadgeOverlay = true
        } else {
            level += 1
            if level > 3 {
                GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 6, badge: "Centripetal Commander")
            }
            reset()
        }
    }
    
    private func reset() {
        withAnimation { showResult = false }
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
