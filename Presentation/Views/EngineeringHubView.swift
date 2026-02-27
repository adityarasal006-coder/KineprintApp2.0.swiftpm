import SwiftUI

struct EngineeringHubView: View {
    @State private var activeModule: EngineeringModule? = nil
    @State private var cardAppeared: [Bool] = [false, false, false]
    @State private var titleGlitch = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)

    enum EngineeringModule: String, CaseIterable, Identifiable {
        case iot = "IoT & Robotics Control"
        case physics = "Modern Physics Engine"
        case math = "Advanced Mathematics"
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .iot: return "cpu"
            case .physics: return "atom"
            case .math: return "function"
            }
        }
        
        var description: String {
            switch self {
            case .iot: return "Hardware integration, robotics telemetry, and sensor feedback loops."
            case .physics: return "Simulate superposition, entanglement, tunneling, and kinematics."
            case .math: return "Calculus, linear algebra, formulas, and structural mathematics."
            }
        }
        
        var accentColor: Color {
            switch self {
            case .iot: return Color(red: 0, green: 1, blue: 0.85)
            case .physics: return Color.purple
            case .math: return Color.orange
            }
        }
        
        var code: String {
            switch self {
            case .iot: return "MOD-IOT-01"
            case .physics: return "MOD-PHY-02"
            case .math: return "MOD-MTH-03"
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            EngineeringGridBackground(cyanColor: neonCyan).opacity(0.3)
            
            if let module = activeModule {
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            withAnimation(.spring()) {
                                activeModule = nil
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                Text("HUB")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(neonCyan)
                        }
                        Spacer()
                        HStack(spacing: 8) {
                            Circle().fill(module.accentColor).frame(width: 8, height: 8)
                                .shadow(color: module.accentColor, radius: 5)
                            Text(module.rawValue.uppercased())
                                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.9))
                    .overlay(
                        Rectangle().frame(height: 1).foregroundColor(module.accentColor.opacity(0.4)), alignment: .bottom
                    )
                    
                    // Module Content View
                    switch module {
                    case .iot:
                        IoTControlHubView()
                    case .physics:
                        LearningLabView()
                    case .math:
                        MathematicsView()
                    }
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                VStack(spacing: 16) {
                    Spacer().frame(height: 30)
                    
                    // Title Block
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Rectangle().fill(neonCyan).frame(width: 20, height: 2)
                            Text("SYSTEM ACCESS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan.opacity(0.7))
                            Rectangle().fill(neonCyan).frame(width: 20, height: 2)
                        }
                        
                        Text("ENGINEERING HUB")
                            .font(.system(size: 30, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .shadow(color: neonCyan.opacity(0.3), radius: titleGlitch ? 10 : 0)
                            .offset(x: titleGlitch ? CGFloat.random(in: -3...3) : 0)
                        
                        Text("SELECT A DISCIPLINE CORE TO INITIALIZE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 10)
                        
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(Array(EngineeringModule.allCases.enumerated()), id: \.element.id) { index, module in
                                Button(action: {
                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        activeModule = module
                                    }
                                }) {
                                    HubModuleCard(module: module)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .opacity(cardAppeared[index] ? 1 : 0)
                                .offset(y: cardAppeared[index] ? 0 : 40)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                    Spacer()
                }
                .transition(.opacity)
                .onAppear {
                    // Staggered entrance animation
                    for i in 0..<3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                cardAppeared[i] = true
                            }
                        }
                    }
                    // Periodic title glitch
                    Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
                        DispatchQueue.main.async {
                            titleGlitch = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                                titleGlitch = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Hub Module Card
struct HubModuleCard: View {
    let module: EngineeringHubView.EngineeringModule
    @State private var iconRotation: Double = 0
    @State private var statusPulse = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        HStack(spacing: 18) {
            // Animated Icon Ring
            ZStack {
                // Outer rotating dashed ring
                Circle()
                    .stroke(module.accentColor.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(iconRotation))
                
                // Inner solid ring
                Circle()
                    .fill(module.accentColor.opacity(0.1))
                    .frame(width: 52, height: 52)
                
                Image(systemName: module.icon)
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(module.accentColor)
                    .shadow(color: module.accentColor.opacity(0.5), radius: 5)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(module.rawValue.uppercased())
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                Text(module.description)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Circle().fill(module.accentColor).frame(width: 6, height: 6)
                        .shadow(color: module.accentColor, radius: statusPulse ? 6 : 2)
                        .scaleEffect(statusPulse ? 1.3 : 1)
                    Text(module.code)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(module.accentColor.opacity(0.7))
                    Spacer()
                    Text("READY")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(module.accentColor.opacity(0.6))
                .font(.system(size: 14, weight: .bold))
        }
        .padding(20)
        .background(
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.08)
                
                // Subtle circuit line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 35))
                    path.addLine(to: CGPoint(x: 15, y: 35))
                    path.addLine(to: CGPoint(x: 30, y: 20))
                    path.addLine(to: CGPoint(x: 70, y: 20))
                }
                .stroke(module.accentColor.opacity(0.1), lineWidth: 1)
            }
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(gradient: Gradient(colors: [module.accentColor.opacity(0.6), module.accentColor.opacity(0.1), module.accentColor.opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
        )
        .shadow(color: module.accentColor.opacity(0.15), radius: 12)
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                iconRotation = 360
            }
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                statusPulse = true
            }
        }
    }
}
