import SwiftUI
import Foundation
import UIKit

struct ScientificCalculatorView: View {
    @State private var display = "0"
    @State private var history = ""
    @State private var isBreaching = false
    @State private var isSecretUnlocked = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    let buttons: [[String]] = [
        ["sin", "cos", "tan", "log"],
        ["ln", "√", "π", "e"],
        ["AC", "⌫", "%", "/"],
        ["7", "8", "9", "*"],
        ["4", "5", "6", "-"],
        ["1", "2", "3", "+"],
        ["0", ".", "=", "^"]
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            EngineeringGridBackground(cyanColor: neonCyan).opacity(0.15)
            
            VStack(spacing: 0) {
                // ═══ Header Bar ═══
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(neonCyan).frame(width: 6, height: 6)
                            .shadow(color: neonCyan, radius: 4)
                        Text("COMPUTATION_NODE")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(neonCyan)
                    }
                    Spacer()
                    Text("v2.1")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan.opacity(0.5))
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)
                .background(Color.black.opacity(0.5))
                .overlay(
                    Rectangle().frame(height: 1).foregroundColor(neonCyan.opacity(0.2)), alignment: .bottom
                )
                
                Spacer()
                
                // ═══ Display Area ═══
                VStack(alignment: .trailing, spacing: 10) {
                    Text(history)
                        .font(.system(size: 20, design: .monospaced))
                        .foregroundColor(.gray)
                    Text(display)
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                        .shadow(color: neonCyan.opacity(0.3), radius: 8)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(neonCyan.opacity(0.15), lineWidth: 1)
                )
                .padding(.horizontal)
                
                Spacer().frame(height: 20)
                
                // ═══ Keypad ═══
                VStack(spacing: 12) {
                    ForEach(buttons, id: \.self) { row in
                        HStack(spacing: 12) {
                            ForEach(row, id: \.self) { btn in
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    self.buttonTapped(btn)
                                }) {
                                    Text(btn)
                                        .font(.system(size: btn.count > 1 ? 18 : 26, weight: .medium, design: .monospaced))
                                        .frame(maxWidth: .infinity, maxHeight: 58)
                                        .foregroundColor(self.buttonColor(btn))
                                        .background(Color.white.opacity(0.04))
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(self.buttonColor(btn).opacity(0.2), lineWidth: 1)
                                        )
                                        .shadow(color: self.buttonColor(btn).opacity(0.08), radius: 4)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            
            if isBreaching && !isSecretUnlocked {
                SystemBreachAnimationView(isComplete: $isSecretUnlocked)
                    .transition(.opacity)
                    .zIndex(10)
            }
            
            if isSecretUnlocked {
                SecretDiaryView(isPresented: $isSecretUnlocked)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(20)
                    .onAppear { isBreaching = false }
            }
        }
    }
    
    private func buttonColor(_ btn: String) -> Color {
        if ["AC", "⌫"].contains(btn) { return .red }
        if ["/", "*", "-", "+", "="].contains(btn) { return Color.orange }
        if ["sin", "cos", "tan", "log", "ln", "√", "π", "e", "%", "^"].contains(btn) { return neonCyan.opacity(0.8) }
        return .white
    }
    
    private func buttonTapped(_ btn: String) {
        if isBreaching || isSecretUnlocked { return } // Prevent input during animation
        
        switch btn {
        case "AC":
            display = "0"; history = ""
        case "⌫":
            if display.count > 1 { display.removeLast() } else { display = "0" }
        case "=":
            if let passkey = UserDefaults.standard.string(forKey: "SecretVaultPasskey"), !passkey.isEmpty, display == passkey {
                withAnimation { isBreaching = true }
                display = "0"
                history = ""
                return
            }
            
            history = display + " ="
            display = calculateResult(display)
        case "π":
            if display == "0" { display = "3.14159" } else { display += "3.14159" }
        case "e":
            if display == "0" { display = "2.71828" } else { display += "2.71828" }
        default:
            if display == "0" && !["/", "*", "-", "+", ".", "%", "^"].contains(btn) { display = btn }
            else { display += btn }
        }
    }
    
    private func calculateResult(_ expression: String) -> String {
        let expr = expression.replacingOccurrences(of: "×", with: "*").replacingOccurrences(of: "÷", with: "/")
        let exp = NSExpression(format: expr)
        if let result = exp.expressionValue(with: nil, context: nil) as? NSNumber { return result.stringValue }
        return "ERROR"
    }
}
