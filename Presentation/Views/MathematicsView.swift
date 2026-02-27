import SwiftUI

struct MathematicsView: View {
    @StateObject private var mathManager = MathChallengeManager()
    
    // Game presentation states
    @State private var showLinearAlgebraGame = false
    @State private var showDiffCalculusGame = false
    @State private var showIntCalculusGame = false
    @State private var showDiffEqGame = false
    @State private var showDiscreteMathGame = false
    @State private var showVectorCalculusGame = false
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                GridBackground(color: neonCyan, size: geo.size)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("MATH_LAB_v1.0")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan)
                            Text("ADVANCED_MATH_HUB")
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("ACTIVE_FORMULA")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(mathManager.currentChallenge?.type.formula ?? "AWAITING")
                                .font(.system(size: 11, weight: .bold, design: .serif))
                                .foregroundColor(Color.orange.opacity(0.9))
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
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Selection Flash Cards
                        MathSelectionView(mathManager: mathManager, onRun: { type in
                            switch type {
                            case .linearAlgebra: showLinearAlgebraGame = true
                            case .diffCalculus: showDiffCalculusGame = true
                            case .intCalculus: showIntCalculusGame = true
                            case .diffEq: showDiffEqGame = true
                            case .discreteMath: showDiscreteMathGame = true
                            case .vectorCalc: showVectorCalculusGame = true
                            }
                        })
                        
                        // Progress Tracker
                        MathProgressTracker()
                        
                        // Revision Flashcards Section
                        MathInsightView(mathManager: mathManager)
                        
                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showLinearAlgebraGame) { LinearAlgebraGame(onExit: { showLinearAlgebraGame = false }) }
        .fullScreenCover(isPresented: $showDiffCalculusGame) { DiffCalculusGame(onExit: { showDiffCalculusGame = false }) }
        .fullScreenCover(isPresented: $showIntCalculusGame) { IntegralCalculusGame(onExit: { showIntCalculusGame = false }) }
        .fullScreenCover(isPresented: $showDiffEqGame) { DifferentialEquationsGame(onExit: { showDiffEqGame = false }) }
        .fullScreenCover(isPresented: $showDiscreteMathGame) { DiscreteMathGame(onExit: { showDiscreteMathGame = false }) }
        .fullScreenCover(isPresented: $showVectorCalculusGame) { VectorCalculusGame(onExit: { showVectorCalculusGame = false }) }
    }
}


// MARK: - Components

