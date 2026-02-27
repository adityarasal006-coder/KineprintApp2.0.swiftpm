import SwiftUI

// MARK: - GOD-TIER ABOUT PAGE: NEURAL PROTOCOL ARCHIVE
@MainActor
struct AboutProtocolView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var bootProgress: CGFloat = 0
    @State private var isActive = false
    @State private var rotatingAngle: Double = 0
    @State private var neuralPulse = 1.0
    @State private var scrollPosition: CGFloat = 0
    @State private var glitchIntensity: CGFloat = 0
    @State private var currentManualStep: Int = 0
    
    private let neonCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    private let neonViolet = Color(red: 0.6, green: 0.0, blue: 1.0)
    private let deepBlack = Color(red: 0.01, green: 0.02, blue: 0.05)
    private let gridCyan = Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.15)
    
    private let protocols: [ProtocolData] = [
        ProtocolData(icon: "brain.head.profile", title: "NEURAL_LINK", desc: "Advanced bio-digital synchronization system that maps human performance data to kinematic models. Your 'Buddy' persona is the primary bridge.", color: .cyan),
        ProtocolData(icon: "antenna.radiowaves.left.and.right", title: "LIDAR_SENSORY", desc: "Uses millimetric depth mapping to create spatial awareness benchmarks. Essential for real-world physics calibration and environment logic.", color: .purple),
        ProtocolData(icon: "shield.checkerboard", title: "SECURE_VAULT", desc: "Military-grade offline encryption (AES-256) for all lab logs and biometric passkeys. No external data transmission is permitted.", color: .green),
        ProtocolData(icon: "cpu.fill", title: "CORE_PHYSICS", desc: "Custom-built Kinematic engine capable of calculating trajectory, momentum, and energy conservation across 8 unique simulation modules.", color: .orange)
    ]
    
    var body: some View {
        ZStack {
            deepBlack.ignoresSafeArea()
            
            // --- LAYER 0: LIVING NEURAL BACKGROUND ---
            NeuralBackgroundEngine()
                .opacity(0.6)
            
            // --- LAYER 1: DATA STREAM SIDEBARS ---
            DataStreamOverlay()
                .opacity(isActive ? 0.3 : 0)
            
            // --- MAIN INTERFACE CONTENT ---
            ScrollView(showsIndicators: false) {
                VStack(spacing: 40) {
                    
                    // --- SECTION 1: HYPER HEADER ---
                    VStack(spacing: 15) {
                        HStack {
                            TargetingBracket(color: neonCyan)
                                .frame(width: 50, height: 50)
                            Spacer()
                            VStack {
                                Text("NEURAL_ARCHIVE_LIBRARIES")
                                    .font(.system(size: 26, weight: .black, design: .monospaced))
                                    .foregroundColor(neonCyan)
                                    .glow(color: neonCyan, radius: 10)
                                    .glitch(intensity: glitchIntensity)
                                
                                Text("SECURE ACCESS // KINEOS-STARK-V2.1")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            TargetingBracket(color: neonCyan)
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(180))
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 20)
                    
                    // --- SECTION 2: THE HYPER-CORE SPHERE ---
                    ZStack {
                        // Outer complex rings
                        ForEach(0..<3) { i in
                            Circle()
                                .stroke(neonCyan.opacity(0.2), lineWidth: 1)
                                .frame(width: 250 + CGFloat(i * 30), height: 250 + CGFloat(i * 30))
                                .rotation3DEffect(.degrees(rotatingAngle * Double(i + 1) * 0.5), axis: (x: 1, y: 1, z: 0))
                        }
                        
                        // Data Hexagons
                        HexGrid(color: neonCyan.opacity(0.1))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-rotatingAngle * 0.2))
                        
                        // Internal Neural Orb
                        ZStack {
                            Circle()
                                .fill(RadialGradient(colors: [neonCyan.opacity(0.6), .clear], center: .center, startRadius: 0, endRadius: 100))
                                .scaleEffect(neuralPulse)
                            
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 80))
                                .foregroundColor(neonCyan)
                                .shadow(color: neonCyan, radius: 20)
                                .scaleEffect(neuralPulse * 0.9)
                        }
                        .frame(width: 180, height: 180)
                    }
                    .padding(.vertical, 40)
                    
                    // --- SECTION 3: PROTOCOL DATA CARDS ---
                    VStack(spacing: 25) {
                        HStack {
                            Rectangle().fill(neonCyan).frame(width: 20, height: 2)
                            Text("ACTIVE_PROTOCOLS")
                                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                .foregroundColor(neonCyan)
                            Rectangle().fill(neonCyan).frame(maxWidth: .infinity, maxHeight: 2)
                        }
                        .padding(.horizontal, 24)
                        
                        ForEach(protocols) { proto in
                            HyperProtocolCard(data: proto)
                        }
                    }
                    
                    // --- SECTION 4: THE "MANUAL" HOLOGRAPH ---
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("SYS_OPERATIONAL_PROCEDURES")
                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                .foregroundColor(starkWhite)
                                .padding(.horizontal, 10)
                                .background(Color.red.opacity(0.3))
                            Spacer()
                        }
                        
                        VStack(spacing: 0) {
                            ManualStepRow(index: "01", title: "INITIALIZE_LINK", detail: "Complete the Neural Onboarding to bind your Bio-ID to the system core.", isActive: true)
                            ManualStepRow(index: "02", title: "SCAN_ARRAY", detail: "Deploy the LiDAR matrix to map 3D objects and measure gravitational vectors.", isActive: isActive)
                            ManualStepRow(index: "03", title: "LOG_EQUATIONS", detail: "Input real-world variables into the Research Lab to generate kinematic predictions.", isActive: isActive)
                            ManualStepRow(index: "04", title: "EARN_BADGES", detail: "Surpass performance benchmarks to unlock high-tier engineering certifications.", isActive: isActive)
                        }
                        .background(Color.white.opacity(0.02))
                        .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)
                    
                    // --- SECTION 5: TECH SPEC GRID ---
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            TechSpecItem(icon: "memorychip", title: "MEMORY", val: "L3_OPT")
                            TechSpecItem(icon: "bolt.fill", title: "ENERGY", val: "NOMINAL")
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            TechSpecItem(icon: "network", title: "LINK", val: "OFFLINE_SEC")
                            TechSpecItem(icon: "shield.fill", title: "SECURITY", val: "ENCRYPTED")
                        }
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(neonCyan.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 24)
                    
                    // --- FOOTER BUTTON ---
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("DISCONNECT_VAULT.X")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                LinearGradient(colors: [neonCyan, neonCyan.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                            )
                            .cornerRadius(8)
                            .shadow(color: neonCyan.opacity(0.5), radius: 15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 80)
                }
            }
        }
        .onAppear {
            startAdvancedAnimations()
        }
    }
    
    private let starkWhite = Color(red: 0.95, green: 0.98, blue: 1.0)
    
    private func startAdvancedAnimations() {
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            rotatingAngle = 360
        }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            neuralPulse = 1.15
            isActive = true
        }
        
        // Random glitch effect
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.spring()) { glitchIntensity = 1.0 }
                try? await Task.sleep(nanoseconds: 300_000_000)
                withAnimation(.spring()) { glitchIntensity = 0.0 }
            }
        }
    }
}

