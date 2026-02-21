#if os(iOS)
import SwiftUI

@available(iOS 16.0, *)
struct LearningLabView: View {
    @StateObject private var challengeManager = ChallengeManager()
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    // Game sheet states
    @State private var showTrajectoryGame = false
    @State private var showVelocityGame = false
    @State private var showOscillationGame = false
    @State private var showLandingGame = false
    @State private var showMomentumGame = false
    @State private var showCollisionGame = false
    @State private var showCentripetalGame = false
    @State private var showEnergyGame = false

    @State private var trajectoryScore = 0
    @State private var velocityScore = 0
    @State private var oscillationScore = 0
    @State private var landingScore = 0
    @State private var momentumScore = 0
    @State private var collisionScore = 0
    @State private var centripetalScore = 0
    @State private var energyScore = 0
    
    private var totalGameScore: Int { 
        trajectoryScore + velocityScore + oscillationScore + landingScore + 
        momentumScore + collisionScore + centripetalScore + energyScore 
    }
    
    var body: some View {
        ZStack {
                // Background: Blueprint Grid
                Color.black.ignoresSafeArea()
                
                GeometryReader { geo in
                    ZStack {
                        ForEach(0..<10) { i in
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: geo.size.height / 10 * CGFloat(i)))
                                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 10 * CGFloat(i)))
                            }
                            .stroke(neonCyan.opacity(0.1), lineWidth: 0.5)
                        }
                    }
                }
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Removed redundant header to fix "nonsense" layout overlap
                    
                    // Challenge Selection — each button opens its game
                    ChallengeSelectionView(
                        challengeManager: challengeManager,
                        onSelectTrajectory: { showTrajectoryGame = true },
                        onSelectVelocity: { showVelocityGame = true },
                        onSelectOscillation: { showOscillationGame = true },
                        onSelectLanding: { showLandingGame = true },
                        onSelectMomentum: { showMomentumGame = true },
                        onSelectCollision: { showCollisionGame = true },
                        onSelectCentripetal: { showCentripetalGame = true },
                        onSelectEnergy: { showEnergyGame = true }
                    )
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Current Challenge Display
                            CurrentChallengeView(challenge: challengeManager.currentChallenge, challengeManager: challengeManager)
                            
                            // Performance Metrics
                            PerformanceMetricsView(challengeManager: challengeManager)
                            
                            // Physics Insights Section
                            PhysicsInsightView(challengeManager: challengeManager)
                            
                            Spacer().frame(height: 80)
                        }
                    }
                }
            }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showTrajectoryGame) {
            TrajectoryGameView(score: $trajectoryScore)
        }
        .fullScreenCover(isPresented: $showVelocityGame) {
            VelocityGameView(score: $velocityScore)
        }
        .fullScreenCover(isPresented: $showOscillationGame) {
            OscillationGameView(score: $oscillationScore)
        }
        .fullScreenCover(isPresented: $showLandingGame) {
            LandingGameView(score: $landingScore)
        }
        .fullScreenCover(isPresented: $showMomentumGame) {
            MomentumGameView(score: $momentumScore)
        }
        .fullScreenCover(isPresented: $showCollisionGame) {
            CollisionGameView(score: $collisionScore)
        }
        .fullScreenCover(isPresented: $showCentripetalGame) {
            CentripetalGameView(score: $centripetalScore)
        }
        .fullScreenCover(isPresented: $showEnergyGame) {
            EnergyGameView(score: $energyScore)
        }
    }
}

