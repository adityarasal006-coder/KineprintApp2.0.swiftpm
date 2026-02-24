#if os(iOS)
import SwiftUI

struct RevisionCard: Identifiable {
    let id = UUID()
    let category: String
    let code: String
    let title: String
    let formula: String
    let subtitle: String
    let deepElaboration: String
    let icon: String
}

struct ResearchLibraryView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory = "ALL SYSTEM FILES"
    let categories = ["ALL SYSTEM FILES", "MATHEMATICS", "KINEMATICS", "QUANTUM PHYSICS", "AI & IOT"]
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    let flashcards: [RevisionCard] = [
        RevisionCard(category: "MATHEMATICS", code: "MTH-001", title: "Euler's Identity", formula: "e^(iπ) + 1 = 0", subtitle: "The most beautiful equation in mathematics.", deepElaboration: "Links five fundamental analytical constants into a single formula. Used heavily in complex analysis, quantum mechanics, and electrical engineering for signal processing applications. Represents the fundamental cyclic nature of reality.", icon: "function"),
        RevisionCard(category: "QUANTUM PHYSICS", code: "QTM-001", title: "Schrödinger Equation", formula: "iℏ ∂Ψ/∂t = HΨ", subtitle: "Governs the wave function of a quantum-mechanical system.", deepElaboration: "Describes how the quantum state of a physical system changes in time. At the core of all modern physics, dictating probability amplitudes rather than deterministic trajectories, essentially allowing the calculation of tunneling arrays and energetic particle distribution.", icon: "atom"),
        RevisionCard(category: "KINEMATICS", code: "KIN-001", title: "Critical Damping", formula: "c = 2√(m·k)", subtitle: "System returns to equilibrium as fast as possible without oscillating.", deepElaboration: "Essential in suspension design and robotic servos. An underdamped system oscillates wildly; overdamped returns too slowly. Critical damping achieves exact stabilization, minimizing the settling time of kinetic force impacts.", icon: "spring"),
        RevisionCard(category: "AI & IOT", code: "AIO-001", title: "Backpropagation Matrix", formula: "∆w = -η (∂E/∂w)", subtitle: "The core mechanic of neural network training algorithms.", deepElaboration: "Utilizes the chain rule of calculus to compute gradients of the loss function with respect to every weight. Allows deep architectures to 'learn' by minimizing multidimensional error landscapes in recursive data structures.", icon: "network"),
        RevisionCard(category: "MATHEMATICS", code: "MTH-002", title: "Navier-Stokes Equations", formula: "ρ(∂v/∂t + v·∇v) = -∇p + μ∇²v + f", subtitle: "Describes the motion of viscous fluid substances.", deepElaboration: "A set of nonlinear partial differential equations bounding fluid dynamics. Understanding exact solutions remains a Millennium Prize Problem. Applied in aerodynamics, weather modeling, and hydrodynamic vector simulations.", icon: "wind"),
        RevisionCard(category: "KINEMATICS", code: "KIN-002", title: "Orbital Escape Velocity", formula: "v = √(2GM/r)", subtitle: "Velocity needed to break free from a gravitational field.", deepElaboration: "Dictates exactly how spacecraft exit orbit. Any speed less than this results in a stable or decaying elliptical orbit. Achieving this velocity pushes the object into a parabolic or hyperbolic trajectory into deep space.", icon: "globe"),
        RevisionCard(category: "QUANTUM PHYSICS", code: "QTM-002", title: "Heisenberg Uncertainty", formula: "ΔxΔp ≥ ℏ/2", subtitle: "Fundamental limit to the precision of complementary variables.", deepElaboration: "Proves that the universe is probabilistic at its core. You cannot simultaneously know the exact position and momentum of a particle; the very act of observation interferes with the state matrix.", icon: "aqi.medium"),
        RevisionCard(category: "MATHEMATICS", code: "MTH-003", title: "Eigenvector Centrality", formula: "Ax = λx", subtitle: "Influence of a node in a network architecture.", deepElaboration: "Vectors that only stretch and do not rotate during a linear transformation. Crucial for Google's PageRank algorithm, principal component analysis (PCA), and structural stability mappings in autonomous systems.", icon: "square.grid.3x3.topleft.filled"),
        RevisionCard(category: "AI & IOT", code: "AIO-002", title: "Shannon’s Information Limit", formula: "C = B log₂(1 + S/N)", subtitle: "The theoretical maximum rate of error-free data transmission.", deepElaboration: "Defines the absolute limit of network bandwidth. IoT devices must optimize their signal-to-noise ratio to bypass atmospheric interference, governing all telemetry uplinks.", icon: "antenna.radiowaves.left.and.right")
    ]
    
    var filteredCards: [RevisionCard] {
        if selectedCategory == "ALL SYSTEM FILES" { return flashcards }
        return flashcards.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            EngineeringGridBackground(cyanColor: neonCyan).opacity(0.2)
            
            VStack(spacing: 0) {
                // ═══ HEADER ═══
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(neonCyan.opacity(0.15)).frame(width: 36, height: 36)
                        Image(systemName: "graduationcap.fill")
                            .foregroundColor(neonCyan)
                            .font(.system(size: 16))
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("REVISION_FLASHCARDS")
                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Text("[\(flashcards.count)]")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(neonCyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(neonCyan.opacity(0.1))
                                .cornerRadius(4)
                        }
                        HStack(spacing: 6) {
                            Circle().fill(.green).frame(width: 6, height: 6)
                                .shadow(color: .green, radius: 4)
                            Text("ALL DATANODES LOADED")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(.green.opacity(0.7))
                        }
                    }
                    Spacer()
                    Image(systemName: "cpu")
                        .foregroundColor(neonCyan.opacity(0.5))
                        .font(.system(size: 18))
                }
                .padding()
                .background(Color.black.opacity(0.85))
                .overlay(
                    Rectangle().frame(height: 1).foregroundColor(neonCyan.opacity(0.3)), alignment: .bottom
                )
                
                // ═══ CATEGORY SELECTOR ═══
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { cat in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = cat
                                }
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                            }) {
                                Text(cat)
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(selectedCategory == cat ? .black : neonCyan.opacity(0.7))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                    .background(selectedCategory == cat ? neonCyan : Color.white.opacity(0.04))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedCategory == cat ? neonCyan : neonCyan.opacity(0.2), lineWidth: selectedCategory == cat ? 2 : 1)
                                    )
                                    .shadow(color: selectedCategory == cat ? neonCyan.opacity(0.4) : .clear, radius: 8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 14)
                }
                .background(Color.black.opacity(0.3))
                
                // ═══ FLASHCARD FEED ═══
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 24) {
                        ForEach(filteredCards) { card in
                            FlashcardView(card: card)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 120)
                }
            }
        }
    }
}

