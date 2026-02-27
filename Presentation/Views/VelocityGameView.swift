#if os(iOS)
import SwiftUI

// MARK: - Optimize Velocity Game

@MainActor
struct VelocityGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonGreen = Color(red: 0.2, green: 1, blue: 0.4)
    private let neonRed = Color(red: 1, green: 0.3, blue: 0.3)
    
    @State private var forceInput: String = ""
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
    @State private var accuracy: Double = 0.0
    @State private var showCalcOverlay = true
    @State private var showBadgeOverlay = false
    
    // Level-based target velocity
    private var targetVelocity: Double { 5.0 + Double(level) * 2.5 }
    private var tolerance: Double { 0.1 }
    private var exactForce: Double { friction + (mass * targetVelocity / 3.0) }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                GameHeader(
                    title: "VELOCITY_OPTIMIZATION",
                    icon: "speedometer",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { withAnimation { showHint.toggle() } }
                )
                
                ZStack {
                    GeometryReader { geo in
                        GridBackground(color: neonCyan, size: geo.size)
                    }
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            if showHint {
                                FormulaCard(lines: [
                                    "a = (F − f) / m",
                                    "v = u + a·t"
                                ], note: "F: Applied Force, f: Friction, m: Mass")
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            
                            // Analysis HUB
                            VStack(spacing: 16) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "gauge.medium")
                                                .foregroundColor(neonCyan)
                                            Text("TARGET_SPEC").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(.gray)
                                        }
                                        
                                        Text(String(format: "%.1f m/s", targetVelocity))
                                            .font(.system(size: 24, weight: .black, design: .monospaced))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                        Text("REQD_FORCE")
                                            .font(.system(size: 8, weight: .black, design: .monospaced))
                                            .foregroundColor(.gray)
                                        Text("CALCULATING...")
                                            .font(.system(size: 14, weight: .black, design: .monospaced))
                                            .foregroundColor(neonCyan)
                                }
                                .padding(20)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                
                                // Simulation Track
                                ZStack(alignment: .leading) {
                                    // Track Base
                                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 2)
                                    
                                    // Milestones
                                    HStack(spacing: 0) {
                                        ForEach(0..<11) { i in
                                            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 8)
                                            if i < 10 { Spacer() }
                                        }
                                    }
                                    
                                    // Target Zone Glow
                                    let targetFrac = min(1.0, targetVelocity / 15.0)
                                    GeometryReader { geo in
                                        let targetPos = geo.size.width * targetFrac
                                        Rectangle()
                                            .fill(neonGreen.opacity(0.3))
                                            .frame(width: 20, height: 40)
                                            .blur(radius: 4)
                                            .position(x: targetPos, y: geo.size.height/2)
                                        
                                        VStack(spacing: 4) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(isRunning ? neonCyan : .gray)
                                                    .frame(width: 32, height: 32)
                                                    .shadow(color: isRunning ? neonCyan.opacity(0.5) : .clear, radius: 5)
                                                Text("\(Int(mass))").font(.system(size: 10, weight: .black)).foregroundColor(.black)
                                            }
                                            
                                            if isRunning {
                                                Text("\(String(format: "%.1f", currentVelocity))")
                                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                                    .foregroundColor(neonCyan)
                                            }
                                        }
                                        .position(x: geo.size.width * objectX, y: geo.size.height/2)
                                    }
                                }
                                .frame(height: 60)
                                .padding(.vertical, 10)
                            }
                            .padding(.horizontal, 16)
                            
                            // Controls
                            VStack(spacing: 20) {
                                Text(level > 3 ? "FORCE CALCULATIONS MASTERED" : "Calculate Exact Applied Force (F) required to reach \(String(format: "%.1f", targetVelocity)) m/s in 3s.")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 40) {
                                    VStack {
                                        Text("MASS").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                                        Text("\(String(format: "%.1f", mass)) kg").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                                    }
                                    VStack {
                                        Text("FRICTION").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                                        Text("\(String(format: "%.1f", friction)) N").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                                    }
                                    VStack {
                                        Text("TIME").font(.system(size: 10, weight: .bold)).foregroundColor(.gray)
                                        Text("3.0 s").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                                    }
                                }
                                
                                HStack {
                                    Text("F = ")
                                        .font(.system(size: 24, weight: .bold, design: .serif))
                                        .foregroundColor(neonCyan)
                                    TextField("?", text: $forceInput)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(width: 100)
                                        .padding(10)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(neonCyan, lineWidth: 1))
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.04))
                            .cornerRadius(24)
                            .padding(.horizontal, 16)
                            
                            if !showResult {
                                Button(action: launchSimulation) {
                                    HStack {
                                        Image(systemName: "bolt.fill")
                                        Text(isRunning ? "PROCESSING_LINK..." : "ENGAGE_SIMULATION")
                                    }
                                    .font(.system(size: 14, weight: .black, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(isRunning ? Color.gray : neonCyan)
                                    .cornerRadius(14)
                                    .shadow(color: isRunning ? .clear : neonCyan.opacity(0.3), radius: 10)
                                }
                                .padding(.horizontal, 16)
                                .disabled(isRunning)
                            }
                            
                            if showResult {
                                ResultOverlay(accuracy: accuracy, onNext: nextLevel, onRetry: retryLevel)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            // Step Calculation Box
                            GameCalcOverlay(
                                title: "VELOCITY_CALC",
                                steps: velocityCalcSteps,
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
            BadgeEarnedOverlay(badgeName: "Velocity Virtuoso") {
                showBadgeOverlay = false
                level = 1
                mass = 5.0
                friction = 2.0
                retryLevel()
            }
        }
    }
    
    private var velocityCalcSteps: [(label: String, value: String)] {
        let inputF = Double(forceInput) ?? 0
        let netForce = max(0, inputF - friction)
        let accel = netForce / mass
        let finalV = accel * 3.0
        return [
            (label: "F applied", value: "\(String(format: "%.1f", inputF)) N"),
            (label: "F net = F - f", value: "\(String(format: "%.1f", inputF)) - \(String(format: "%.1f", friction)) = \(String(format: "%.1f", netForce)) N"),
            (label: "a = F_net / m", value: "\(String(format: "%.2f", netForce)) / \(String(format: "%.1f", mass)) = \(String(format: "%.2f", accel)) m/s²"),
            (label: "v = u + a·t", value: "0 + \(String(format: "%.2f", accel)) × 3 = \(String(format: "%.2f", finalV)) m/s"),
            (label: "Target v", value: "\(String(format: "%.1f", targetVelocity)) m/s"),
            (label: "Δv (error)", value: "\(String(format: "%.2f", abs(finalV - targetVelocity))) m/s"),
        ]
    }
    
    private func launchSimulation() {
        guard let inForce = Double(forceInput) else { return }
        objectX = 0; currentVelocity = 0; isRunning = true; showResult = false
        let accel = max(0.0, (inForce - friction) / mass)
        let dt = 0.04
        var elapsed = 0.0
        let maxTime = 3.0
        
        Task { @MainActor in
            while isRunning {
                try? await Task.sleep(nanoseconds: UInt64(dt * 1_000_000_000))
                guard !Task.isCancelled && isRunning else { break }
                
                elapsed += dt
                let v = accel * elapsed
                let x = min(1.0, 0.5 * accel * elapsed * elapsed / 10.0)
                
                self.currentVelocity = v
                self.objectX = x
                
                if elapsed >= maxTime || x >= 1.0 {
                    self.isRunning = false
                    let diff = abs(v - self.targetVelocity)
                    self.accuracy = max(0, 1.0 - (diff / targetVelocity))
                    self.hitTarget = diff <= self.tolerance
                    
                    if hitTarget {
                        totalScore += Int(accuracy * 100) * level
                        streak += 1
                    } else {
                        streak = 0
                    }
                    
                    self.score = totalScore
                    withAnimation(.spring()) { showResult = true }
                }
            }
        }
    }
    
    private func nextLevel() {
        if level >= 10 {
            GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 1, badge: "Velocity Virtuoso")
            showResult = false
            showBadgeOverlay = true
        } else {
            level += 1
            mass += 2.0
            friction += 0.5
            if level > 3 {
                GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 1, badge: "Velocity Virtuoso")
            }
            retryLevel()
        }
    }
    private func retryLevel() { withAnimation { forceInput = ""; showResult = false; objectX = 0; currentVelocity = 0 } }
}


// MARK: - Supporting Views

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