struct MathSelectionView: View {
    @ObservedObject var mathManager: MathChallengeManager
    var onRun: (MathChallengeType) -> Void
    @AppStorage("unlockedMathGamesCount") private var unlockedMathCount = 3
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("APPLIED_THEOREMS")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("READY")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(MathChallengeType.allCases.enumerated()), id: \.element) { index, type in
                        Button(action: {
                            withAnimation(.spring()) {
                                mathManager.selectChallenge(type)
                                onRun(type)
                            }
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(mathManager.selectedChallengeType == type ? neonCyan : Color.white.opacity(0.05))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: type.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(mathManager.selectedChallengeType == type ? .black : .white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(type.rawValue.uppercased())
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(mathManager.selectedChallengeType == type ? neonCyan : .white)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                    Text("TOPIC: \(type.concept)")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(14)
                            .frame(width: 140, height: 140)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(mathManager.selectedChallengeType == type ? neonCyan : Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// Active Dashboard
struct CurrentMathChallengeView: View {
    var challenge: MathChallenge?
    @ObservedObject var mathManager: MathChallengeManager
    var onRun: (MathChallengeType) -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("THEOREM_SIMULATION_ACTIVE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(16)
            
            if let challenge = challenge {
                VStack(spacing: 20) {
                    Text(challenge.title)
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Text(challenge.description)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("VAR_X")
                                .font(.system(size: 8, design: .monospaced)).foregroundColor(.gray)
                            Text("\(String(format: "%.2f", challenge.variableX))")
                                .font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(.orange)
                        }
                        
                        ZStack {
                            Circle().stroke(Color.white.opacity(0.1), lineWidth: 4).frame(width: 60, height: 60)
                            Circle()
                                .trim(from: 0, to: CGFloat(challenge.progress))
                                .stroke(neonCyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(challenge.progress * 100))%")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        VStack {
                            Text("TARGET_Y")
                                .font(.system(size: 8, design: .monospaced)).foregroundColor(.gray)
                            Text("\(String(format: "%.2f", challenge.targetY))")
                                .font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(neonCyan)
                        }
                    }
                    
                    Button(action: {
                        withAnimation {
                            if let type = mathManager.selectedChallengeType {
                                onRun(type)
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "cpu.fill")
                            Text("INITIALIZE_SIMULATION")
                        }
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(neonCyan)
                        .cornerRadius(10)
                        .shadow(color: neonCyan.opacity(0.3), radius: 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            } else {
                Text("SELECT_A_THEOREM").padding(.vertical, 40).foregroundColor(.gray)
            }
        }
        .background(Color.white.opacity(0.03))
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Math Progress Tracker
struct MathProgressTracker: View {
    @AppStorage("unlockedMathGamesCount") private var unlockedMathCount = 3
    @State private var earnedBadges: [String] = []
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    private let mathBadges = [
        "Linear Scholar", "Derivative Master", "Integral Architect",
        "Differential Stabilizer", "Logic Gate Hacker", "Vector Navigator"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .foregroundColor(neonCyan)
                Text("PROGRESS_TRACKER")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
                Spacer()
                Text("\(min(unlockedMathCount, 6))/6 UNLOCKED")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(neonCyan)
                        .frame(width: geo.size.width * CGFloat(min(unlockedMathCount, 6)) / 6.0)
                        .shadow(color: neonCyan.opacity(0.5), radius: 6)
                }
            }
            .frame(height: 6)
            
            // Badges row
            if !earnedBadges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(mathBadges, id: \.self) { badge in
                            let isEarned = earnedBadges.contains(badge)
                            HStack(spacing: 4) {
                                Image(systemName: isEarned ? "shield.checkered" : "lock.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(isEarned ? neonCyan : .gray.opacity(0.4))
                                Text(badge.uppercased())
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(isEarned ? .white : .gray.opacity(0.4))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(isEarned ? neonCyan.opacity(0.1) : Color.white.opacity(0.03))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isEarned ? neonCyan.opacity(0.4) : Color.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                }
            } else {
                Text("Complete challenges to earn badges")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.6))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(neonCyan.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 16)
        .onAppear {
            earnedBadges = UserDefaults.standard.stringArray(forKey: "EarnedBadgesArray") ?? []
        }
    }
}

struct MathInsightView: View {
    @ObservedObject var mathManager: MathChallengeManager
    @State private var showLibrary = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showLibrary = true
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                        .foregroundColor(neonCyan)
                    Text("REVISION_FLASHCARD")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                }
                Text(currentInsight)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .animation(.easeInOut, value: mathManager.selectedChallengeType)
                
                HStack {
                    Spacer()
                    Text(mathManager.selectedChallengeType?.formula ?? "SELECT")
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.orange)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(neonCyan.opacity(0.4), lineWidth: 2))
            .padding(.horizontal, 16)
            .shadow(color: neonCyan.opacity(0.2), radius: 10)
        }
        .fullScreenCover(isPresented: $showLibrary) {
            ResearchLibraryView(viewModel: KineprintViewModel(), initialTopic: "MATHEMATICS")
        }
    }
    
    private var currentInsight: String {
        guard let type = mathManager.selectedChallengeType else { return "No theorem selected." }
        switch type {
        case .linearAlgebra: return "Eigenvectors represent structural stable states in kinematic robotics. Matrices define transformations in 3D space."
        case .diffCalculus: return "Calculating instantaneous velocity (gradient) and acceleration by taking the limit of distance over time."
        case .intCalculus: return "Determining total work done by accumulating the area under the force-displacement curve."
        case .diffEq: return "Predicting the evolution of dynamical systems like robotic suspension, dampening, and spring mechanics."
        case .discreteMath: return "Logic gates, state machines, array logic, and probability models for AI mapping and control schemas."
        case .vectorCalc: return "Analyzing magnetic fields, fluid dynamics simulation, and multidirectional force vectors (Curl & Divergence)."
        }
    }
}

// MARK: - Logic Models

enum MathChallengeType: String, CaseIterable {
    case linearAlgebra = "Linear Algebra"
    case diffCalculus = "Differential Calculus"
    case intCalculus = "Integral Calculus"
    case diffEq = "Differential Equations"
    case discreteMath = "Discrete Mathematics"
    case vectorCalc = "Vector Calculus"
    
    var icon: String {
        switch self {
        case .linearAlgebra: return "square.grid.3x3.topleft.filled"
        case .diffCalculus: return "chart.line.uptrend.xyaxis"
        case .intCalculus: return "sum"
        case .diffEq: return "f.cursive.circle"
        case .discreteMath: return "number.square.fill"
        case .vectorCalc: return "wind"
        }
    }
    
    var concept: String {
        switch self {
        case .linearAlgebra: return "Matrix Transforms"
        case .diffCalculus: return "Rates of Change"
        case .intCalculus: return "Accumulation"
        case .diffEq: return "Dynamical Systems"
        case .discreteMath: return "Boolean Logic"
        case .vectorCalc: return "Vector Fields"
        }
    }
    
    var formula: String {
        switch self {
        case .linearAlgebra: return "Ax = λx"
        case .diffCalculus: return "f'(x) = lim(h→0) [f(x+h) - f(x)]/h"
        case .intCalculus: return "∫ f(x) dx"
        case .diffEq: return "d²y/dt² + (k/m)y = 0"
        case .discreteMath: return "P(A ∪ B) = P(A) + P(B)"
        case .vectorCalc: return "∇ × F = 0"
        }
    }
}

struct MathChallenge {
    let type: MathChallengeType
    let title: String
    let description: String
    var variableX: Float = 0
    let targetY: Float
    var currentValue: Float = 0
    var progress: Float = 0
}

@MainActor
class MathChallengeManager: ObservableObject {
    @Published var selectedChallengeType: MathChallengeType?
    @Published var currentChallenge: MathChallenge?
    @Published var isRunning = false
    
    func selectChallenge(_ type: MathChallengeType) {
        selectedChallengeType = type
        currentChallenge = MathChallenge(
            type: type,
            title: "COMPUTE: \(type.rawValue)",
            description: "Evaluating \(type.formula) across bounds.",
            targetY: Float.random(in: 10...50)
        )
    }
    
    func start() {
        isRunning = true
        Task {
            while isRunning {
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled && isRunning else { break }
                if var challenge = currentChallenge {
                    challenge.variableX += Float.random(in: 0.1...1.5)
                    challenge.progress = min(challenge.variableX / challenge.targetY, 1.0)
                    currentChallenge = challenge
                    if challenge.progress >= 1.0 { isRunning = false }
                }
            }
        }
    }
    
    func pause() {
        isRunning = false
    }
}
