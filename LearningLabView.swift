import SwiftUI

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
            Color.black.ignoresSafeArea()
            
            // Dynamic Grid Background
            GeometryReader { geo in
                GridBackground(color: neonCyan, size: geo.size)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Lab Header
                LabHeaderView(totalScore: totalGameScore)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Challenge Selection
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
                        
                        // Main Dashboard Section
                        VStack(spacing: 20) {
                            CurrentChallengeView(challenge: challengeManager.currentChallenge, challengeManager: challengeManager)
                            
                            PerformanceMetricsView(challengeManager: challengeManager)
                            
                            PhysicsInsightView(challengeManager: challengeManager)
                        }
                        .padding(.horizontal, 16)
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showTrajectoryGame) { TrajectoryGameView(score: $trajectoryScore) }
        .fullScreenCover(isPresented: $showVelocityGame) { VelocityGameView(score: $velocityScore) }
        .fullScreenCover(isPresented: $showOscillationGame) { OscillationGameView(score: $oscillationScore) }
        .fullScreenCover(isPresented: $showLandingGame) { LandingGameView(score: $landingScore) }
        .fullScreenCover(isPresented: $showMomentumGame) { MomentumGameView(score: $momentumScore) }
        .fullScreenCover(isPresented: $showCollisionGame) { CollisionGameView(score: $collisionScore) }
        .fullScreenCover(isPresented: $showCentripetalGame) { CentripetalGameView(score: $centripetalScore) }
        .fullScreenCover(isPresented: $showEnergyGame) { EnergyGameView(score: $energyScore) }
    }
}

struct LabHeaderView: View {
    let totalScore: Int
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LEARNING_LAB_v4.0")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                    Text("KINEMATIC_SIMULATION_HUB")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("EXP_EARNED")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("\(totalScore)")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(neonCyan)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(neonCyan.opacity(0.2), lineWidth: 1))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            
            Rectangle()
                .fill(LinearGradient(colors: [neonCyan.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
        }
        .background(Color.black.opacity(0.85))
    }
}

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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("AVAILABLE_SIMULATIONS")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("SCANNING...")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(ChallengeType.allCases, id: \.self) { type in
                        ChallengeCardView(
                            type: type,
                            isSelected: challengeManager.selectedChallengeType == type,
                            action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    challengeManager.selectChallenge(type)
                                    handleSelection(type)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
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

struct ChallengeCardView: View {
    let type: ChallengeType
    let isSelected: Bool
    let action: () -> Void
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? neonCyan : Color.white.opacity(0.05))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isSelected ? .black : .white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue.uppercased())
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(isSelected ? neonCyan : .white)
                    Text("PROB_SIM_LVL_\(Int.random(in: 1...5))")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack {
                    Text("ENGAGE_LINK")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(isSelected ? .black : neonCyan)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(isSelected ? .black : neonCyan)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(isSelected ? neonCyan : neonCyan.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(14)
            .frame(width: 140, height: 160)
            .background(
                ZStack {
                    Color.black.opacity(0.6)
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(neonCyan, lineWidth: 2)
                            .shadow(color: neonCyan.opacity(0.3), radius: 10)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
                }
            )
            .cornerRadius(20)
        }
    }
}

struct CurrentChallengeView: View {
    var challenge: Challenge?
    @ObservedObject var challengeManager: ChallengeManager
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("SELECTED_EXP_DATA")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                if challenge != nil {
                    Text("ACTIVE_SIM")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(neonCyan.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(16)
            
            if let challenge = challenge {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text(challenge.title)
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text(challenge.description)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Stats Cluster
                    HStack(spacing: 20) {
                        ChallengeValueBox(label: "INIT_TARGET", value: challenge.targetValue.formattedChallengeValue, color: .gray)
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.05), lineWidth: 6)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(challenge.progress))
                                .stroke(
                                    AngularGradient(colors: [neonCyan, .blue, neonCyan], center: .center),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: 0) {
                                Text("\(Int(challenge.progress * 100))")
                                    .font(.system(size: 24, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("%")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        ChallengeValueBox(label: "LIVE_READOUT", value: challenge.currentValue.formattedChallengeValue, color: neonCyan)
                    }
                    .padding(.horizontal, 24)
                    
                    // Control
                    Button(action: {
                        withAnimation(.spring()) {
                            if challengeManager.isRunning {
                                challengeManager.pauseChallenge()
                            } else {
                                challengeManager.startChallenge()
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: challengeManager.isRunning ? "pause.fill" : "play.fill")
                            Text(challengeManager.isRunning ? "SUSPEND_CALCULATION" : "INITIALIZE_CORE_STREAM")
                        }
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(challengeManager.isRunning ? Color.orange : neonCyan)
                        .cornerRadius(12)
                        .shadow(color: (challengeManager.isRunning ? Color.orange : neonCyan).opacity(0.3), radius: 10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "cpu")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.1))
                    Text("AWAITING_SIMULATION_LINK")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.2))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct ChallengeValueBox: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

struct PerformanceMetricsView: View {
    @ObservedObject var challengeManager: ChallengeManager
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BIOMETRIC_FEEDBACK_ANALYSIS")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricCard(title: "ACCURACY", value: challengeManager.performanceMetrics.accuracy, icon: "target", color: .green)
                MetricCard(title: "SMOOTHNESS", value: challengeManager.performanceMetrics.smoothness, icon: "figure.walk.motion", color: .blue)
                MetricCard(title: "EFFICIENCY", value: challengeManager.performanceMetrics.efficiency, icon: "bolt.fill", color: .yellow)
                MetricCard(title: "STABILITY", value: challengeManager.performanceMetrics.stability, icon: "balance", color: .purple)
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: Float
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 3)
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: CGFloat(value) * 60, height: 3) // Hardcoded width for grid item
                    .shadow(color: color.opacity(0.4), radius: 2)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.03))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