// MARK: - Sub-components with God-tier Aesthetics

struct HyperProtocolCard: View {
    let data: ProtocolData
    @State private var hover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 15) {
                ZStack {
                    Circle().fill(data.color.opacity(0.2)).frame(width: 45, height: 45)
                    Image(systemName: data.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(data.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.title)
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(data.color)
                    Text("MODULE STATUS: ANALYZED")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.gray)
                }
                Spacer()
                
                // Visual Shimmer
                RoundedRectangle(cornerRadius: 2)
                    .fill(data.color.opacity(0.3))
                    .frame(width: 20, height: 4)
            }
            
            Text(data.desc)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(3)
        }
        .padding(20)
        .background(
            ZStack {
                Color.white.opacity(0.03)
                // Diagonal scan reflection logic
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, .white.opacity(0.05), .clear], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .rotationEffect(.degrees(30))
                    .offset(x: hover ? 400 : -400)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(data.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                hover = true
            }
        }
    }
}

struct ManualStepRow: View {
    let index: String
    let title: String
    let detail: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            VStack {
                Text(index)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(isActive ? .black : .gray)
                Spacer()
            }
            .frame(width: 40, height: 80)
            .padding(.top, 15)
            .background(isActive ? Color(red: 0.0, green: 0.85, blue: 1.0) : Color.white.opacity(0.05))
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(isActive ? .white : .gray)
                Text(detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .padding(.leading, 20)
            
            Spacer()
        }
        .frame(height: 80)
        .overlay(Rectangle().stroke(Color.white.opacity(0.05), lineWidth: 0.5))
    }
}