struct FlashcardView: View {
    let card: RevisionCard
    @State private var rotation: Double = 0
    @State private var hoverOffset: CGFloat = 0
    @State private var isFlipped = false
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
            // FRONT OF CARD
            frontView
                .opacity(rotation < 90 ? 1 : 0)
            
            // BACK OF CARD
            backView
                .opacity(rotation >= 90 ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 320)
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .offset(y: hoverOffset)
        .onAppear {
            // Holographic hovering effect
            withAnimation(Animation.easeInOut(duration: Double.random(in: 2.0...3.0)).repeatForever(autoreverses: true)) {
                hoverOffset = CGFloat.random(in: -8...8)
            }
        }
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.5)) {
                isFlipped.toggle()
                rotation = isFlipped ? 180 : 0
            }
        }
    }
    
    // MARK: FRONT VIEW
    private var frontView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Bar
            HStack {
                HStack(spacing: 4) {
                    Circle().fill(neonCyan).frame(width: 8, height: 8)
                        .scaleEffect(isFlipped ? 0.5 : 1)
                        .animation(Animation.easeInOut(duration: 0.5).repeatForever(), value: isFlipped)
                    Text(card.category)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(neonCyan)
                }
                Spacer()
                Text(card.code)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Central Formula Hologram
            HStack {
                Spacer()
                ZStack {
                    // Glowing aura
                    Text(card.formula)
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .foregroundColor(neonCyan.opacity(0.3))
                        .blur(radius: 10)
                    
                    Text(card.formula)
                        .font(.system(size: 28, weight: .black, design: .serif))
                        .foregroundColor(.white)
                        .shadow(color: neonCyan, radius: 2)
                }
                Spacer()
            }
            .frame(height: 100)
            .background(
                ZStack {
                    // Futuristic inner grid
                    Image(systemName: "square.grid.3x3.fill")
                        .resizable()
                        .foregroundColor(neonCyan.opacity(0.05))
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Color.black.opacity(0.4)
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LinearGradient(gradient: Gradient(colors: [neonCyan, .clear, neonCyan]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            
            Spacer()
            
            // Title & Icon
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.title.uppercased())
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: neonCyan.opacity(0.5), radius: 5)
                    Text(card.subtitle)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: card.icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(neonCyan)
            }
        }
        .padding(24)
        .background(
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.08)
                
                // Tech circuit lines
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 50))
                    path.addLine(to: CGPoint(x: 20, y: 50))
                    path.addLine(to: CGPoint(x: 40, y: 30))
                    path.addLine(to: CGPoint(x: 100, y: 30))
                }.stroke(neonCyan.opacity(0.2), lineWidth: 1)
                
                Path { path in
                    path.move(to: CGPoint(x: 300, y: 250))
                    path.addLine(to: CGPoint(x: 280, y: 250))
                    path.addLine(to: CGPoint(x: 260, y: 270))
                    path.addLine(to: CGPoint(x: 200, y: 270))
                }.stroke(neonCyan.opacity(0.2), lineWidth: 1)
            }
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(LinearGradient(gradient: Gradient(colors: [neonCyan.opacity(0.8), .clear, neonCyan.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
        )
        .shadow(color: neonCyan.opacity(0.2), radius: 15)
    }
    
    // MARK: BACK VIEW
    private var backView: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            // Decrypted Header
            HStack {
                Image(systemName: "lock.open.display")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
                    .shadow(color: .green, radius: 5)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("CORE LOGIC DECRYPTED")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(.green)
                    Text("ACCESSLEVEL: OMEGA")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.green.opacity(0.6))
                }
                Spacer()
                Text("TAP TO SECURE")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 8)
            .overlay(Rectangle().frame(height: 1).foregroundColor(.green.opacity(0.3)).offset(y: 25), alignment: .bottom)
            
            // Detailed Elaboration Matrix
            ScrollView(showsIndicators: false) {
                Text(card.deepElaboration)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(6)
                    .shadow(color: .white.opacity(0.1), radius: 2)
            }
            
            Spacer()
            
            // Hexadecimal Footer
            HStack {
                Text(generateHex())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.green.opacity(0.4))
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.green)
            }
        }
        .padding(24)
        .background(
            ZStack {
                Color(red: 0.0, green: 0.1, blue: 0.0) // Deep dark green
                
                // Matrix digital rain fake background
                GeometryReader { geo in
                    ForEach(0..<10) { i in
                        Text(generateHex())
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.green.opacity(0.1))
                            .rotationEffect(.degrees(90))
                            .position(x: CGFloat.random(in: 0...geo.size.width), y: CGFloat.random(in: 0...geo.size.height))
                    }
                }
            }
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.green.opacity(0.6), lineWidth: 2)
        )
        .shadow(color: Color.green.opacity(0.3), radius: 20)
    }
    
    private func generateHex() -> String {
        let letters = "0123456789ABCDEF"
        return "0x" + String((0..<8).map{ _ in letters.randomElement()! })
    }
}
#endif
