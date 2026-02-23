#if os(iOS)
import SwiftUI

// MARK: - Predict Landing Point Game

struct LandingGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonGreen = Color(red: 0.2, green: 1, blue: 0.4)
    private let neonOrange = Color(red: 1, green: 0.6, blue: 0.1)
    private let g = 9.81
    
    @State private var v0: Double = 15.0       // Initial velocity m/s
    @State private var angle: Double = 45.0   // Launch angle degrees
    @State private var userTapX: Double? = nil
    @State private var isLaunched = false
    @State private var projectileX = 0.0
    @State private var projectileY = 0.0
    @State private var landingX = 0.0
    @State private var showTrail = false
    @State private var trailPoints: [CGPoint] = []
    @State private var showResult = false
    @State private var hitAccuracy: Double = 0
    @State private var level = 1
    @State private var totalScore = 0
    @State private var showHint = false
    @State private var canvasSize: CGSize = .zero
    @State private var streak = 0
    @State private var thinkingLog: [String] = ["SYSTEM_INIT: SUCCESS", "KINETIC_LINK: ESTABLISHED"]
    
    // Computed physics values
    private var timeOfFlight: Double { 2.0 * v0 * sin(angle * .pi / 180) / g }
    private var range: Double { v0 * v0 * sin(2.0 * angle * .pi / 180) / g }
    private var maxHeight: Double { v0 * v0 * pow(sin(angle * .pi / 180), 2) / (2 * g) }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                GameHeader(
                    title: "BALLISTIC_PREDICTION",
                    icon: "target",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { withAnimation { showHint.toggle() } }
                )
                
                ZStack {
                    GeometryReader { geo in
                        GridBackground(color: neonCyan, size: geo.size)
                            .onAppear { canvasSize = geo.size }
                    }
                    
                    VStack(spacing: 0) {
                        // Diagnostic HUD
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: "scope")
                                        .foregroundColor(neonCyan)
                                    Text("BALLISTIC_VARS").font(.system(size: 8, weight: .black, design: .monospaced)).foregroundColor(.gray)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HUDDataRow(label: "V_INIT", value: String(format: "%.1f m/s", v0))
                                    HUDDataRow(label: "LAUNCH_THETA", value: String(format: "%.0f°", angle))
                                    HUDDataRow(label: "G_FORCE", value: "9.81 m/s²")
                                }
                                .padding(10)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(neonCyan.opacity(0.2), lineWidth: 1))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("COMPUTE_MODULE: ACTIVE")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                                ForEach(thinkingLog, id: \.self) { log in
                                    Text("> \(log)")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(neonCyan.opacity(0.7))
                                }
                            }
                            .frame(width: 140, alignment: .trailing)
                        }
                        .padding(16)
                        
                        if showHint {
                            FormulaCard(lines: [
                                "Range: R = (v₀²·sin(2θ)) / g",
                                "Flight Time: T = (2·v₀·sinθ) / g"
                            ], note: "Calculate the expected range, then TAP where the arc will land.")
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        Spacer()
                        
                        // Physics Interaction Area
                        ZStack {
                            // Ground plane line
                            Rectangle()
                                .fill(LinearGradient(colors: [.clear, neonCyan.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing))
                                .frame(height: 1)
                                .position(x: canvasSize.width/2, y: canvasSize.height - 40)
                            
                            // Prediction crosshair
                            if let tapX = userTapX {
                                VStack(spacing: 0) {
                                    Text("EXPECTED_IMPACT")
                                        .font(.system(size: 7, weight: .black, design: .monospaced))
                                        .foregroundColor(neonOrange)
                                    Image(systemName: "scope")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(neonOrange)
                                    Rectangle().fill(neonOrange).frame(width: 1, height: 30)
                                }
                                .position(x: tapX, y: canvasSize.height - 55)
                            }
                            
                            // Projectile
                            if isLaunched {
                                if !trailPoints.isEmpty {
                                    Path { p in
                                        p.move(to: trailPoints[0])
                                        for pt in trailPoints { p.addLine(to: pt) }
                                    }
                                    .stroke(neonCyan.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                    
                                    Circle()
                                        .fill(neonCyan)
                                        .frame(width: 12, height: 12)
                                        .shadow(color: neonCyan.opacity(0.8), radius: 6)
                                        .position(trailPoints.last!)
                                }
                            }
                            
                            // Result impact marker
                            if showResult {
                                let rx = 40 + range * ((canvasSize.width - 80) / max(range, 1))
                                Circle()
                                    .stroke(Color.yellow, lineWidth: 2)
                                    .frame(width: 30, height: 30)
                                    .position(x: rx, y: canvasSize.height - 40)
                                Text("TRUE_IMPACT")
                                    .font(.system(size: 7, weight: .black, design: .monospaced))
                                    .foregroundColor(.yellow)
                                    .position(x: rx, y: canvasSize.height - 65)
                            }
                            
                            if showResult {
                                ResultOverlay(accuracy: hitAccuracy, onNext: nextLevel, onRetry: resetLevel)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { v in
                                    if !isLaunched && !showResult {
                                        userTapX = v.location.x
                                        updateLog("LOCK: TARGET_X_SET")
                                    }
                                }
                        )
                        
                        // Controls
                        VStack(spacing: 20) {
                            ScientificSlider(label: "LAUNCH_THETA", value: $angle, range: 10...85, unit: "°", color: neonOrange)
                            ScientificSlider(label: "INITIAL_THRUST", value: $v0, range: 5...35, unit: "m/s", color: neonCyan)
                            
                            Button(action: launchProjectile) {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                    Text(isLaunched ? "SIMULATING..." : (userTapX == nil ? "SELECT_TARGET" : "EXECUTE_LAUNCH"))
                                }
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(userTapX == nil ? Color.gray : (isLaunched ? Color.orange : neonGreen))
                                .cornerRadius(14)
                                .shadow(color: userTapX == nil ? .clear : neonGreen.opacity(0.3), radius: 10)
                            }
                            .disabled(userTapX == nil || isLaunched)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(24)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
    
    private func launchProjectile() {
        guard userTapX != nil else { return }
        isLaunched = true; showTrail = true; trailPoints = []; updateLog("STATUS: LAUNCHED")
        
        let cWidth = canvasSize.width
        let cHeight = canvasSize.height
        let capturedV0 = v0, capturedAngle = angle, capturedRange = range
        
        let scaleX = (cWidth - 80) / max(capturedRange, 1)
        let scaleHeight = (cHeight - 100) / max(maxHeight, 1)
        
        var localElapsed = 0.0
        let dt = 0.05
        
        Task { @MainActor in
            while isLaunched {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled && isLaunched else { break }
                
                localElapsed += dt
                let vx = capturedV0 * cos(capturedAngle * .pi / 180)
                let vy = capturedV0 * sin(capturedAngle * .pi / 180)
                let x = vx * localElapsed
                let y = vy * localElapsed - 0.5 * 9.81 * localElapsed * localElapsed
                
                let px = 40 + x * scaleX
                let py = cHeight - 40 - y * scaleHeight
                
                self.trailPoints.append(CGPoint(x: px, y: py))
                
                if y <= 0 && localElapsed > 0.1 {
                    isLaunched = false
                    self.calculateHitAccuracy()
                    withAnimation(.spring()) { self.showResult = true }
                    updateLog("STATUS: IMPACT_RECORDED")
                }
            }
        }
    }
    
    private func calculateHitAccuracy() {
        guard let tapX = userTapX else { return }
        let rx = 40 + range * ((canvasSize.width - 80) / max(range, 1))
        let diff = abs(tapX - rx)
        hitAccuracy = max(0, min(1.0, 1.0 - diff / (canvasSize.width * 0.2)))
        totalScore += Int(hitAccuracy * 100) * level
        score = totalScore
        if hitAccuracy > 0.7 { streak += 1 } else { streak = 0 }
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 4 { thinkingLog.removeFirst() }
        }
    }
    
    private func nextLevel() { level = min(level + 1, 10); resetLevel() }
    private func resetLevel() { userTapX = nil; isLaunched = false; showResult = false; trailPoints = [] }
}

// MARK: - Supporting Views

struct LandingResultView: View {
    let accuracy: Double
    let range: Double
    let onNext: () -> Void
    let onRetry: () -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            Text(accuracy > 0.8 ? "BULLSEYE_ACHIEVED" : "TRAJECTORY_MISMATCH")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(accuracy > 0.8 ? .green : .orange)
            
            Text("ACCURACY: \(Int(accuracy * 100))% | RANGE: \(String(format: "%.1f", range))m")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.gray)
            
            HStack(spacing: 16) {
                Button(action: onRetry) {
                    Text("RE-CALCULATE").font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white).padding(10).background(Color.white.opacity(0.1)).cornerRadius(6)
                }
                Button(action: onNext) {
                    Text("NEXT_TARGET").font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black).padding(10).background(neonCyan).cornerRadius(6)
                }
            }
        }
        .padding(16).background(Color.black.opacity(0.8)).overlay(RoundedRectangle(cornerRadius: 12).stroke(neonCyan.opacity(0.3), lineWidth: 1))
    }
}
#endif
