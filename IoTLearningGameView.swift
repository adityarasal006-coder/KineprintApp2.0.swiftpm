#if os(iOS)
import SwiftUI

@available(iOS 16.0, *)
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
        VStack(spacing: 20) {
            Text("IoT MISSION BRIEFING")
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(neonCyan)
            
            if isGameOver {
                GameOverView(score: score, total: components.count, restartAction: restartGame)
            } else {
                VStack(spacing: 16) {
                    HStack {
                        Text("MISSION \(currentQuestionIndex + 1)/\(components.count)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("SCORE: \(score)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                    
                    // The Question (Use Case)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("IDENTIFY THE COMPONENT FOR THIS SCENARIO:")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                        
                        Text(components[currentQuestionIndex].useCase)
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(minHeight: 80, alignment: .topLeading)
                    }
                    .padding()
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(neonCyan.opacity(0.3), lineWidth: 1)
                    )
                    
                    if showResult {
                        Text(feedbackText)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(feedbackColor)
                            .padding(.vertical, 8)
                            .transition(.opacity)
                    } else {
                        Spacer().frame(height: 35) // Placeholder to prevent jump
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
                                        .foregroundColor(neonCyan)
                                    
                                    Text(component.name)
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .disabled(showResult)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func handleAnswer(selected: IoTComponent) {
        let correct = components[currentQuestionIndex]
        showResult = true
        
        if selected.id == correct.id {
            score += 100
            feedbackText = "CORRECT! IDENTIFICATION CONFIRMED."
            feedbackColor = .green
        } else {
            feedbackText = "INCORRECT. TARGET WAS \(correct.name.uppercased())."
            feedbackColor = .red
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
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
        isGameOver = false
    }
}

@available(iOS 16.0, *)
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
            
            Text("TRAINING COMPLETE")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Text("FINAL OPERATIVE SCORE")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            Text("\(score)")
                .font(.system(size: 48, weight: .heavy, design: .monospaced))
                .foregroundColor(neonCyan)
            
            Text("Out of \(total * 100) possible points")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            
            Button(action: restartAction) {
                Text("RESTART TRAINING")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 40)
                    .background(neonCyan)
                    .cornerRadius(12)
            }
            .padding(.top, 20)
        }
        .padding(30)
        .background(Color.black.opacity(0.5))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(neonCyan.opacity(0.3), lineWidth: 1)
        )
    }
}
#endif