struct PhysicsInsightView: View {
    @ObservedObject var challengeManager: ChallengeManager
    @State private var displayedText: String = ""
    @State private var typingTask: Task<Void, Never>?
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                    .font(.system(size: 14))
                Text("NEURAL_PHYSICS_ADVISOR")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(neonCyan)
                Spacer()
                Circle()
                    .fill(neonCyan)
                    .frame(width: 4, height: 4)
                    .opacity(challengeManager.isRunning ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: challengeManager.isRunning)
            }
            
            Text(displayedText)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .onChange(of: challengeManager.selectedChallengeType) { _ in
                    startTyping()
                }
        }
        .padding(20)
        .background(
            ZStack {
                Color.blue.opacity(0.05)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(neonCyan.opacity(0.2), lineWidth: 1)
            }
        )
        .onAppear {
            startTyping()
        }
    }
    
    private func startTyping() {
        typingTask?.cancel()
        displayedText = ""
        let fullText = currentInsight
        
        typingTask = Task {
            for char in fullText {
                if Task.isCancelled { break }
                displayedText.append(char)
                try? await Task.sleep(nanoseconds: 15_000_000) // 0.015s
            }
        }
    }
    
    private var currentInsight: String {
        guard let type = challengeManager.selectedChallengeType else {
            return "AWAITING_SIMULATION_LINK. SELECT A CHALLENGE TO RECEIVE EXPERT KINEMATIC INSIGHTS."
        }
        switch type {
        case .matchTrajectory: return "> Projectiles follow a parabolic trajectory because gravity only acts vertically. Horizontal velocity remains constant (negligible drag)."
        case .optimizeVelocity: return "> Velocity is a vector. To optimize efficiency, maintain a constant kinetic link. Rapid acceleration spikes waste electrical energy."
        case .stabilizeOscillation: return "> Damping coefficient (b) must be tuned to critical levels (ζ = 1) to eliminate oscillation without causing sluggish response times."
        case .landingPrediction: return "> Calculating impact coordinates requires integrating instantaneous acceleration. Note: Air density fluctuations may introduce 2-5% error margin."
        case .momentumTransfer: return "> Momentum (p) is conserved. Impulse (J) is the integral of force over time. Aim for a high-impulse impact for maximum energy transfer."
        case .elasticCollision: return "> In perfectly elastic collisions, kinetic energy is preserved. Watch for the coefficient of restitution; inelasticity causes thermal dissipation."
        case .centripetalForce: return "> Centripetal acceleration (a = v²/r) is always normal to the velocity vector. Increasing velocity requires exponential force increases to stay in orbit."
        case .kineticEnergy: return "> Observe the non-linear relationship: doubling your velocity requires four times the energy output. Efficiency is found in steady-state motion."
        }
    }
}

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

struct PerformanceMetrics {
    var accuracy: Float = 0.0
    var smoothness: Float = 0.0
    var efficiency: Float = 0.0
    var stability: Float = 0.0
}

@MainActor
class ChallengeManager: ObservableObject {
    @Published var selectedChallengeType: ChallengeType?
    @Published var currentChallenge: Challenge?
    @Published var isRunning = false
    @Published var performanceMetrics = PerformanceMetrics()
    
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
        Task { @MainActor in
            while isRunning {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                guard !Task.isCancelled && isRunning else { break }
                self.updateChallengeProgress()
            }
        }
    }
    
    private func stopTimer() {
        // Task loop handles cancellation via isRunning check
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

