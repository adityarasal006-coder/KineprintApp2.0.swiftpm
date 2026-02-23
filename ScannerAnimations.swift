import SwiftUI

struct HackerProcessingAnimationView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @State private var matrixOpacity: Double = 0
    @State private var showTerminals = false
    @State private var terminalCount = 0
    @State private var glitchEffect = false
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        ZStack {
            // Intense black background
            Color.black.ignoresSafeArea()
            
            // Re-using the matrix column view for falling elements with intense speed
            HackerRainOverlay()
                .opacity(matrixOpacity)
                .scaleEffect(glitchEffect ? 1.05 : 1.0)
                .offset(x: glitchEffect ? 5 : -5, y: glitchEffect ? 5 : -5)
                .animation(.randomGlitch(), value: glitchEffect)
            
            // Multiple Terminal Windows Opening
            if showTerminals {
                ForEach(0..<terminalCount, id: \.self) { i in
                    TerminalPopup(
                        width: CGFloat.random(in: 150...300),
                        height: CGFloat.random(in: 100...250),
                        offset: CGSize(width: CGFloat.random(in: -100...100), height: CGFloat.random(in: -200...200)),
                        lines: generateRandomCodes(lines: Int.random(in: 5...12)),
                        title: "sys_override_\(i).exe"
                    )
                    .scaleEffect(glitchEffect ? 1.05 : 0.95)
                    .animation(.randomGlitch().delay(Double(i) * 0.05), value: glitchEffect)
                }
            }
            
            VStack(spacing: 20) {
                // Central processing ring melting
                ZStack {
                    if showTerminals {
                        Circle()
                            .stroke(Color.red.opacity(0.8), lineWidth: 8)
                            .frame(width: 250, height: 250)
                            .scaleEffect(glitchEffect ? 1.1 : 0.9)
                            .animation(.randomGlitch(), value: glitchEffect)
                        
                        Circle()
                            .trim(from: 0, to: 1)
                            .stroke(neonCyan, style: StrokeStyle(lineWidth: 10, dash: [20, 10, 50, 5]))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(glitchEffect ? 360 : -360))
                            .animation(.linear(duration: 0.5).repeatForever(autoreverses: false), value: glitchEffect)
                    }
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(glitchEffect ? .white : .red)
                        .opacity(showTerminals ? 1 : 0)
                        .scaleEffect(glitchEffect ? 1.2 : 0.8)
                        .animation(.randomGlitch(), value: glitchEffect)
                }
                
                Text("ANALYZING SPATIAL MESH")
                    .font(.system(size: 20, weight: .heavy, design: .monospaced))
                    .foregroundColor(glitchEffect ? neonCyan : .red)
                    .offset(x: glitchEffect ? 10 : -10)
                    .animation(.randomGlitch(), value: glitchEffect)
                
                Text("GENERATING TONY STARK BLUEPRINT...")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .opacity(glitchEffect ? 0.3 : 1.0)
                    .animation(.randomGlitch(), value: glitchEffect)
            }
        }
        .onAppear {
            matrixOpacity = 1.0
            
            // Gradually pop up terminals
            Task { @MainActor in
                for _ in 0..<8 {
                    try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s
                    guard !Task.isCancelled else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        showTerminals = true
                        terminalCount += 1
                    }
                }
            }
            
            // Trigger intense random glitches
            Task { @MainActor in
                while !Task.isCancelled {
                    if viewModel.showCapturedBlueprint {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                    glitchEffect.toggle()
                }
            }
        }
    }
    
    private func generateRandomCodes(lines: Int) -> [String] {
        let codeSnippets = [
            "0x000F: MOV EAX, [EBP-4]",
            "DECRYPTING SECTOR 7G...",
            "0x001A: XOR EBX, EBX",
            "OVERRIDE_ACTIVE=TRUE",
            "CONNECTING TO MAINFRAME...",
            "0x002B: JMP 0x003F",
            "UPLOADING KINEMATIC DATA...",
            "BYPASSING SECURITY PROTOCOL...",
            "0x004C: PUSH ECX",
            "INITIALIZING ARC REACTOR CORE..."
        ]
        return (0..<lines).map { _ in codeSnippets.randomElement()! }
    }
}


extension Animation {
    static func randomGlitch() -> Animation {
        return Animation.interactiveSpring(response: Double.random(in: 0.05...0.2), dampingFraction: Double.random(in: 0.1...0.5), blendDuration: Double.random(in: 0.05...0.1))
    }
}

struct TerminalPopup: View {
    let width: CGFloat
    let height: CGFloat
    let offset: CGSize
    let lines: [String]
    let title: String
    
