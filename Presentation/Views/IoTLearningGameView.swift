#if os(iOS)
import SwiftUI

struct IoTLearningGameView: View {
    @State private var components = IoTComponentsDatabase.shared.components.shuffled()
    @State private var currentQuestionIndex = 0
    @State private var score = 0
    @State private var showResult = false
    @State private var feedbackText = ""
    @State private var feedbackColor = Color.clear
    @State private var isGameOver = false
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    // Generate options: 1 correct, 3 wrong
    var options: [IoTComponent] {
        let correct = components[currentQuestionIndex]
        var wrong = components.filter { $0.id != correct.id }
        wrong.shuffle()
        let selectedOptions = [correct] + Array(wrong.prefix(3))
        return selectedOptions.shuffled()
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                GridBackground(color: neonCyan, size: geo.size)
            }
            
            VStack(spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: "cpu")
                        .font(.system(size: 20))
                        .foregroundColor(neonCyan)
                    Text("IoT MISSION BRIEFING")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
                
                if isGameOver {
                    GameOverView(score: score, total: components.count, restartAction: restartGame)
                } else {
                    VStack(spacing: 16) {
                        HStack {
                            Text("MISSION \(currentQuestionIndex + 1)/\(components.count)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(6)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text("SCORE")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                                Text("\(score)")
                                    .font(.system(size: 14, weight: .black, design: .monospaced))
                                    .foregroundColor(neonCyan)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(6)
                        }
                        
                        // The Question (Use Case)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("IDENTIFY THE COMPONENT FOR THIS SCENARIO:")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan.opacity(0.8))
                            
                            Text(components[currentQuestionIndex].useCase)
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(minHeight: 80, alignment: .topLeading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(neonCyan.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: neonCyan.opacity(0.1), radius: 10)
                        
                        if showResult {
                            Text(feedbackText)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(feedbackColor)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(feedbackColor.opacity(0.15))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(feedbackColor.opacity(0.5), lineWidth: 1))
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Spacer().frame(height: 48) // Placeholder to prevent jump
                        }
                        
                        // The Options
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(options) { component in
                                Button(action: {
                                    handleAnswer(selected: component)
                                }) {
                                    VStack(spacing: 12) {
                                        Image(systemName: component.iconName)
                                            .font(.system(size: 30))
                                            .foregroundColor(showResult && component.id == components[currentQuestionIndex].id ? .green : neonCyan)
                                        
                                        Text(component.name)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 110)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(showResult && component.id == components[currentQuestionIndex].id ? Color.green : Color.white.opacity(0.15), lineWidth: 1)
                                    )
                                    .shadow(color: showResult && component.id == components[currentQuestionIndex].id ? Color.green.opacity(0.4) : .clear, radius: 10)
                                }
                                .disabled(showResult)
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
    
    private func handleAnswer(selected: IoTComponent) {
        let correct = components[currentQuestionIndex]
        
        withAnimation(.spring()) {
            showResult = true
            if selected.id == correct.id {
                score += 100
                feedbackText = "CORRECT! IDENTIFICATION CONFIRMED."
                feedbackColor = .green
            } else {
                feedbackText = "INCORRECT. TARGET: \(correct.name.uppercased())."
                feedbackColor = .red
            }
        }
        
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation {
                showResult = false
                if currentQuestionIndex < components.count - 1 {
                    currentQuestionIndex += 1
                } else {
                    isGameOver = true
                }
            }
        }
    }
    
    private func restartGame() {
        components.shuffle()
        currentQuestionIndex = 0
        score = 0
        withAnimation {
            isGameOver = false
        }
    }
}

struct GameOverView: View {
    let score: Int
    let total: Int
    let restartAction: () -> Void
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(neonCyan)
                .shadow(color: neonCyan.opacity(0.5), radius: 15)
            
            Text("TRAINING COMPLETE")
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            VStack(spacing: 4) {
                Text("FINAL OPERATIVE SCORE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                
                Text("\(score)")
                    .font(.system(size: 56, weight: .heavy, design: .monospaced))
                    .foregroundColor(neonCyan)
                
                Text("Out of \(total * 100) possible points")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(neonCyan.opacity(0.6))
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            
            Button(action: restartAction) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("RESTART TRAINING")
                }
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(neonCyan)
                .cornerRadius(12)
                .shadow(color: neonCyan.opacity(0.4), radius: 10)
            }
            .padding(.top, 10)
        }
        .padding(30)
        .background(Color.black.opacity(0.6))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(neonCyan.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black, radius: 20)
    }
}
#endif
