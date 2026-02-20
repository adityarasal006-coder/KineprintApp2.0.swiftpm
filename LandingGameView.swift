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
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Problem statement
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("INITIAL VELOCITY")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Text(String(format: "v₀ = %.1f m/s", v0))
                                        .font(.system(size: 20, weight: .heavy, design: .monospaced))
                                        .foregroundColor(neonCyan)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("LAUNCH ANGLE")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                    Text(String(format: "θ = %.0f°", angle))
                                        .font(.system(size: 20, weight: .heavy, design: .monospaced))
                                        .foregroundColor(neonOrange)
                                }
                            }
                            
                            // Physics preview row
                            HStack(spacing: 0) {
                                PhysicsDataCell(label: "RANGE", value: String(format: "%.1f m", range), color: neonGreen)
                                PhysicsDataCell(label: "MAX H", value: String(format: "%.1f m", maxHeight), color: neonCyan)
                                PhysicsDataCell(label: "TIME", value: String(format: "%.2f s", timeOfFlight), color: neonOrange)
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(neonCyan.opacity(0.15), lineWidth: 0.5))
                        
                        // Canvas
                        GeometryReader { geo in
                            ZStack {
                                GridBackground(color: neonCyan, size: geo.size)
                                
                                // Ground line
                                Path { p in
                                    p.move(to: CGPoint(x: 0, y: geo.size.height - 20))
                                    p.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - 20))
                                }
                                .stroke(neonCyan.opacity(0.3), lineWidth: 1.5)
                                
                                // Launch arrow
                                if !isLaunched {
                                    LaunchArrow(angle: angle, color: neonOrange, origin: CGPoint(x: 30, y: geo.size.height - 30))
                                }
                                
                                // Trail
                                if showTrail && trailPoints.count > 1 {
                                    Path { path in
                                        path.move(to: trailPoints[0])
                                        for pt in trailPoints.dropFirst() { path.addLine(to: pt) }
                                    }
                                    .stroke(neonCyan.opacity(0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                }
                                
                                // Projectile ball
                                if isLaunched {
                                    let scaleX = (geo.size.width - 60) / max(range, 1)
                                    let scaleY = (geo.size.height - 60) / max(maxHeight, 1)
                                    let px = 30 + projectileX * scaleX
                                    let py = geo.size.height - 30 - projectileY * scaleY
                                    Circle()
                                        .fill(neonCyan)
                                        .frame(width: 16, height: 16)
                                        .shadow(color: neonCyan.opacity(0.6), radius: 8)
                                        .position(x: px, y: py)
                                }
                                
                                // User tap marker
                                if let tapX = userTapX {
                                    VStack(spacing: 0) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(neonOrange)
                                            .shadow(color: neonOrange.opacity(0.5), radius: 6)
                                        Rectangle()
                                            .fill(neonOrange.opacity(0.4))
                                            .frame(width: 2, height: 20)
                                    }
                                    .position(x: tapX, y: geo.size.height - 32)
                                }
                                
                                // Result markers
                                if showResult {
                                    let scaleX = (geo.size.width - 60) / max(range, 1)
                                    let actualLandX = 30 + range * scaleX
                                    
                                    // Actual landing
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.yellow)
                                        .shadow(color: Color.yellow.opacity(0.5), radius: 8)
                                        .position(x: actualLandX, y: geo.size.height - 30)
                                    
                                    Text("ACTUAL")
                                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                                        .foregroundColor(.yellow)
                                        .position(x: actualLandX, y: geo.size.height - 44)
                                }
                                
                                // Instruction overlay when waiting for tap
                                if !isLaunched && userTapX == nil && !showResult {
                                    Text("TAP THE GROUND WHERE YOU PREDICT LANDING →")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(neonCyan.opacity(0.5))
                                        .position(x: geo.size.width / 2, y: geo.size.height - 10)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { location in
                                if !isLaunched && !showResult {
                                    userTapX = location.x
                                    canvasWidth = geo.size.width
                                    canvasHeight = geo.size.height
                                }
                            }
                            .onAppear { canvasWidth = geo.size.width; canvasHeight = geo.size.height }
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(neonCyan.opacity(0.2), lineWidth: 1))
                        
                        // Launch button
                        if !showResult {
                            Button(action: launchProjectile) {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .font(.system(size: 22))
                                    Text(userTapX == nil ? "TAP CANVAS FIRST" : (isLaunched ? "LAUNCHING..." : "LAUNCH!"))
                                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(userTapX == nil ? Color.gray : (isLaunched ? Color.orange : neonGreen))
                                .cornerRadius(14)
                                .shadow(color: neonGreen.opacity(0.3), radius: 10)
                            }
                            .disabled(userTapX == nil || isLaunched)
                        }
                        
                        // Result
                        if showResult {
                            LandingResultView(
                                accuracy: hitAccuracy,
                                range: range,
                                onNext: nextLevel,
                                onRetry: resetLevel
                            )
                        }
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(16)
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
            DispatchQueue.main.async {
                elapsedTime = te
                projectileX = newX
                projectileY = newY
                trailPoints.append(CGPoint(x: px, y: py))
                if shouldStop {
                    landingX = 30 + capturedRange * scaleX
                    calculateHitAccuracy()
                    isLaunched = false
                    showResult = true
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

@MainActor
@available(iOS 16.0, *)
struct LaunchArrow: View {
    let angle: Double
    let color: Color
    let origin: CGPoint
    
    var body: some View {
        let length = 40.0
        let rad = angle * .pi / 180
        let endX = origin.x + length * cos(rad)
        let endY = origin.y - length * sin(rad)
        
        return ZStack {
            Path { p in
                p.move(to: origin)
                p.addLine(to: CGPoint(x: endX, y: endY))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            
            Image(systemName: "arrowtriangle.up.fill")
                .font(.system(size: 10))
                .foregroundColor(color)
                .rotationEffect(.degrees(-(angle - 90)))
                .position(x: endX, y: endY)
        }
    }
}

@MainActor
@available(iOS 16.0, *)
struct PhysicsDataCell: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

@MainActor
@available(iOS 16.0, *)
struct LandingResultView: View {
    let accuracy: Double
    let range: Double
    let onNext: () -> Void
    let onRetry: () -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var grade: String {
        if accuracy > 0.9 { return "PERFECT!" }
        else if accuracy > 0.7 { return "GREAT!" }
        else if accuracy > 0.5 { return "CLOSE!" }
        else { return "MISS!" }
    }
    
    var body: some View {
        VStack(spacing: 14) {
            Text(grade)
                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                .foregroundColor(accuracy > 0.5 ? neonCyan : .red)
            
            Text(String(format: "Accuracy: %.0f%%  |  Actual Range: %.1f m", accuracy * 100, range))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button(action: onRetry) {
                    Label("RETRY", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.gray).cornerRadius(10)
                }
                Button(action: onNext) {
                    Label("NEXT LEVEL", systemImage: "chevron.right.2")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(neonCyan).cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(neonCyan.opacity(0.15), lineWidth: 0.5))
    }
}
#endif