    private let neonCyan = Color(red: 0, green: 1, blue: 0.85)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(neonCyan)
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Circle().fill(Color.yellow).frame(width: 8, height: 8)
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(red: 0.1, green: 0.15, blue: 0.2))
            
            // Body
            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines.indices, id: \.self) { i in
                    Text(lines[i])
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.green)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.85))
        }
        .frame(width: width, height: height)
        .border(neonCyan.opacity(0.6), width: 1)
        .offset(offset)
        .shadow(color: neonCyan.opacity(0.4), radius: 15)
    }
}

struct HackerRainOverlay: View {
    let columns = 20
    @State private var matrixColumns: [MatrixColumn] = []
    @State private var isMatrixRunning = false

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(matrixColumns.indices, id: \.self) { i in
                    MatrixColumnView(column: matrixColumns[i], screenHeight: geo.size.height)
                        .frame(width: geo.size.width / CGFloat(columns))
                }
            }
        }
        .onAppear {
            let chars = Array("01ｦｧｨｩｪｫｬｭｮｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ!@#$%^&*")
            matrixColumns = (0..<columns).map { _ in
                MatrixColumn(
                    chars: chars,
                    speed: Double.random(in: 0.02...0.08), // Faster drop
                    startDelay: Double.random(in: 0...0.2),
                    length: Int.random(in: 15...35),
                    currentRow: Int.random(in: 0...40),
                    opacity: Double.random(in: 0.6...1.0)
                )
            }
            isMatrixRunning = true
            Task { @MainActor in
                while isMatrixRunning {
                    try? await Task.sleep(nanoseconds: 40_000_000) // 0.04s
                    guard !Task.isCancelled && isMatrixRunning else { break }
                    for i in matrixColumns.indices {
                        matrixColumns[i].advance()
                    }
                }
            }
        }
        .onDisappear {
            isMatrixRunning = false
        }
    }
}

struct BlueprintDisplayView: View {
    @ObservedObject var viewModel: KineprintViewModel
    let entry: ResearchEntry
    
    @State private var lineProgress: CGFloat = 0
    @State private var textTitleProgress: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var showDetails: Bool = false
    @State private var rotatingAngle: Double = 0
    
    // Stark Arc Reactor Blue aesthetic
    private let draftBlue = Color(red: 0.02, green: 0.08, blue: 0.15)
    private let starkCyan = Color(red: 0.0, green: 0.85, blue: 1.0)
    private let starkWhite = Color(red: 0.9, green: 0.95, blue: 1.0)
    