@available(iOS 16.0, *)
struct ChallengeSelectionView: View {
    @ObservedObject var challengeManager: ChallengeManager
    let onSelectTrajectory: () -> Void
    let onSelectVelocity: () -> Void
    let onSelectOscillation: () -> Void
    let onSelectLanding: () -> Void
    let onSelectMomentum: () -> Void
    let onSelectCollision: () -> Void
    let onSelectCentripetal: () -> Void
    let onSelectEnergy: () -> Void
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            Text("TAP A CHALLENGE TO PLAY")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ChallengeType.allCases, id: \.self) { type in
                        ChallengeButtonView(
                            type: type,
                            isSelected: challengeManager.selectedChallengeType == type,
                            action: {
                                challengeManager.selectChallenge(type)
                                handleSelection(type)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 14)
        .background(
            ZStack {
                Color.black.opacity(0.6)
                // Decorative diagonal lines
                GeometryReader { geo in
                    Path { p in
                        for i in 0..<10 {
                            let x = CGFloat(i) * 50
                            p.move(to: CGPoint(x: x, y: 0))
                            p.addLine(to: CGPoint(x: x + 100, y: geo.size.height))
                        }
                    }
                    .stroke(neonCyan.opacity(0.05), lineWidth: 1)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(neonCyan.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    private func handleSelection(_ type: ChallengeType) {
        switch type {
        case .matchTrajectory: onSelectTrajectory()
        case .optimizeVelocity: onSelectVelocity()
        case .stabilizeOscillation: onSelectOscillation()
        case .landingPrediction: onSelectLanding()
        case .momentumTransfer: onSelectMomentum()
        case .elasticCollision: onSelectCollision()
        case .centripetalForce: onSelectCentripetal()
        case .kineticEnergy: onSelectEnergy()
        }
    }
}

@available(iOS 16.0, *)
struct ChallengeButtonView: View {
    let type: ChallengeType
    let isSelected: Bool
    let action: () -> Void
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? neonCyan : .gray)
                
                Text(type.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? neonCyan : .gray)
                    .multilineTextAlignment(.center)
                
                Text("▶ PLAY")
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundColor(isSelected ? .black : neonCyan.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isSelected ? neonCyan : neonCyan.opacity(0.1))
                    .cornerRadius(6)
            }
            .frame(width: 80, height: 88)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color(red: 0, green: 0.15, blue: 0.13) : Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? neonCyan : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 0.5)
            )
            .shadow(color: isSelected ? neonCyan.opacity(0.2) : .clear, radius: 8)
        }
    }
}

@available(iOS 16.0, *)
struct CurrentChallengeView: View {
    var challenge: Challenge?
    @ObservedObject var challengeManager: ChallengeManager
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            Text("CURRENT CHALLENGE")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            if let challenge = challenge {
                VStack(spacing: 16) {
                    Text(challenge.title)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                        .multilineTextAlignment(.center)
                    
                    Text(challenge.description)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    // Challenge objective display
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TARGET:")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Text(challenge.targetValue.formattedChallengeValue)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("CURRENT:")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            
                            Text(challenge.currentValue.formattedChallengeValue)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(challenge.isCompleted ? Color.green : neonCyan)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Progress indicator
                    VStack(spacing: 4) {
                        Text("PROGRESS: \(Int(challenge.progress * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        ProgressView(value: challenge.progress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle())
                            .accentColor(neonCyan)
                    }
                    .padding(.horizontal, 20)
                    
                    // Start/Pause button
                    Button(action: {
                        if challengeManager.isRunning {
                            challengeManager.pauseChallenge()
                        } else {
                            challengeManager.startChallenge()
                        }
                    }) {
                        Text(challengeManager.isRunning ? "PAUSE" : "START")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(neonCyan)
                            .cornerRadius(10)
                    }
                }
            } else {
                Text("SELECT A CHALLENGE")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 120)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(10)
            }
        }
        .padding(.vertical, 10)
        .background(
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark) {
                Rectangle().fill(Color.clear)
            }
            .opacity(0.85)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(neonCyan.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }
}

@available(iOS 16.0, *)
struct PerformanceMetricsView: View {
    @ObservedObject var challengeManager: ChallengeManager
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            Text("PERFORMANCE METRICS")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            HStack {
                MetricCard(
                    title: "ACCURACY",
                    value: "\(Int(challengeManager.performanceMetrics.accuracy * 100))%",
                    color: Color.green,
                    icon: "target"
                )
                
                MetricCard(
                    title: "SMOOTHNESS",
                    value: "\(Int(challengeManager.performanceMetrics.smoothness * 100))%",
                    color: Color.blue,
                    icon: "figure.walk.motion"
                )
            }
            
