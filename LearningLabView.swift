#if os(iOS)
import SwiftUI

@available(iOS 16.0, *)
struct LearningLabView: View {
    @StateObject private var challengeManager = ChallengeManager()
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
                // Background: Blueprint Grid
                Color.black.ignoresSafeArea()
                
                GeometryReader { geo in
                    ZStack {
                        // Moving grid lines for flair
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
                
                VStack {
                    // Header
                    HStack {
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(neonCyan)
                            .font(.system(size: 24, weight: .bold))
                        
                        Spacer()
                        
                        Text("LEARNING LAB")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "info.circle")
                                .foregroundColor(neonCyan)
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    
                    // Challenge Selection
                    ChallengeSelectionView(challengeManager: challengeManager)
                    
                    // Current Challenge Display
                    CurrentChallengeView(challenge: challengeManager.currentChallenge, challengeManager: challengeManager)
                    
                    // Performance Metrics
                    PerformanceMetricsView(challengeManager: challengeManager)
                    
                    Spacer()
                }
                .padding(.top, 10)
            }
        .preferredColorScheme(.dark)
    }
}

@available(iOS 16.0, *)
struct ChallengeSelectionView: View {
    @ObservedObject var challengeManager: ChallengeManager
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 12) {
            Text("CHALLENGE SELECT")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ChallengeType.allCases, id: \.self) { type in
                        ChallengeButtonView(
                            type: type,
                            isSelected: challengeManager.selectedChallengeType == type,
                            action: { challengeManager.selectChallenge(type) }
                        )
                    }
                }
                .padding(.horizontal, 16)
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
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? neonCyan : .gray)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.black.opacity(0.6) : Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? neonCyan : Color.white.opacity(0.1), lineWidth: isSelected ? 1.5 : 0.5)
            )
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

// MARK: - Challenge Models and Manager

@available(iOS 16.0, *)
enum ChallengeType: String, CaseIterable {
    case matchTrajectory = "Match Trajectory"
    case optimizeVelocity = "Optimize Velocity"
    case stabilizeOscillation = "Stabilize Oscillation"
    case predictLanding = "Predict Landing Point"
    
    var icon: String {
        switch self {
        case .matchTrajectory: return "location.fill.viewfinder"
        case .optimizeVelocity: return "speedometer"
        case .stabilizeOscillation: return "waveform.path.ecg"
        case .predictLanding: return "location.magnifyingglass"
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
        
        // Create a new challenge based on the type
        switch type {
        case .matchTrajectory:
            currentChallenge = Challenge(
                type: type,
                title: "MATCH THE TRAJECTORY",
                description: "Follow the target path as closely as possible using proper kinematic motion",
                targetValue: 1.0
            )
        case .optimizeVelocity:
            currentChallenge = Challenge(
                type: type,
                title: "OPTIMIZE VELOCITY",
                description: "Achieve the target velocity with minimal deviation",
                targetValue: 2.5
            )
        case .stabilizeOscillation:
            currentChallenge = Challenge(
                type: type,
                title: "STABILIZE OSCILLATION",
                description: "Minimize oscillation to achieve steady-state motion",
                targetValue: 0.1
            )
        case .predictLanding:
            currentChallenge = Challenge(
                type: type,
                title: "PREDICT LANDING POINT",
                description: "Calculate and reach the predicted landing point",
                targetValue: 5.0
            )
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
        
        // Simulate progress updates based on the challenge type
        
        switch challenge.type {
        case .matchTrajectory:
            // Simulate following a trajectory
            challenge.currentValue = min(challenge.currentValue + Float.random(in: 0.01...0.03), challenge.targetValue)
            challenge.progress = min(challenge.currentValue / challenge.targetValue, 1.0)
            
        case .optimizeVelocity:
            // Simulate approaching target velocity
            let targetVel = challenge.targetValue
            let diff = targetVel - challenge.currentValue
            challenge.currentValue += diff * 0.05 // Approach target gradually
            challenge.progress = min(abs(challenge.currentValue - targetVel) / targetVel, 1.0)
            
        case .stabilizeOscillation:
            // Simulate reducing oscillation
            challenge.currentValue = max(challenge.currentValue - Float.random(in: 0.001...0.005), 0.0)
            challenge.progress = 1.0 - min(challenge.currentValue / challenge.targetValue, 1.0)
            
        case .predictLanding:
            // Simulate approaching landing prediction
            challenge.currentValue = min(challenge.currentValue + Float.random(in: 0.02...0.05), challenge.targetValue)
            challenge.progress = min(challenge.currentValue / challenge.targetValue, 1.0)
        }
        
        // Update performance metrics
        updatePerformanceMetrics()
        
        // Check if challenge is completed
        challenge.isCompleted = challenge.progress >= 1.0
        currentChallenge = challenge
    }
    
    private func updatePerformanceMetrics() {
        // Update performance metrics based on current challenge progress
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