struct TechSpecItem: View {
    let icon: String
    let title: String
    let val: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.cyan)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text(val)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
        }
    }
}

struct DataStreamOverlay: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        HStack {
            VStack(spacing: 4) {
                ForEach(0..<40) { _ in
                    Text("0x" + String(format: "%04X", Int.random(in: 0...65535)))
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.1))
                }
            }
            Spacer()
            VStack(spacing: 4) {
                ForEach(0..<40) { _ in
                    Text("NODE_" + String(format: "%02d", Int.random(in: 1...99)))
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.1))
                }
            }
        }
        .padding(.horizontal, 5)
        .offset(y: offset)
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                offset = -200
            }
        }
    }
}

struct NeuralBackgroundEngine: View {
    @State private var nodes: [Node] = (0..<15).map { _ in Node() }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(nodes) { node in
                    Circle()
                        .fill(Color.cyan.opacity(0.1))
                        .frame(width: node.size, height: node.size)
                        .position(x: node.x * geo.size.width, y: node.y * geo.size.height)
                        .blur(radius: 5)
                }
            }
        }
        .onAppear {
            startFloating()
        }
    }
    
    private func startFloating() {
        for i in nodes.indices {
            withAnimation(.easeInOut(duration: Double.random(in: 5...10)).repeatForever(autoreverses: true)) {
                nodes[i].x = CGFloat.random(in: 0...1)
                nodes[i].y = CGFloat.random(in: 0...1)
            }
        }
    }
    
    struct Node: Identifiable {
        let id = UUID()
        var x = CGFloat.random(in: 0...1)
        var y = CGFloat.random(in: 0...1)
        let size = CGFloat.random(in: 50...150)
    }
}

struct HexGrid: View {
    let color: Color
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let hexWidth: CGFloat = 40
                let hexHeight: CGFloat = 46
                let rows = 6
                let cols = 6
                
                for r in 0..<rows {
                    for c in 0..<cols {
                        let x = CGFloat(c) * hexWidth * 0.75
                        let y = CGFloat(r) * hexHeight + (c % 2 == 0 ? 0 : hexHeight / 2)
                        
                        // Simple Hexagon
                        for i in 0..<6 {
                            let angle = CGFloat(i) * 60 * .pi / 180
                            let px = x + hexWidth / 2 * cos(angle)
                            let py = y + hexHeight / 2 * sin(angle)
                            if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
                            else { path.addLine(to: CGPoint(x: px, y: py)) }
                        }
                        path.closeSubpath()
                    }
                }
            }
            .stroke(color, lineWidth: 1)
        }
    }
}

struct ProtocolData: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let desc: String
    let color: Color
}

// Global Glitch Modifier
extension View {
    func glitch(intensity: CGFloat) -> some View {
        self.modifier(GlitchEffect(intensity: intensity))
    }
}

struct GlitchEffect: ViewModifier {
    var intensity: CGFloat
    func body(content: Content) -> some View {
        content
            .offset(x: intensity > 0.5 ? CGFloat.random(in: -5...5) : 0)
            .shadow(color: .red.opacity(intensity), radius: 0, x: 2, y: 0)
            .shadow(color: .blue.opacity(intensity), radius: 0, x: -2, y: 0)
    }
}

#Preview {
    AboutProtocolView()
}
