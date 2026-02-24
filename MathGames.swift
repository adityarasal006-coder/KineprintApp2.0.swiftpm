import SwiftUI
import AVFoundation

// MARK: - Mathematician "Background Music" & Voice System
class MathAudioManager: ObservableObject {
    static let shared = MathAudioManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    func playMathematicianIntro(for theorem: String, formula: String) {
        let text = "Welcome to the simulation. Your objective is related to \(theorem). Remember the fundamental theorem: \(formula). Precise calculation is required."
        speak(text)
    }
    
    func playMathematicianQuote(quote: String) {
        speak(quote)
    }
    
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 0.9
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
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

// MARK: - Level Complete Overlay
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
struct LinearAlgebraGame: View {
    let onExit: () -> Void
    @State private var inputLambda: String = ""
    @State private var level = 1
    @State private var showOverlay = false
    @State private var errorWiggle = false
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
                                    .keyboardType(.numberPad)
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
    }
    
    private func verify() {
        if let val = Int(inputLambda), validEigenvalues.contains(val) {
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
    private func advanceLevel() { level += 1; inputLambda = ""; showOverlay = false }
}

// MARK: - 2. Differential Calculus Game
struct DiffCalculusGame: View {
    let onExit: () -> Void
    @State private var inputX: String = ""
    @State private var level = 1
    @State private var showOverlay = false
    @State private var errorWiggle = false
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
                                    .keyboardType(.decimalPad)
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
    }
    
    private func verify() {
        if let val = Double(inputX), validAnswers.contains(where: { abs($0 - val) < 0.05 }) {
            MathAudioManager.shared.playSuccess()
            MathAudioManager.shared.playMathematicianQuote(quote: "Newton is impressed. The gradient vanishes exactly here.")
            withAnimation { showOverlay = true }
        } else {
            MathAudioManager.shared.playError()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) { errorWiggle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { errorWiggle = false }
        }
    }
    private func advanceLevel() { level += 1; inputX = ""; showOverlay = false }
}

// MARK: - 3. Integral Calculus Game
struct IntegralCalculusGame: View {
    let onExit: () -> Void
    @State private var inputArea: String = ""
    @State private var level = 1
    @State private var showOverlay = false
    @State private var errorWiggle = false
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
                                    .keyboardType(.decimalPad)
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
    }
    
    private func verify() {
        if let val = Double(inputArea), abs(val - correctArea) < 0.1 {
            MathAudioManager.shared.playSuccess()
            MathAudioManager.shared.playMathematicianQuote(quote: "Continuous accumulation validated.")
            withAnimation { showOverlay = true }
        } else {
            MathAudioManager.shared.playError()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) { errorWiggle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { errorWiggle = false }
        }
    }
    private func advanceLevel() { level += 1; inputArea = ""; showOverlay = false }
}

// MARK: - 4. Differential Equations Game
struct DifferentialEquationsGame: View {
    let onExit: () -> Void
    @State private var inputC: String = ""
    @State private var level = 1
    @State private var showOverlay = false
    @State private var errorWiggle = false
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
                                    .keyboardType(.decimalPad)
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
    }
    
    private func verify() {
        if let val = Double(inputC), abs(val - exactC) < 0.1 {
            MathAudioManager.shared.playSuccess()
            MathAudioManager.shared.playMathematicianQuote(quote: "Critical damping achieved. The system will safely return to equilibrium.")
            withAnimation { showOverlay = true }
        } else {
            MathAudioManager.shared.playError()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.2)) { errorWiggle = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { errorWiggle = false }
        }
    }
    private func advanceLevel() { level += 1; inputC = ""; showOverlay = false }
}

// Stubs for remaining to ensure compilation (you can expand them following the same rigorous pattern)
struct DiscreteMathGame: View { let onExit: () -> Void; var body: some View { MathGameWrapper(title: "Discrete Mathematics", formula: "(A ∨ B) ∧ (C ⊕ D)", onExit: onExit) { Text("Combinatorics engine coming soon...").foregroundColor(.cyan) } } }
struct VectorCalculusGame: View { let onExit: () -> Void; var body: some View { MathGameWrapper(title: "Vector Calculus", formula: "∇ × F = 0", onExit: onExit) { Text("Stokes Theorem processing...").foregroundColor(.cyan) } } }
