import SwiftUI
import AVFoundation

// MARK: - Mathematician "Background Music" & Voice System
@MainActor
class MathAudioManager: ObservableObject {
    @MainActor static let shared = MathAudioManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    func playMathematicianIntro(for theorem: String, formula: String) {
        let text = "Welcome to the simulation. Your objective is related to \(theorem). Remember the fundamental theorem: \(formula). Precise calculation is required."
        speak(text)
    }
    
    func playMathematicianQuote(quote: String) {
        speak(quote)
    }
    
    private func speak(_ text: String) {
        VoiceManager.shared.speak(text, rate: 0.45, pitch: 0.9)
    }
    
    func stop() {
        VoiceManager.shared.stop()
    }
    
    func playSuccess() {
        AudioServicesPlaySystemSound(1052)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - Progressive Unlocks & Badges Manager
@MainActor
class GameProgressManager {
    @MainActor static let shared = GameProgressManager()
    
    func unlockNext(category: String, currentIndex: Int, badge: String) {
        // Unlock Logic
        let key = category == "Math" ? "unlockedMathGamesCount" : "unlockedPhysicsGamesCount"
        let currentUnlocked = UserDefaults.standard.integer(forKey: key)
        let actualUnlocked = currentUnlocked == 0 ? 3 : currentUnlocked
        
        if currentIndex + 2 > actualUnlocked {
            UserDefaults.standard.set(currentIndex + 2, forKey: key)
        }
        
        // Badge Logic
        var badges = UserDefaults.standard.stringArray(forKey: "EarnedBadgesArray") ?? []
        if !badges.contains(badge) {
            badges.append(badge)
            UserDefaults.standard.set(badges, forKey: "EarnedBadgesArray")
            
            // Brief haptic burst to celebrate badge
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Level Complete Overlay
@MainActor
struct MathLevelCompleteOverlay: View {
    let level: Int
    let onNext: () -> Void
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("LEVEL \(level) THEOREM SOLVED")
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(.green)
                
            Text("COMPUTATION VERIFIED")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            
            Button(action: onNext) {
                Text("ADVANCE TO LEVEL \(level + 1)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(neonCyan)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding(30)
        .background(Color.black.opacity(0.95))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.green, lineWidth: 2))
        .padding(40)
    }
}

// MARK: - Shared Game Wrapper
@MainActor
struct MathGameWrapper<Content: View>: View {
    let title: String
    let formula: String
    let onExit: () -> Void
    let content: Content
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    init(title: String, formula: String, onExit: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.title = title
        self.formula = formula
        self.onExit = onExit
        self.content = content()
    }

    var body: some View {
        let allFormulas = ["∫ f(x) dx", "∇ × F = 0", "mx'' + cx' + kx = 0", "f'(x) = 0", "Ax = λx", "E = mc²", "P(A ∪ B)"]
        
        ZStack {
            Color.black.ignoresSafeArea()
            FloatingFormulasView(formulas: allFormulas, color: neonCyan).ignoresSafeArea()
            GeometryReader { geo in
                GridBackground(color: neonCyan, size: geo.size).opacity(0.3)
            }.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: onExit) {
                        Image(systemName: "xmark.square.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.red)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(title.uppercased())
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(neonCyan)
                        Text(formula)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .border(neonCyan.opacity(0.4), width: 1)
                
                Spacer()
                content
                Spacer()
            }
        }
        .onAppear { MathAudioManager.shared.playMathematicianIntro(for: title, formula: formula) }
        .onDisappear { MathAudioManager.shared.stop() }
    }
}

// MARK: - 1. Linear Algebra Game
@MainActor
struct LinearAlgebraGame: View {
    let onExit: () -> Void
    @State private var inputLambda: String = ""
    @State private var level = 1
    @State private var showOverlay = false
    @State private var errorWiggle = false
    @State private var showBadgeOverlay = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var matrix: [[Int]] {
        if level == 1 { return [[2, 0], [0, 3]] }
        else if level == 2 { return [[4, 1], [0, 5]] }
        else { return [[2, 1], [1, 2]] }
    }
    var validEigenvalues: [Int] {
        if level == 1 { return [2, 3] }
        else if level == 2 { return [4, 5] }
        else { return [1, 3] }
    }
    
    var body: some View {
        MathGameWrapper(title: "Linear Algebra (LVL \(level))", formula: level == 3 ? "det(A - λI) = 0" : "Ax = λx", onExit: onExit) {
            ZStack {
                VStack(spacing: 20) {
                    if level <= 3 {
                        FormulaCard(lines: ["Ax = λx", "det(A - λI) = 0"], note: "Solve determinant for exact invariant scalar λ.")
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                        
                        VStack(spacing: 30) {
                            Text(level > 3 ? "EIGENSPACE FULLY MAPPED." : "Calculate an exact Eigenvalue (λ) for Matrix A.")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            VStack(spacing: 15) {
                                Text("MATRIX A").font(.system(size: 12, weight: .black, design: .monospaced)).foregroundColor(neonCyan)
                                VStack(spacing: 8) {
                                    HStack(spacing: 20) {
                                        Text("\(matrix[0][0])").frame(width: 30)
                                        Text("\(matrix[0][1])").frame(width: 30)
                                    }
                                    HStack(spacing: 20) {
                                        Text("\(matrix[1][0])").frame(width: 30)
                                        Text("\(matrix[1][1])").frame(width: 30)
                                    }
                                }
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .padding(20)
                                .background(Color.white.opacity(0.05))
                                .border(neonCyan, width: 2)
                            }
                            
                            HStack {
                                Text("λ =")
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundColor(.orange)
                                TextField("?", text: $inputLambda)
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 80)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .offset(x: errorWiggle ? -10 : 0)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 16)
                        
                        Button(action: verify) {
                            Text("VERIFY COMPUTATION")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(neonCyan)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        VStack(spacing: 30) {
                            Text("EIGENSPACE FULLY MAPPED.")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                if showOverlay { MathLevelCompleteOverlay(level: level, onNext: advanceLevel) }
            }
        }
        .fullScreenCover(isPresented: $showBadgeOverlay) {
            BadgeEarnedOverlay(badgeName: "Linear Scholar") {
                showBadgeOverlay = false
                level = 1
                inputLambda = ""
                showOverlay = false
            }
        }
    }
    
    private func verify() {
        if let val = parseMathInput(inputLambda, expectedType: .integer), validEigenvalues.contains(Int(val)) {
            MathAudioManager.shared.playSuccess()
            MathAudioManager.shared.playMathematicianQuote(quote: "Correct. The determinant vanishes perfectly along this scalar.")
            withAnimation { showOverlay = true }
        } else {
            MathAudioManager.shared.playError()
            triggerWiggle()
        }
    }
    private func triggerWiggle() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) { errorWiggle = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { errorWiggle = false }
    }
    private func advanceLevel() {
        if level >= 3 {
            GameProgressManager.shared.unlockNext(category: "Math", currentIndex: 0, badge: "Linear Scholar")
            showOverlay = false
            showBadgeOverlay = true
        } else {
            level += 1
            inputLambda = ""
            showOverlay = false
        }
    }
}

// MARK: - 2. Differential Calculus Game
@MainActor
struct DiffCalculusGame: View {
    let onExit: () -> Void
    @State private var inputX: String = ""
    @State private var level = 1
    @State private var showOverlay = false
    @State private var errorWiggle = false
    @State private var showBadgeOverlay = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var functionStr: String {
        if level == 1 { return "f(x) = -x² + 4x" } // max at x=2
        else if level == 2 { return "f(x) = x³ - 3x" } // extremum at x=1 or -1
        else { return "f(x) = sin(x) (0 < x < π)" } // max at x = 1.57 (pi/2)
    }
    var validAnswers: [Double] {
        if level == 1 { return [2.0] }
        else if level == 2 { return [1.0, -1.0] }
        else { return [1.57] }
    }
    
    var body: some View {
        MathGameWrapper(title: "Differential Calculus (LVL \(level))", formula: "f'(x) = 0 for Extrema", onExit: onExit) {
            ZStack {
                VStack(spacing: 20) {
                    if level <= 3 {
                        FormulaCard(lines: ["f'(x) = 0", "d/dx [x^n] = n*x^(n-1)"], note: "Find x where instantaneous rate of change vanishes.")
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                        
                        VStack(spacing: 30) {
                            Text(level > 3 ? "ALL EXTREMA VERIFIED." : "Calculate the exact value of x where the function reaches a local extremum (f'(x) = 0).")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text(functionStr)
                                .font(.system(size: 24, weight: .bold, design: .serif))
                                .foregroundColor(neonCyan)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(neonCyan.opacity(0.5), lineWidth: 1))
                            
                            HStack {
                                Text("x = ")
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundColor(.orange)
                                TextField(level == 3 ? "e.g. 1.57" : "?", text: $inputX)
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 120)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .offset(x: errorWiggle ? -10 : 0)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 16)
                        
                        Button(action: verify) {
                            Text("VERIFY CRITICAL POINT")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(neonCyan)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        VStack(spacing: 30) {
                            Text("ALL EXTREMA VERIFIED.")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                if showOverlay { MathLevelCompleteOverlay(level: level, onNext: advanceLevel) }
            }
        }
        .fullScreenCover(isPresented: $showBadgeOverlay) {
            BadgeEarnedOverlay(badgeName: "Derivative Master") {
                showBadgeOverlay = false
                level = 1; inputX = ""; showOverlay = false
            }
        }
    }
    
    private func verify() {
        if let val = parseMathInput(inputX), validAnswers.contains(where: { abs($0 - val) < 0.05 }) {
            MathAudioManager.shared.playSuccess()
            MathAudioManager.shared.playMathematicianQuote(quote: "Newton is impressed. The gradient vanishes exactly here.")
            withAnimation { showOverlay = true }
        } else {
            MathAudioManager.shared.playError()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) { errorWiggle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { errorWiggle = false }
        }
    }
    private func advanceLevel() {
        if level >= 3 {
            GameProgressManager.shared.unlockNext(category: "Math", currentIndex: 1, badge: "Derivative Master")
            showOverlay = false
            showBadgeOverlay = true
        } else {
            level += 1
            inputX = ""
            showOverlay = false
        }
    }
}

// MARK: - 3. Integral Calculus Game
@MainActor
struct IntegralCalculusGame: View {
    let onExit: () -> Void
    @State private var inputArea: String = ""
    @State private var level = 1
    @State private var showOverlay = false
    @State private var errorWiggle = false
    @State private var showBadgeOverlay = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var functionStr: String {
        if level == 1 { return "∫(from 0 to 2) x dx" } // Area = 2
        else if level == 2 { return "∫(from 0 to 3) x² dx" } // Area = 9
        else { return "∫(from 0 to π) sin(x) dx" } // Area = 2
    }
    var correctArea: Double {
        if level == 1 { return 2.0 }
        else if level == 2 { return 9.0 }
        else { return 2.0 }
    }
    
    var body: some View {
        MathGameWrapper(title: "Integral Calculus (LVL \(level))", formula: "Area = lim(n→∞) Σ f(xi)Δx", onExit: onExit) {
            ZStack {
                VStack(spacing: 20) {
                    if level <= 3 {
                        FormulaCard(lines: ["A = ∫ f(x) dx", "F(b) - F(a)"], note: "Evaluate the definite integral for exact area.")
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                        
                        VStack(spacing: 30) {
                            Text(level > 3 ? "ALL INTEGRALS EVALUATED." : "Manually compute the definite integral to find the exact area under the curve.")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text(functionStr)
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundColor(neonCyan)
                                .padding()
                            
                            HStack {
                                Text("Area = ")
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundColor(.orange)
                                TextField("?", text: $inputArea)
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 100)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .offset(x: errorWiggle ? -10 : 0)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 16)
                        
                        Button(action: verify) {
                            Text("INPUT COMPUTATION")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(neonCyan)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        VStack(spacing: 30) {
                            Text("ALL INTEGRALS EVALUATED.")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                if showOverlay { MathLevelCompleteOverlay(level: level, onNext: advanceLevel) }
            }
        }
        .fullScreenCover(isPresented: $showBadgeOverlay) {
            BadgeEarnedOverlay(badgeName: "Integral Architect") {
                showBadgeOverlay = false
                level = 1; inputArea = ""; showOverlay = false
            }
        }
    }
    
    private func verify() {
        if let val = parseMathInput(inputArea), abs(val - correctArea) < 0.1 {
            MathAudioManager.shared.playSuccess()
            MathAudioManager.shared.playMathematicianQuote(quote: "Continuous accumulation validated.")
            withAnimation { showOverlay = true }
        } else {
            MathAudioManager.shared.playError()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) { errorWiggle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { errorWiggle = false }
        }
    }
    private func advanceLevel() {
        if level >= 3 {
            GameProgressManager.shared.unlockNext(category: "Math", currentIndex: 2, badge: "Integral Architect")
            showOverlay = false
            showBadgeOverlay = true
        } else {
            level += 1
            inputArea = ""
            showOverlay = false
        }
    }
}

// MARK: - 4. Differential Equations Game
@MainActor
struct DifferentialEquationsGame: View {
    let onExit: () -> Void
    @State private var inputC: String = ""
    @State private var level = 1
    @State private var showOverlay = false
    @State private var errorWiggle = false
    @State private var showBadgeOverlay = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var mass: Double { level == 1 ? 1.0 : (level == 2 ? 4.0 : 2.0) }
    var kVal: Double { level == 1 ? 4.0 : (level == 2 ? 1.0 : 8.0) }
    var exactC: Double { 2 * sqrt(mass * kVal) } // critical damping
    
    var body: some View {
        MathGameWrapper(title: "Differential Eq (LVL \(level))", formula: "mx'' + cx' + kx = 0", onExit: onExit) {
            ZStack {
                VStack(spacing: 20) {
                    if level <= 3 {
                        FormulaCard(lines: ["c = 2√(m·k)", "mx'' + cx' + kx = 0"], note: "Solve for Critical Damping coefficient.")
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                        
                        VStack(spacing: 30) {
                            Text(level > 3 ? "ALL SYSTEMS STABILIZED." : "Calculate the exact Critical Damping coefficient (c) for the harmonic oscillator where c = 2√(m·k).")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            VStack(spacing: 15) {
                                Text("System Parameters")
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(neonCyan)
                                Text("Mass (m) = \(String(format: "%.1f", mass)) kg")
                                Text("Spring (k) = \(String(format: "%.1f", kVal)) N/m")
                            }
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .padding(20)
                            
                            HStack {
                                Text("c =")
                                    .font(.system(size: 24, weight: .bold, design: .serif))
                                    .foregroundColor(.orange)
                                TextField("?", text: $inputC)
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 80)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .offset(x: errorWiggle ? -10 : 0)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 16)
                        
                        Button(action: verify) {
                            Text("LOCK IN DAMPING MATRIX")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(neonCyan)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                    } else {
                        VStack(spacing: 30) {
                            Text("ALL SYSTEMS STABILIZED.")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                
                if showOverlay { MathLevelCompleteOverlay(level: level, onNext: advanceLevel) }
            }
        }
        .fullScreenCover(isPresented: $showBadgeOverlay) {
            BadgeEarnedOverlay(badgeName: "Differential Stabilizer") {
                showBadgeOverlay = false
                level = 1; inputC = ""; showOverlay = false
            }
        }
    }
    
    private func verify() {
        if let val = parseMathInput(inputC), abs(val - exactC) < 0.1 {
            MathAudioManager.shared.playSuccess()
            MathAudioManager.shared.playMathematicianQuote(quote: "Critical damping achieved. The system will safely return to equilibrium.")
            withAnimation { showOverlay = true }
        } else {
            MathAudioManager.shared.playError()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) { errorWiggle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { errorWiggle = false }
        }
    }
    private func advanceLevel() {
        if level >= 3 {
            GameProgressManager.shared.unlockNext(category: "Math", currentIndex: 3, badge: "Differential Stabilizer")
            showOverlay = false
            showBadgeOverlay = true
        } else {
            level += 1
            inputC = ""
            showOverlay = false
        }
    }
}

// MARK: - 5. Discrete Mathematics Game (10 Levels)
@MainActor
struct DiscreteMathGame: View {
    let onExit: () -> Void
    @State private var inputAnswer: String = ""
    @State private var level = 1
    @State private var showOverlay = false
    @State private var errorWiggle = false
    @State private var showBadgeOverlay = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var subtopic: String {
        switch level {
        case 1: return "Truth Tables"
        case 2: return "Propositional Logic"
        case 3: return "Set Theory"
        case 4: return "Combinatorics"
        case 5: return "Graph Theory"
        case 6: return "Modular Arithmetic"
        case 7: return "Boolean Algebra"
        case 8: return "Relations"
        case 9: return "Recurrence Relations"
        default: return "Proof Techniques"
        }
    }

    var prompt: String {
        switch level {
        case 1: return "(True AND False) OR True"
        case 2: return "NOT (True AND (False OR True))"
        case 3: return "|A ∪ B| if |A|=5, |B|=3, |A∩B|=2"
        case 4: return "C(5, 2) = 5! / (2! × 3!)"
        case 5: return "Edges in complete graph K₄"
        case 6: return "17 mod 5"
        case 7: return "(A + B)' simplifies to (De Morgan)"
        case 8: return "Is R={(1,1),(2,2),(3,3)} reflexive? (True/False)"
        case 9: return "If a(n) = 2·a(n-1), a(1) = 3, find a(4)"
        default: return "(True XOR False) AND (NOT False)"
        }
    }

    var expected: String {
        switch level {
        case 1: return "true"
        case 2: return "false"
        case 3: return "6"     // |A∪B| = 5+3-2 = 6
        case 4: return "10"    // C(5,2) = 10
        case 5: return "6"     // K4 edges = 4*3/2 = 6
        case 6: return "2"     // 17 mod 5 = 2
        case 7: return "a'b'"  // De Morgan's: (A+B)' = A'·B'
        case 8: return "true"  // yes reflexive
        case 9: return "24"    // 3, 6, 12, 24
        default: return "true" // (T^F) & (!F) = T & T = T
        }
    }

    var hintLines: [String] {
        switch level {
        case 1: return ["AND, OR truth tables", "T AND F = F, F OR T = T"]
        case 2: return ["NOT negates result", "Evaluate inner first"]
        case 3: return ["|A∪B| = |A| + |B| - |A∩B|", "Inclusion-Exclusion Principle"]
        case 4: return ["C(n,r) = n! / (r!(n-r)!)", "Binomial Coefficient"]
        case 5: return ["Complete graph Kn", "Edges = n(n-1)/2"]
        case 6: return ["a mod n = remainder", "17 ÷ 5 = 3 remainder ?"]
        case 7: return ["De Morgan's Law", "(A+B)' = A'·B'"]
        case 8: return ["Reflexive: ∀a, (a,a) ∈ R", "Check all elements"]
        case 9: return ["a(n) = 2·a(n-1)", "Geometric: a(n) = 3·2^(n-1)"]
        default: return ["XOR: T⊕F = T", "Combined logic gates"]
        }
    }

    var body: some View {
        MathGameWrapper(title: "Discrete Math (LVL \(level))", formula: "Concept: \(subtopic)", onExit: onExit) {
            ZStack {
                VStack(spacing: 20) {
                    if level <= 10 {
                        FormulaCard(lines: hintLines, note: "Subtopic: \(subtopic)")
                            .padding(.horizontal, 16)
                            .padding(.top, 10)

                        VStack(spacing: 30) {
                            Text("Evaluate the following \(subtopic.lowercased()) problem.")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            Text(prompt)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(neonCyan.opacity(0.5), lineWidth: 1))

                            HStack {
                                Text("Ans = ")
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .foregroundColor(.orange)
                                TextField("Answer", text: $inputAnswer)
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 140)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .offset(x: errorWiggle ? -10 : 0)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 16)

                        Button(action: verify) {
                            Text("VERIFY LOGIC")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(neonCyan)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                    }
                }

                if showOverlay { MathLevelCompleteOverlay(level: level, onNext: advanceLevel) }
            }
        }
        .fullScreenCover(isPresented: $showBadgeOverlay) {
            BadgeEarnedOverlay(badgeName: "Logic Gate Hacker") {
                showBadgeOverlay = false
                level = 1; inputAnswer = ""; showOverlay = false
            }
        }
    }

    private func verify() {
        let userAns = inputAnswer.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "'", with: "'")
            .replacingOccurrences(of: " ", with: "")
        let correctAns = expected.lowercased().replacingOccurrences(of: " ", with: "")

        if userAns == correctAns {
            MathAudioManager.shared.playSuccess()
            MathAudioManager.shared.playMathematicianQuote(quote: "Logic verified. The truth table holds.")
            withAnimation { showOverlay = true }
        } else if let val = parseMathInput(inputAnswer), let exp = Double(expected), abs(val - exp) < 0.1 {
            MathAudioManager.shared.playSuccess()
            MathAudioManager.shared.playMathematicianQuote(quote: "Computation validated.")
            withAnimation { showOverlay = true }
        } else {
            MathAudioManager.shared.playError()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) { errorWiggle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { errorWiggle = false }
        }
    }
    private func advanceLevel() {
        if level >= 10 {
            GameProgressManager.shared.unlockNext(category: "Math", currentIndex: 4, badge: "Logic Gate Hacker")
            showOverlay = false
            showBadgeOverlay = true
        } else {
            level += 1
            if level > 3 { GameProgressManager.shared.unlockNext(category: "Math", currentIndex: 4, badge: "Logic Gate Hacker") }
            inputAnswer = ""
            showOverlay = false
        }
    }
}

// MARK: - 6. Vector Calculus Game (10 Levels)
struct VectorCalculusGame: View {
    let onExit: () -> Void
    @State private var inputAnswer: String = ""
    @State private var level = 1
    @State private var showOverlay = false
    @State private var errorWiggle = false
    @State private var showBadgeOverlay = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    var subtopic: String {
        switch level {
        case 1: return "Vector Magnitude"
        case 2: return "Dot Product"
        case 3: return "Cross Product"
        case 4: return "Unit Vectors"
        case 5: return "Gradient"
        case 6: return "Divergence"
        case 7: return "Curl"
        case 8: return "Line Integrals"
        case 9: return "Surface Area"
        default: return "Stokes' Theorem"
        }
    }

    var prompt: String {
        switch level {
        case 1: return "Magnitude of vector (3, 4)"
        case 2: return "Dot product: a=(1,2) · b=(3,4)"
        case 3: return "|a × b| where a⊥b, |a|=2, |b|=3"
        case 4: return "Unit vector of (6, 8): find magnitude"
        case 5: return "∇f at (1,1) if f(x,y) = x² + y². Find |∇f|"
        case 6: return "div F if F = (2x, 3y, z)"
        case 7: return "curl F = ? if F = (y, -x, 0). Find z-component"
        case 8: return "∫C ds along x from 0 to 5"
        case 9: return "Surface area of sphere r=1: 4πr²"
        default: return "∮ F·dr = ∫∫ (curl F)·dS, curl z-comp = -2. Area=3. Value?"
        }
    }

    var expected: Double {
        switch level {
        case 1: return 5.0       // sqrt(9+16)
        case 2: return 11.0      // 1*3 + 2*4
        case 3: return 6.0       // |a||b|sin90 = 2*3
        case 4: return 1.0       // unit vector magnitude is always 1
        case 5: return 2.828     // |∇f| = sqrt(4+4) = 2√2 ≈ 2.83
        case 6: return 6.0       // 2 + 3 + 1 = 6
        case 7: return -2.0      // ∂(-x)/∂x - ∂(y)/∂y = -1-1 = -2
        case 8: return 5.0       // simple line integral = length
        case 9: return 12.566    // 4π ≈ 12.566
        default: return -6.0     // -2 * 3 = -6 (Stokes')
        }
    }

    var hintLines: [String] {
        switch level {
        case 1: return ["|v| = √(x² + y²)", "Pythagorean theorem"]
        case 2: return ["a · b = a₁b₁ + a₂b₂", "Scalar product"]
        case 3: return ["|a × b| = |a||b|sin θ", "θ = 90° ⟹ sin θ = 1"]
        case 4: return ["û = v / |v|", "Unit vector has magnitude 1"]
        case 5: return ["∇f = (∂f/∂x, ∂f/∂y)", "|∇f| at (1,1)"]
        case 6: return ["div F = ∂F₁/∂x + ∂F₂/∂y + ∂F₃/∂z", "Sum of partial derivatives"]
        case 7: return ["curl F z-comp = ∂F₂/∂x - ∂F₁/∂y", "Compute partials"]
        case 8: return ["∫C ds = path length", "Straight line from 0 to 5"]
        case 9: return ["Surface area = 4πr²", "r = 1, compute 4π"]
        default: return ["Stokes: ∮F·dr = ∫∫ curlF·dS", "curlz × Area"]
        }
    }
    
    var tolerance: Double {
        switch level {
        case 5: return 0.05  // 2√2 ≈ 2.83
        case 9: return 0.1   // 4π ≈ 12.566
        default: return 0.1
        }
    }

    var body: some View {
        MathGameWrapper(title: "Vector Calculus (LVL \(level))", formula: "Concept: \(subtopic)", onExit: onExit) {
            ZStack {
                VStack(spacing: 20) {
                    if level <= 10 {
                        FormulaCard(lines: hintLines, note: "Subtopic: \(subtopic)")
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                        
                        VStack(spacing: 30) {
                            Text("Evaluate the \(subtopic.lowercased()) problem.")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Text(prompt)
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(neonCyan.opacity(0.5), lineWidth: 1))
                            
                            HStack {
                                Text("Ans = ")
                                    .font(.system(size: 20, weight: .bold, design: .serif))
                                    .foregroundColor(.orange)
                                TextField("?", text: $inputAnswer)
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                    .frame(width: 120)
                                    .padding(10)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .offset(x: errorWiggle ? -10 : 0)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(20)
                        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .padding(.horizontal, 16)
                        
                        Button(action: verify) {
                            Text("RUN SCALAR SIMULATION")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(neonCyan)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                    }
                }
                
                if showOverlay { MathLevelCompleteOverlay(level: level, onNext: advanceLevel) }
            }
        }
        .fullScreenCover(isPresented: $showBadgeOverlay) {
            BadgeEarnedOverlay(badgeName: "Vector Navigator") {
                showBadgeOverlay = false
                level = 1; inputAnswer = ""; showOverlay = false
            }
        }
    }

    private func verify() {
        if let val = parseMathInput(inputAnswer), abs(val - expected) < tolerance {
            MathAudioManager.shared.playSuccess()
            MathAudioManager.shared.playMathematicianQuote(quote: "Field trajectory confirmed. Calculation correct.")
            withAnimation { showOverlay = true }
        } else {
            MathAudioManager.shared.playError()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) { errorWiggle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { errorWiggle = false }
        }
    }
    private func advanceLevel() {
        if level >= 10 {
            GameProgressManager.shared.unlockNext(category: "Math", currentIndex: 5, badge: "Vector Navigator")
            showOverlay = false
            showBadgeOverlay = true
        } else {
            level += 1
            if level > 3 { GameProgressManager.shared.unlockNext(category: "Math", currentIndex: 5, badge: "Vector Navigator") }
            inputAnswer = ""
            showOverlay = false
        }
    }
}

enum MathInputType {
    case double
    case integer
}

func parseMathInput(_ input: String, expectedType: MathInputType = .double) -> Double? {
    let cleaned = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Pi parsing
    if cleaned == "pi" || cleaned == "pai" || cleaned == "π" { return Double.pi }
    if cleaned == "pi/2" || cleaned == "pai/2" || cleaned == "π/2"{ return Double.pi / 2.0 }
    if cleaned == "-pi" || cleaned == "-pai" || cleaned == "-π"{ return -Double.pi }
    if cleaned == "-pi/2" || cleaned == "-pai/2" || cleaned == "-π/2"{ return -Double.pi / 2.0 }
    
    // Fractions matching
    let parts = cleaned.components(separatedBy: "/")
    if parts.count == 2, let num = Double(parts[0]), let den = Double(parts[1]), den != 0 {
        return num / den
    }
    
    return Double(cleaned)
}
