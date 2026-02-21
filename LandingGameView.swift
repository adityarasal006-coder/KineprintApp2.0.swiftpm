#if os(iOS)
import SwiftUI

// MARK: - Predict Landing Point Game

@MainActor
@available(iOS 16.0, *)
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
    @State private var elapsedTime = 0.0
    @State private var landingX = 0.0
    @State private var showTrail = false
    @State private var trailPoints: [CGPoint] = []
    @State private var timer: Timer?
    @State private var showResult = false
    @State private var hitAccuracy: Double = 0
    @State private var level = 1
    @State private var totalScore = 0
    @State private var showHint = false
    @State private var canvasWidth: Double = 320
    @State private var streak = 0
    @State private var canvasHeight: Double = 200
    @State private var thinkingLog: [String] = ["SYSTEM_IDLE", "AWAITING_BALLISTIC_TARGET"]
    
    // Computed physics values
    private var timeOfFlight: Double { 2.0 * v0 * sin(angle * .pi / 180) / g }
    private var range: Double { v0 * v0 * sin(2.0 * angle * .pi / 180) / g }
    private var maxHeight: Double { v0 * v0 * pow(sin(angle * .pi / 180), 2) / (2 * g) }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                GameHeader(
                    title: "PREDICT LANDING",
                    icon: "target",
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { showHint.toggle() }
                )
                
                if showHint {
                    FormulaCard(lines: [
                        "R = v₀²·sin(2θ) / g",
                        "H_max = v₀²·sin²(θ) / 2g",
                        "t_flight = 2·v₀·sinθ / g"
                    ], note: "Use the given v₀ and θ, then TAP where you predict the projectile lands")
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Advanced Physics Stage
                ZStack {
                    GeometryReader { geo in
                        GridBackground(color: neonCyan, size: geo.size)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Diagnostic HUD
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("BALLISTIC_VARS", systemImage: "target")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(neonCyan)
                                
                                HUDDataRow(label: "V_0", value: String(format: "%.1f m/s", v0))
                                HUDDataRow(label: "THETA", value: String(format: "%.0f°", angle))
                                HUDDataRow(label: "G_REF", value: "9.81 m/s²")
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.6))
                            .border(neonCyan.opacity(0.3), width: 1)
                            
                            Spacer()
                            
                            // Thinking Log
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("COMPUTE_MODULE: ONLINE")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                                ForEach(thinkingLog, id: \.self) { log in
                                    Text("> \(log)")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(neonCyan.opacity(0.7))
                                }
                            }
                            .frame(width: 160, alignment: .trailing)
                        }
                        .padding(16)
                        
                        // Canvas Area
                        GeometryReader { geo in
                            ZStack {
                                // Ground plane
                                Path { p in
                                    p.move(to: CGPoint(x: 0, y: geo.size.height - 30))
                                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - 30))
                                }
                                .stroke(neonCyan.opacity(0.3), lineWidth: 1)
                                
                                // Predictive Dots
                                if !isLaunched && userTapX == nil {
                                    Path { path in
                                        let step = geo.size.width / 20.0
                                        for i in 0...10 {
                                            let x = CGFloat(i) * step + 30
                                            path.addEllipse(in: CGRect(x: x, y: geo.size.height - 32, width: 2, height: 2))
                                        }
                                    }
                                    .fill(neonCyan.opacity(0.2))
                                }
                                
                                // Projectile & Trail
                                if isLaunched {
                                    // Ball
                                    Circle()
                                        .fill(neonCyan)
                                        .frame(width: 12, height: 12)
                                        .shadow(color: neonCyan.opacity(0.6), radius: 6)
                                        .position(trailPoints.last ?? CGPoint(x: 30, y: geo.size.height - 30))
                                    
                                    // Altitude readout
                                    VStack(alignment: .leading) {
                                        Text("ALT: \(String(format: "%.1fm", projectileY))")
                                        Text("DIST: \(String(format: "%.1fm", projectileX))")
                                    }
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(neonCyan)
                                    .position(x: (trailPoints.last?.x ?? 0) + 40, y: (trailPoints.last?.y ?? 0) - 20)
                                    
                                    // Trail
                                    Path { path in
                                        if let first = trailPoints.first {
                                            path.move(to: first)
                                            for pt in trailPoints { path.addLine(to: pt) }
                                        }
                                    }
                                    .stroke(neonCyan, style: StrokeStyle(lineWidth: 1.5, dash: [4, 2]))
                                }
                                
                                // Target marker (scientist style)
                                if let tapX = userTapX {
                                    VStack(spacing: 0) {
                                        Text("PREDICTION_TARGET")
                                            .font(.system(size: 6, weight: .bold, design: .monospaced))
                                            .foregroundColor(neonOrange)
                                        Image(systemName: "scope")
                                            .font(.system(size: 20))
                                            .foregroundColor(neonOrange)
                                        Rectangle().fill(neonOrange).frame(width: 1, height: 20)
                                    }
                                    .position(x: tapX, y: geo.size.height - 40)
                                }
                                
                                // Actual landing marker
                                if showResult {
                                    let rx = 30 + range * ((geo.size.width - 60) / max(range, 1))
                                    Circle()
                                        .stroke(Color.yellow, lineWidth: 2)
                                        .frame(width: 30, height: 30)
                                        .position(x: rx, y: geo.size.height - 30)
                                    Text("IMPACT_SITE")
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundColor(.yellow)
                                        .position(x: rx, y: geo.size.height - 50)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { loc in
                                if !isLaunched && !showResult {
                                    userTapX = loc.x
                                    updateLog("TARGET_LOCKED: \(Int(loc.x))px")
                                }
                            }
                            .onAppear { canvasWidth = geo.size.width; canvasHeight = geo.size.height }
                        }
                        .padding(.bottom, 20)
                        
                        // Controls
                        HStack(spacing: 12) {
                            ScientificSlider(label: "LAUNCH_ARC", value: $angle, range: 10...85, unit: "°", color: neonOrange)
                            ScientificSlider(label: "THRUST_SEC", value: $v0, range: 5...35, unit: "m/s", color: neonCyan)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Action
                        if !showResult {
                            Button(action: launchProjectile) {
                                Text(isLaunched ? "SIMULATING_FLIGHT..." : (userTapX == nil ? "AWAITING_TARGET_TAP" : "INITIATE_LAUNCH"))
                                    .font(.system(size: 14, weight: .black, design: .monospaced))
                                    .foregroundColor(.black)
                                    .padding(.vertical, 18)
                                    .frame(maxWidth: .infinity)
                                    .background(userTapX == nil ? Color.gray : (isLaunched ? Color.orange : neonGreen))
                                    .cornerRadius(12)
                                    .shadow(color: (userTapX == nil ? .clear : neonGreen.opacity(0.3)), radius: 8)
                            }
                            .padding(16)
                            .disabled(userTapX == nil || isLaunched)
                        }
                        
                        if showResult {
                            LandingResultView(accuracy: hitAccuracy, range: range, onNext: nextLevel, onRetry: resetLevel)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showHint)
        .animation(.easeInOut(duration: 0.3), value: showResult)
        .onDisappear { timer?.invalidate() }
    }
    
    private func launchProjectile() {
        guard userTapX != nil else { return }
        isLaunched = true; showTrail = true; trailPoints = []; elapsedTime = 0
        let dt = 0.05
        let scaleX = (canvasWidth - 60) / max(range, 1)
        let scaleY = (canvasHeight - 60) / max(maxHeight, 1)
        
        let capturedV0 = v0
        let capturedAngle = angle
        let capturedCanvasHeight = canvasHeight
        let capturedRange = range
        let capturedG = g
        var localElapsed = 0.0
        timer = Timer.scheduledTimer(withTimeInterval: dt, repeats: true) { t in
            Task { @MainActor in
                localElapsed += dt
                let te = localElapsed
                let vx = capturedV0 * cos(capturedAngle * .pi / 180)
                let vy = capturedV0 * sin(capturedAngle * .pi / 180)
                let newX = vx * te
                let newY = vy * te - 0.5 * capturedG * te * te
                let px = 30 + newX * scaleX
                let py = capturedCanvasHeight - 30 - newY * scaleY
                let shouldStop = newY <= 0 && te > 0.1
                if shouldStop { t.invalidate() }
                
                self.elapsedTime = te
                self.projectileX = newX
                self.projectileY = newY
                self.trailPoints.append(CGPoint(x: px, y: py))
                if shouldStop {
                    self.landingX = 30 + capturedRange * scaleX
                    self.calculateHitAccuracy()
                    self.isLaunched = false
                    self.showResult = true
                }
            }
        }
    }
    
    private func calculateHitAccuracy() {
        guard let tapX = userTapX else { return }
        let diff = abs(tapX - landingX)
        hitAccuracy = max(0, min(1.0, 1.0 - diff / (canvasWidth * 0.3)))
        let pts = Int(hitAccuracy * 100) * level
        totalScore += pts
        score = totalScore
        if hitAccuracy > 0.6 { streak += 1 } else { streak = 0 }
    }
    
    private func updateLog(_ msg: String) {
        withAnimation {
            thinkingLog.append(msg)
            if thinkingLog.count > 4 { thinkingLog.removeFirst() }
        }
    }
    
    private func nextLevel() {
        level = min(level + 1, 6)
        v0 = 10.0 + Double(level) * 2.5
        angle = Double.random(in: 30...60)
        resetLevel()
    }
    
    private func resetLevel() {
        userTapX = nil; isLaunched = false; showResult = false
        projectileX = 0; projectileY = 0; trailPoints = []; showTrail = false
    }
}

// MARK: - Supporting Views

@available(iOS 16.0, *)
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