            HStack {
                MetricCard(
                    title: "EFFICIENCY",
                    value: "\(Int(challengeManager.performanceMetrics.efficiency * 100))%",
                    color: Color.yellow,
                    icon: "bolt.fill"
                )
                
                MetricCard(
                    title: "STABILITY",
                    value: "\(Int(challengeManager.performanceMetrics.stability * 100))%",
                    color: Color.purple,
                    icon: "balance"
                )
            }
        }
        .padding(.vertical, 10)
        .background(
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark) {
                Rectangle().fill(Color.clear)
            }
            .opacity(0.85)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(neonCyan.opacity(0.15), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
    }
}

@available(iOS 16.0, *)
struct MetricCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14))
                
                Spacer()
            }
            
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(12)
        .background(Color.black.opacity(0.4))
        .cornerRadius(10)
    }
}

@available(iOS 16.0, *)
struct PhysicsInsightView: View {
    @ObservedObject var challengeManager: ChallengeManager
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("PHYSICS INSIGHT")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
                Spacer()
            }
            
            Text(currentInsight)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .id(challengeManager.selectedChallengeType)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(neonCyan.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .animation(.spring(), value: challengeManager.selectedChallengeType)
    }
    
    private var currentInsight: String {
        guard let type = challengeManager.selectedChallengeType else {
            return "Select a challenge to receive expert physics insights and master the laws of motion."
        }
        switch type {
        case .matchTrajectory: return "Did you know? Projectiles follow a parabolic path because gravity only acts vertically, creating constant vertical acceleration while horizontal velocity remains constant."
        case .optimizeVelocity: return "Velocity is a vector quantity. To optimize, you must manage both magnitude (speed) and direction perfectly. Smooth transitions reduce energy loss."
        case .stabilizeOscillation: return "Damping is the process of reducing oscillation amplitude. In engineering, critical damping prevents overshoot and reaches equilibrium fastest."
        case .landingPrediction: return "Air resistance (drag) significantly affects long-range trajectories. For heavy objects, the impact of drag is lower relative to their inertia."
        case .momentumTransfer: return "Momentum (p = mv) is always conserved in a closed system. Impulse is the change in momentum caused by a force applied over time."
        case .elasticCollision: return "In a perfectly elastic collision, both momentum and kinetic energy are conserved. Real-world collisions are usually 'partially inelastic'."
        case .centripetalForce: return "Centripetal force is not a 'new' force, but a requirement for circular motion, provided by tension, gravity, or friction toward the center."
        case .kineticEnergy: return "Kinetic Energy increases with the square of velocity (KE = ½mv²). Doubling your speed quadruples the energy required!"
        }
    }
}

@available(iOS 16.0, *)
enum ChallengeType: String, CaseIterable {
    case matchTrajectory = "Match Trajectory"
    case optimizeVelocity = "Optimize Velocity"
    case stabilizeOscillation = "Stabilize Oscillation"
    case landingPrediction = "Predict Landing Point"
    case momentumTransfer = "Momentum Transfer"
    case elasticCollision = "Elastic Collision"
    case centripetalForce = "Centripetal Force"
    case kineticEnergy = "Kinetic Energy"
    
    var icon: String {
        switch self {
        case .matchTrajectory: return "location.fill.viewfinder"
        case .optimizeVelocity: return "speedometer"
        case .stabilizeOscillation: return "waveform.path.ecg"
        case .landingPrediction: return "location.magnifyingglass"
        case .momentumTransfer: return "arrow.right.to.line.compact"
        case .elasticCollision: return "arrow.up.and.down.and.sparkles"
        case .centripetalForce: return "rotate.right.fill"
        case .kineticEnergy: return "bolt.batteryblock.fill"
        }
    }
}

@available(iOS 16.0, *)
struct Challenge: Identifiable {
    let id = UUID()
    let type: ChallengeType
    let title: String
    let description: String
    let targetValue: Float
    var currentValue: Float = 0
    var progress: Float = 0
    var isCompleted: Bool = false
}

@available(iOS 16.0, *)
struct PerformanceMetrics {
    var accuracy: Float = 0.0
    var smoothness: Float = 0.0
    var efficiency: Float = 0.0
    var stability: Float = 0.0
}