    var body: some View {
        ZStack {
            draftBlue.ignoresSafeArea()
            
            // Crisp engineering grid
            EngineeringGridBackground(cyanColor: starkCyan)
                .opacity(0.4)
            
            VStack {
                // Header
                HStack {
                    Button(action: {
                        viewModel.dismissBlueprintView()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(starkCyan)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("PROJECT: KINEPRINT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(starkCyan.opacity(0.8))
                        Text(entry.title.uppercased())
                            .font(.system(size: 20, weight: .heavy, design: .monospaced))
                            .foregroundColor(starkWhite)
                        Text("PRACTICAL KNOWLEDGE DATABASE: ACTIVE")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(starkCyan)
                    }
                    .opacity(textOpacity)
                }
                .padding()
                .background(Color.black.opacity(0.4))
                .border(starkCyan.opacity(0.3), width: 1)
                
                Spacer()
                
                // Blueprint Core & Data Nodes
                ZStack {
                    // Lines connecting center to nodes
                    if showDetails {
                        GeometryReader { geo in
                            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                            Path { p in
                                // Center to Top Left
                                p.move(to: center)
                                p.addLine(to: CGPoint(x: center.x - 100, y: center.y - 100))
                                p.addLine(to: CGPoint(x: center.x - 150, y: center.y - 100))
                                
                                // Center to Top Right
                                p.move(to: center)
                                p.addLine(to: CGPoint(x: center.x + 100, y: center.y - 100))
                                p.addLine(to: CGPoint(x: center.x + 150, y: center.y - 100))
                                
                                // Center to Bottom Left
                                p.move(to: center)
                                p.addLine(to: CGPoint(x: center.x - 100, y: center.y + 100))
                                p.addLine(to: CGPoint(x: center.x - 150, y: center.y + 100))
                                
                                // Center to Bottom Right
                                p.move(to: center)
                                p.addLine(to: CGPoint(x: center.x + 100, y: center.y + 100))
                                p.addLine(to: CGPoint(x: center.x + 150, y: center.y + 100))
                            }
                            .trim(from: 0, to: lineProgress)
                            .stroke(starkCyan.opacity(0.6), lineWidth: 1.5)
                        }
                        .frame(height: 300)
                    }

                    // Holographic Arc Reactor Core representation
                    ZStack {
                        Circle()
                            .stroke(starkCyan.opacity(0.3), lineWidth: 1)
                            .frame(width: 220, height: 220)
                        
                        Circle()
                            .stroke(starkCyan.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(rotatingAngle))
                        
                        Circle()
                            .trim(from: 0, to: lineProgress)
                            .stroke(starkWhite, lineWidth: 4)
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                        
                        // Technical diagram lines
                        Path { path in
                            path.move(to: CGPoint(x: 100, y: 0))
                            path.addLine(to: CGPoint(x: 100, y: 200))
                            path.move(to: CGPoint(x: 0, y: 100))
                            path.addLine(to: CGPoint(x: 200, y: 100))
                        }
                        .trim(from: 0, to: lineProgress)
                        .stroke(starkCyan.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(width: 200, height: 200)
                        
                        // Core Geometry (Actual or Simulated Item)
                        if let imagePath = entry.imagePath, let uiImage = UIImage(contentsOfFile: imagePath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .colorMultiply(starkCyan) // Applies hologram tint
                                .opacity(textOpacity)
                                .shadow(color: starkCyan.opacity(0.8), radius: 20)
                        } else {
                            // Fallback Geometry
                            Path { path in
                                let width: CGFloat = 100
                                let height: CGFloat = 100
                                path.move(to: CGPoint(x: width/2, y: 0))
                                path.addLine(to: CGPoint(x: width, y: height/2))
                                path.addLine(to: CGPoint(x: width/2, y: height))
                                path.addLine(to: CGPoint(x: 0, y: height/2))
                                path.closeSubpath()
                            }
                            .trim(from: 0, to: lineProgress)
                            .stroke(starkCyan, lineWidth: 3)
                            .frame(width: 100, height: 100)
                            .background(
                                Path { path in
                                    let width: CGFloat = 100
                                    let height: CGFloat = 100
                                    path.move(to: CGPoint(x: width/2, y: 0))
                                    path.addLine(to: CGPoint(x: width, y: height/2))
                                    path.addLine(to: CGPoint(x: width/2, y: height))
                                    path.addLine(to: CGPoint(x: 0, y: height/2))
                                    path.closeSubpath()
                                }
                                .fill(starkCyan.opacity(0.15))
                                .opacity(textOpacity)
                            )
                        }
                    }
                    .frame(height: 300)
                    
                    // Data Nodes
                    if showDetails {
                        VStack(spacing: 160) {
                            HStack {
                                BlueprintDataNode(title: "DIMENSIONS", val1: "W: \(entry.dimensions)", val2: "H: CALCULATED", color: starkCyan)
                                Spacer()
                                BlueprintDataNode(title: "MATERIAL", val1: "TYPE: \(entry.material)", val2: "DENSITY: Unknown", color: starkCyan)
                            }
                            HStack {
                                BlueprintDataNode(title: "KINEMATICS", val1: "MASS: \(entry.mass)", val2: "STRUCT: VERIFIED", color: starkCyan)
                                Spacer()
                                BlueprintDataNode(title: "ANALYSIS", val1: "QUAL: \(entry.scanQuality)", val2: "STATUS: STABLE", color: starkCyan)
                            }
                        }
                        .padding(.horizontal, 20)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                Spacer()
                
                if showDetails {
                    Text("PRACTICAL FIELD KNOWLEDGE EXTRACTED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(starkCyan.opacity(0.8))
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            lineProgress = 0.0
            withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                rotatingAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.5)) {
                lineProgress = 1.0
                textOpacity = 1.0
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showDetails = true
                }
            }
        }
    }
}

struct BlueprintDataNode: View {
    let title: String
    let val1: String
    let val2: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
                .border(color.opacity(0.5), width: 1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(val1)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white)
                Text(val2)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.leading, 4)
            .padding(.bottom, 4)
        }
        .frame(width: 130, alignment: .leading)
    }
}

struct EngineeringGridBackground: View {
    let cyanColor: Color
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                
                // Fine grid
                let fineSpacing: CGFloat = 10
                for x in stride(from: 0, through: width, by: fineSpacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                for y in stride(from: 0, through: height, by: fineSpacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(cyanColor.opacity(0.1), lineWidth: 0.5)
            
            Path { path in
                let width = geo.size.width
                let height = geo.size.height
                
                // Thick grid
                let thickSpacing: CGFloat = 50
                for x in stride(from: 0, through: width, by: thickSpacing) {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                for y in stride(from: 0, through: height, by: thickSpacing) {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(cyanColor.opacity(0.3), lineWidth: 1.0)
        }
    }
}



