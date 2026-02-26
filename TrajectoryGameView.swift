#if os(iOS)
import SwiftUI

// MARK: - Real-World Trajectory Launcher Game

@MainActor
struct TrajectoryGameView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var score: Int
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    private let neonGreen = Color(red: 0.2, green: 1, blue: 0.4)
    private let neonOrange = Color(red: 1, green: 0.6, blue: 0.1)
    private let groundColor = Color(red: 0.15, green: 0.25, blue: 0.1)
    private let skyGradient = [Color(red: 0.02, green: 0.04, blue: 0.12), Color(red: 0.05, green: 0.12, blue: 0.22)]
    
    @State private var userVelocity: Double = 20.0
    @State private var userAngle: Double = 45.0
    @State private var level = 1
    @State private var totalScore = 0
    @State private var streak = 0
    @State private var showHint = false
    @State private var launched = false
    @State private var showResult = false
    @State private var accuracy: Double = 0.0
    @State private var animationProgress: Double = 0.0
    @State private var canvasSize: CGSize = .zero
    @State private var showCalcBox = true
    @State private var showBadgeOverlay = false
    @State private var thinkingLog: [String] = ["SYS_READY", "TARGET_LOCKED"]
    
    // Level scenarios
    private var scenario: TrajectoryScenario {
        TrajectoryScenario.forLevel(level)
    }
    
    // Physics
    private let g = 9.81
    
    private var flightTime: Double { 2.0 * userVelocity * sin(userAngle * .pi / 180.0) / g }
    private var rangeCalc: Double { userVelocity * userVelocity * sin(2.0 * userAngle * .pi / 180.0) / g }
    private var maxHeight: Double { userVelocity * userVelocity * pow(sin(userAngle * .pi / 180.0), 2) / (2.0 * g) }
    
    // Target position
    private var targetX: Double { scenario.targetDistance }
    
    // Step calculations
    private var calcSteps: [CalcStep] {
        let angleRad = userAngle * .pi / 180.0
        return [
            CalcStep(label: "θ (rad)", formula: "\(String(format: "%.1f", userAngle))° × π/180", result: String(format: "%.3f", angleRad)),
            CalcStep(label: "Vx", formula: "V₀ × cos(θ)", result: String(format: "%.2f", userVelocity * cos(angleRad)) + " m/s"),
            CalcStep(label: "Vy", formula: "V₀ × sin(θ)", result: String(format: "%.2f", userVelocity * sin(angleRad)) + " m/s"),
            CalcStep(label: "T flight", formula: "2·Vy / g", result: String(format: "%.2f", flightTime) + " s"),
            CalcStep(label: "H max", formula: "Vy² / (2g)", result: String(format: "%.2f", maxHeight) + " m"),
            CalcStep(label: "Range", formula: "V₀²·sin(2θ)/g", result: String(format: "%.2f", rangeCalc) + " m"),
        ]
    }
    
    var body: some View {
        ZStack {
            // Sky background
            LinearGradient(colors: skyGradient, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                GameHeader(
                    title: scenario.title,
                    icon: scenario.icon,
                    level: level,
                    score: totalScore,
                    streak: streak,
                    onDismiss: { dismiss() },
                    onHint: { withAnimation { showHint.toggle() } }
                )
                
                if showHint {
                    FormulaCard(lines: [
                        "y = x·tan(θ) - (g·x²) / (2·v₀²·cos²(θ))",
                        "R = (v₀²·sin(2θ)) / g",
                        "H = (v₀·sinθ)² / (2g)"
                    ], note: scenario.hint)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.horizontal, 16)
                }
                
                // Main game canvas + calc box
                GeometryReader { geo in
                    let size = geo.size
                    let groundY = size.height * 0.72
                    let launcherX: CGFloat = 40
                    
                    ZStack {
                        // --- WORLD SCENE ---
                        // Ground
                        Rectangle()
                            .fill(LinearGradient(colors: [groundColor, groundColor.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                            .frame(height: size.height * 0.28)
                            .offset(y: groundY - size.height * 0.5 + size.height * 0.14)
                        
                        // Ground grid lines
                        ForEach(0..<12) { i in
                            let xPos = CGFloat(i) * size.width / 11
                            Path { p in
                                p.move(to: CGPoint(x: xPos, y: groundY))
                                p.addLine(to: CGPoint(x: xPos, y: size.height))
                            }
                            .stroke(neonCyan.opacity(0.08), lineWidth: 0.5)
                        }
                        
                        // Distance markers on ground
                        ForEach(0..<6) { i in
                            let dist = Double(i) * 20.0
                            let xPos = launcherX + CGFloat(dist / maxDisplayRange * Double(size.width - 80))
                            VStack(spacing: 2) {
                                Rectangle().fill(neonCyan.opacity(0.3)).frame(width: 1, height: 8)
                                Text("\(Int(dist))m")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundColor(neonCyan.opacity(0.5))
                            }
                            .position(x: xPos, y: groundY + 12)
                        }
                        
                        // Scenario decoration (landscape elements)
                        scenarioDecorations(size: size, groundY: groundY, launcherX: launcherX)
                        
                        // Target zone
                        let targetScreenX = launcherX + CGFloat(targetX / maxDisplayRange * Double(size.width - 80))
                        ZStack {
                            // Target highlight
                            RoundedRectangle(cornerRadius: 4)
                                .fill(neonOrange.opacity(0.15))
                                .frame(width: 30, height: groundY)
                                .position(x: targetScreenX, y: groundY / 2)
                            
                            // Target marker
                            VStack(spacing: 2) {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(neonOrange)
                                Text("TARGET")
                                    .font(.system(size: 7, weight: .black, design: .monospaced))
                                    .foregroundColor(neonOrange)
                                Text("\(Int(targetX))m")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(neonOrange)
                            }
                            .position(x: targetScreenX, y: groundY - 28)
                            
                            // Target base
                            Rectangle()
                                .fill(neonOrange)
                                .frame(width: 4, height: 24)
                                .position(x: targetScreenX, y: groundY - 12)
                        }
                        
                        // Launcher
                        ZStack {
                            // Launcher base
                            Circle()
                                .fill(Color.gray.opacity(0.6))
                                .frame(width: 18, height: 18)
                            
                            // Launcher barrel (rotates with angle)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(neonCyan)
                                .frame(width: 28, height: 6)
                                .offset(x: 14)
                                .rotationEffect(.degrees(-userAngle))
                                .shadow(color: neonCyan, radius: 4)
                            
                            // Launcher icon
                            Image(systemName: scenario.launcherIcon)
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        }
                        .position(x: launcherX, y: groundY - 10)
                        
                        // --- TRAJECTORY PATH ---
                        if launched {
                            trajectoryPath(size: size, groundY: groundY, launcherX: launcherX)
                        }
                        
                        // Peak height marker (when launched)
                        if launched && maxHeight > 0 {
                            let peakScreenY = groundY - CGFloat(maxHeight / maxDisplayHeight * Double(groundY * 0.8))
                            let peakScreenX = launcherX + CGFloat((rangeCalc / 2.0) / maxDisplayRange * Double(size.width - 80))
                            VStack(spacing: 2) {
                                Text("\(String(format: "%.1f", maxHeight))m")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(neonGreen)
                                Image(systemName: "arrowtriangle.down.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(neonGreen)
                            }
                            .position(x: min(peakScreenX, size.width - 30), y: max(peakScreenY - 14, 20))
                            .opacity(animationProgress > 0.4 ? 1 : 0)
                        }
                        
                        // --- STEP CALCULATION BOX (top right) ---
                        if showCalcBox {
                            StepCalcBox(steps: calcSteps, rangeCalc: rangeCalc, targetX: targetX)
                                .frame(width: 170)
                                .position(x: size.width - 95, y: 90)
                        }
                        
                        // Result overlay
                        if showResult {
                            ResultOverlay(accuracy: accuracy, onNext: nextLevel, onRetry: retry)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .onAppear { canvasSize = size }
                }
                
                // --- CONTROLS PANEL ---
                controlsPanel
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showBadgeOverlay) {
            BadgeEarnedOverlay(badgeName: "Trajectory Master") {
                showBadgeOverlay = false
                level = 1
                retry()
            }
        }
    }
    
    // MARK: - Max display helpers
    private var maxDisplayRange: Double { max(120, targetX * 1.5) }
    private var maxDisplayHeight: Double { max(40, maxHeight * 1.5) }
    
    // MARK: - Trajectory Path Drawing
    @ViewBuilder
    private func trajectoryPath(size: CGSize, groundY: CGFloat, launcherX: CGFloat) -> some View {
        let angleRad = userAngle * .pi / 180.0
        let totalT = flightTime
        let steps = 60
        
        Path { path in
            var first = true
            for i in 0...steps {
                let frac = Double(i) / Double(steps)
                if frac > animationProgress { break }
                let t = frac * totalT
                let x = userVelocity * cos(angleRad) * t
                let y = userVelocity * sin(angleRad) * t - 0.5 * g * t * t
                
                let screenX = launcherX + CGFloat(x / maxDisplayRange * Double(size.width - 80))
                let screenY = groundY - CGFloat(y / maxDisplayHeight * Double(groundY * 0.8))
                
                if y < 0 && t > 0.1 { break }
                if first { path.move(to: CGPoint(x: screenX, y: screenY)); first = false }
                else { path.addLine(to: CGPoint(x: screenX, y: screenY)) }
            }
        }
        .stroke(
            LinearGradient(colors: [neonCyan, .blue, neonCyan.opacity(0.3)], startPoint: .leading, endPoint: .trailing),
            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
        )
        .shadow(color: neonCyan.opacity(0.6), radius: 8)
        
        // Projectile dot
        if animationProgress < 1.0 {
            let t = animationProgress * totalT
            let x = userVelocity * cos(angleRad) * t
            let y = userVelocity * sin(angleRad) * t - 0.5 * g * t * t
            let screenX = launcherX + CGFloat(x / maxDisplayRange * Double(size.width - 80))
            let screenY = groundY - CGFloat(max(0, y) / maxDisplayHeight * Double(groundY * 0.8))
            
            ZStack {
                Circle().fill(neonCyan.opacity(0.3)).frame(width: 16, height: 16)
                Circle().fill(neonCyan).frame(width: 8, height: 8)
                Image(systemName: scenario.projectileIcon)
                    .font(.system(size: 6))
                    .foregroundColor(.black)
            }
            .position(x: screenX, y: screenY)
        }
    }
    
    // MARK: - Scenario Decorations
    @ViewBuilder
    private func scenarioDecorations(size: CGSize, groundY: CGFloat, launcherX: CGFloat) -> some View {
        // Scenario description tag
        VStack(spacing: 2) {
            Text(scenario.sceneName)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(neonCyan)
            Text(scenario.description)
                .font(.system(size: 7, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(6)
        .background(Color.black.opacity(0.6))
        .cornerRadius(6)
        .position(x: size.width / 2, y: 14)
        
        // Clouds/stars
        ForEach(0..<5) { i in
            Image(systemName: level % 3 == 0 ? "star.fill" : "cloud.fill")
                .font(.system(size: CGFloat(6 + i * 2)))
                .foregroundColor(.white.opacity(Double(5 - i) * 0.04))
                .position(x: CGFloat(50 + i * 70), y: CGFloat(30 + i * 15))
        }
        
        // Terrain bumps
        ForEach(0..<4) { i in
            let bX = launcherX + CGFloat(30 + i * 60)
            Ellipse()
                .fill(groundColor.opacity(0.4))
                .frame(width: CGFloat(20 + i * 10), height: 6)
                .position(x: bX, y: groundY + 2)
        }
    }
    
    // MARK: - Controls Panel
    private var controlsPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                // Velocity control
                VStack(spacing: 4) {
                    HStack {
                        Text("V₀")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        Spacer()
                        Text("\(String(format: "%.1f", userVelocity)) m/s")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Slider(value: $userVelocity, in: scenario.velocityRange, step: 0.5)
                        .accentColor(neonCyan)
                        .disabled(launched)
                }
                
                // Angle control
                VStack(spacing: 4) {
                    HStack {
                        Text("θ")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(neonOrange)
                        Spacer()
                        Text("\(String(format: "%.1f", userAngle))°")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    Slider(value: $userAngle, in: 5...85, step: 0.5)
                        .accentColor(neonOrange)
                        .disabled(launched)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: { showCalcBox.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: showCalcBox ? "eye.slash" : "eye")
                            .font(.system(size: 10))
                        Text(showCalcBox ? "HIDE CALC" : "SHOW CALC")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                if launched {
                    Button(action: retry) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10))
                            Text("RESET")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                } else {
                    Button(action: launch) {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12))
                            Text("LAUNCH")
                                .font(.system(size: 12, weight: .black, design: .monospaced))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(neonCyan)
                        .cornerRadius(12)
                        .shadow(color: neonCyan.opacity(0.4), radius: 10)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.9))
    }
    
    // MARK: - Game Logic
    private func launch() {
        launched = true
        animationProgress = 0
        
        // Animate the projectile flight
        withAnimation(.easeInOut(duration: max(1.0, flightTime * 0.6))) {
            animationProgress = 1.0
        }
        
        // After animation, calculate accuracy
        DispatchQueue.main.asyncAfter(deadline: .now() + max(1.2, flightTime * 0.6 + 0.3)) {
            calculateAccuracy()
        }
    }
    
    private func calculateAccuracy() {
        let error = abs(rangeCalc - targetX)
        let tolerancePercent = targetX * 0.15 // 15% tolerance zone
        accuracy = max(0, min(1.0, 1.0 - error / max(tolerancePercent, 1.0)))
        
        let pts = Int(accuracy * 100) * level
        totalScore += pts
        score = totalScore
        
        if accuracy > 0.6 { streak += 1 } else { streak = 0 }
        withAnimation(.spring()) { showResult = true }
    }
    
    private func nextLevel() {
        if level >= 10 {
            GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 0, badge: "Trajectory Master")
            showResult = false
            showBadgeOverlay = true
        } else {
            level += 1
            if level > 3 {
                GameProgressManager.shared.unlockNext(category: "Physics", currentIndex: 0, badge: "Trajectory Master")
            }
            retry()
        }
    }
    
    private func retry() {
        launched = false
        showResult = false
        accuracy = 0
        animationProgress = 0
        userVelocity = scenario.defaultVelocity
        userAngle = 45.0
    }
}

// MARK: - Step Calculation Box

struct StepCalcBox: View {
    let steps: [CalcStep]
    let rangeCalc: Double
    let targetX: Double
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "function").font(.system(size: 8)).foregroundColor(neonCyan)
                Text("STEP_CALC")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundColor(neonCyan)
                Spacer()
            }
            
            ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                HStack(spacing: 4) {
                    Text("\(idx + 1).")
                        .font(.system(size: 6, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(step.label)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(step.result)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                }
            }
            
            Rectangle().fill(neonCyan.opacity(0.2)).frame(height: 1)
            
            HStack {
                Text("HIT?")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                let diff = abs(rangeCalc - targetX)
                Text(diff < targetX * 0.15 ? "✓ ON TARGET" : "✗ OFF BY \(String(format: "%.1f", diff))m")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(diff < targetX * 0.15 ? .green : .red)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.85))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(neonCyan.opacity(0.3), lineWidth: 1))
    }
}

struct CalcStep {
    let label: String
    let formula: String
    let result: String
}

// MARK: - Level Scenarios

struct TrajectoryScenario {
    let title: String
    let sceneName: String
    let description: String
    let icon: String
    let launcherIcon: String
    let projectileIcon: String
    let hint: String
    let targetDistance: Double
    let velocityRange: ClosedRange<Double>
    let defaultVelocity: Double
    
    static func forLevel(_ level: Int) -> TrajectoryScenario {
        switch level {
        case 1:
            return TrajectoryScenario(
                title: "CANNON_RANGE", sceneName: "🏰 CASTLE SIEGE", description: "Hit the enemy fort",
                icon: "scope", launcherIcon: "circle.fill", projectileIcon: "circle.fill",
                hint: "A castle cannon fires cannonballs. Find the right angle and speed to hit the fort.",
                targetDistance: 30, velocityRange: 10...40, defaultVelocity: 20)
        case 2:
            return TrajectoryScenario(
                title: "BASKETBALL_SHOT", sceneName: "🏀 COURT SHOT", description: "Score the basket",
                icon: "sportscourt", launcherIcon: "figure.basketball", projectileIcon: "circle.fill",
                hint: "Launch the basketball at the right angle to reach the hoop 7m away.",
                targetDistance: 7, velocityRange: 5...20, defaultVelocity: 10)
        case 3:
            return TrajectoryScenario(
                title: "ROCKET_LAUNCH", sceneName: "🚀 ROCKET TEST", description: "Reach the landing pad",
                icon: "airplane", launcherIcon: "bolt.fill", projectileIcon: "triangle.fill",
                hint: "Launch a test rocket to the landing pad. Account for higher velocity.",
                targetDistance: 60, velocityRange: 15...50, defaultVelocity: 30)
        case 4:
            return TrajectoryScenario(
                title: "FOOTBALL_KICK", sceneName: "⚽ PENALTY ARC", description: "Chip over the wall",
                icon: "figure.soccer", launcherIcon: "shoe.fill", projectileIcon: "circle.fill",
                hint: "Chip the football over the defensive wall and into the goal area.",
                targetDistance: 18, velocityRange: 8...30, defaultVelocity: 15)
        case 5:
            return TrajectoryScenario(
                title: "CATAPULT_STRIKE", sceneName: "🏗️ MEDIEVAL CATAPULT", description: "Demolish the tower",
                icon: "hammer.fill", launcherIcon: "triangle.fill", projectileIcon: "square.fill",
                hint: "The catapult hurls boulders. Calculate the trajectory to hit the tower.",
                targetDistance: 45, velocityRange: 15...45, defaultVelocity: 25)
        case 6:
            return TrajectoryScenario(
                title: "GOLF_DRIVE", sceneName: "⛳ GOLF RANGE", description: "Reach the green",
                icon: "figure.golf", launcherIcon: "circle.fill", projectileIcon: "circle.fill",
                hint: "Drive the golf ball to the green. Precision over power!",
                targetDistance: 55, velocityRange: 20...50, defaultVelocity: 30)
        case 7:
            return TrajectoryScenario(
                title: "ARCHERY_ARC", sceneName: "🏹 ARCHERY FIELD", description: "Hit the bullseye",
                icon: "target", launcherIcon: "arrowtriangle.right.fill", projectileIcon: "arrowtriangle.right.fill",
                hint: "Arrows have lower mass. Angle is critical at close range.",
                targetDistance: 25, velocityRange: 10...35, defaultVelocity: 18)
        case 8:
            return TrajectoryScenario(
                title: "MORTAR_STRIKE", sceneName: "💣 MORTAR RANGE", description: "Hit the bunker",
                icon: "scope", launcherIcon: "circle.fill", projectileIcon: "circle.fill",
                hint: "Mortars use high angles. Try above 60° for short-range lobs.",
                targetDistance: 15, velocityRange: 8...25, defaultVelocity: 14)
        case 9:
            return TrajectoryScenario(
                title: "WATER_BALLOON", sceneName: "💧 WATER FIGHT", description: "Splash the target",
                icon: "drop.fill", launcherIcon: "circle.fill", projectileIcon: "drop.fill",
                hint: "Water balloons are slow. Use a steep angle for accuracy.",
                targetDistance: 12, velocityRange: 5...20, defaultVelocity: 10)
        default:
            return TrajectoryScenario(
                title: "ARTILLERY_CALC", sceneName: "🎯 PRECISION STRIKE", description: "Long-range artillery",
                icon: "scope", launcherIcon: "bolt.fill", projectileIcon: "triangle.fill",
                hint: "Long-range requires precise velocity and angle tuning.",
                targetDistance: 80, velocityRange: 20...60, defaultVelocity: 35)
        }
    }
}

#endif