@available(iOS 16.0, *)
@MainActor
class ChallengeManager: ObservableObject {
    @Published var selectedChallengeType: ChallengeType?
    @Published var currentChallenge: Challenge?
    @Published var isRunning = false
    @Published var performanceMetrics = PerformanceMetrics()
    
    private var timer: Timer?
    
    func selectChallenge(_ type: ChallengeType) {
        selectedChallengeType = type
        
        switch type {
        case .matchTrajectory:
            currentChallenge = Challenge(type: type, title: "MATCH THE TRAJECTORY", description: "Follow the target path as closely as possible using proper kinematic motion", targetValue: 1.0)
        case .optimizeVelocity:
            currentChallenge = Challenge(type: type, title: "OPTIMIZE VELOCITY", description: "Achieve the target velocity with minimal deviation", targetValue: 2.5)
        case .stabilizeOscillation:
            currentChallenge = Challenge(type: type, title: "STABILIZE OSCILLATION", description: "Minimize oscillation to achieve steady-state motion", targetValue: 0.1)
        case .landingPrediction:
            currentChallenge = Challenge(type: type, title: "PREDICT LANDING POINT", description: "Calculate and reach the predicted landing point", targetValue: 5.0)
        case .momentumTransfer:
            currentChallenge = Challenge(type: type, title: "MOMENTUM TRANSFER", description: "Calculate impulse needed for a perfect transfer of momentum", targetValue: 15.0)
        case .elasticCollision:
            currentChallenge = Challenge(type: type, title: "ELASTIC COLLISION", description: "Analyze energy conservation during a perfect elastic bounce", targetValue: 1.0)
        case .centripetalForce:
            currentChallenge = Challenge(type: type, title: "CENTRIPETAL FORCE", description: "Maintain constant acceleration toward the central pivot", targetValue: 9.8)
        case .kineticEnergy:
            currentChallenge = Challenge(type: type, title: "KINETIC ENERGY", description: "Maximize energy efficiency through velocity management", targetValue: 50.0)
        }
    }
    
    func startChallenge() {
        isRunning = true
        startTimer()
    }
    
    func pauseChallenge() {
        isRunning = false
        stopTimer()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateChallengeProgress()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateChallengeProgress() {
        guard var challenge = currentChallenge else { return }
        
        switch challenge.type {
        case .matchTrajectory, .landingPrediction, .momentumTransfer, .kineticEnergy:
            challenge.currentValue = min(challenge.currentValue + Float.random(in: 0.01...0.05), challenge.targetValue)
            challenge.progress = min(challenge.currentValue / challenge.targetValue, 1.0)
        case .optimizeVelocity, .centripetalForce:
            let target = challenge.targetValue
            let diff = target - challenge.currentValue
            challenge.currentValue += diff * 0.05
            challenge.progress = min(abs(challenge.currentValue - target) / target, 1.0)
        case .stabilizeOscillation, .elasticCollision:
            challenge.currentValue = max(challenge.currentValue - Float.random(in: 0.001...0.01), 0.0)
            challenge.progress = 1.0 - min(challenge.currentValue / challenge.targetValue, 1.0)
        }
        
        updatePerformanceMetrics()
        challenge.isCompleted = challenge.progress >= 0.99
        currentChallenge = challenge
    }
    
    private func updatePerformanceMetrics() {
        performanceMetrics.accuracy = min(performanceMetrics.accuracy + Float.random(in: 0.001...0.005), 1.0)
        performanceMetrics.smoothness = min(performanceMetrics.smoothness + Float.random(in: 0.001...0.005), 1.0)
        performanceMetrics.efficiency = min(performanceMetrics.efficiency + Float.random(in: 0.001...0.005), 1.0)
        performanceMetrics.stability = min(performanceMetrics.stability + Float.random(in: 0.001...0.005), 1.0)
    }
}

extension Float {
    var formattedChallengeValue: String {
        switch self {
        case let val where val < 10:
            return String(format: "%.2f", val)
        default:
            return String(format: "%.1f", self)
        }
    }
}
#endif
