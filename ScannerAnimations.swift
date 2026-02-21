#if canImport(SwiftUI)
import SwiftUI
#endif

#if os(iOS)

@available(iOS 16.0, *)
@available(iOS 16.0, *)
struct HackerProcessingAnimationView: View {
    @ObservedObject var viewModel: KineprintViewModel
    @State private var matrixOpacity: Double = 0
    @State private var showScanningRings = false
    @State private var blinkFrame = false
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
            
            // Multiple screens / frames tearing effect
            if blinkFrame {
                ForEach(0..<6) { i in
                    Rectangle()
                        .stroke(neonCyan.opacity(Double.random(in: 0.2...0.8)), lineWidth: CGFloat.random(in: 1...5))
                        .frame(width: CGFloat(Int.random(in: 100...400)), height: CGFloat(Int.random(in: 100...600)))
                        .position(x: CGFloat.random(in: 50...350), y: CGFloat.random(in: 100...700))
                        .opacity(showScanningRings ? 0 : 1)
                        .animation(.easeOut(duration: 0.2).delay(Double(i) * 0.05).repeatCount(10, autoreverses: true), value: showScanningRings)
                }
            }
            
            VStack(spacing: 20) {
                // Central processing ring melting
                ZStack {
                    if showScanningRings {
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
                        .opacity(blinkFrame ? 1 : 0)
                        .scaleEffect(glitchEffect ? 1.2 : 0.8)
                        .animation(.randomGlitch(), value: glitchEffect)
                }
                
                Text("FATAL: ANALYZING MESH ANOMALY")
                    .font(.system(size: 20, weight: .heavy, design: .monospaced))
                    .foregroundColor(glitchEffect ? neonCyan : .red)
                    .offset(x: glitchEffect ? 10 : -10)
                    .animation(.randomGlitch(), value: glitchEffect)
                
                Text("OVERRIDING REPOSITORY...")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .opacity(glitchEffect ? 0.3 : 1.0)
                    .animation(.randomGlitch(), value: glitchEffect)
            }
        }
        .onAppear {
            matrixOpacity = 1.0
            showScanningRings = true
            blinkFrame = true
            
            // Trigger intense random glitches
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if viewModel.showCapturedBlueprint {
                    timer.invalidate()
                } else {
                    glitchEffect.toggle()
                }
            }
        }
    }
}

extension Animation {
    static func randomGlitch() -> Animation {
        return Animation.interactiveSpring(response: Double.random(in: 0.05...0.2), dampingFraction: Double.random(in: 0.1...0.5), blendDuration: Double.random(in: 0.05...0.1))
    }
}

@available(iOS 16.0, *)
struct HackerRainOverlay: View {
    let columns = 20
    @State private var matrixColumns: [MatrixColumn] = []
    @State private var timer: Timer?

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
            timer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in // Insane speed
                for i in matrixColumns.indices {
                    matrixColumns[i].advance()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}

@available(iOS 16.0, *)
struct BlueprintDisplayView: View {
    @ObservedObject var viewModel: KineprintViewModel
    let entry: ResearchEntry
    
    @State private var lineProgress: CGFloat = 0
    @State private var textTitleProgress: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var showDetails: Bool = false
    @State private var rotatingAngle: Double = 0
    
    // Stark Arc Reactor Blue aesthetic
    private let draftBlue = Color(red: 0.05, green: 0.15, blue: 0.35)
    private let starkCyan = Color(red: 0.3, green: 0.9, blue: 1.0)
    private let starkWhite = Color(red: 0.9, green: 0.95, blue: 1.0)
    
    var body: some View {
        ZStack {
            draftBlue.ignoresSafeArea()
            
            // Crisp engineering grid
            EngineeringGridBackground(cyanColor: starkCyan)
                .opacity(0.6)
            
            VStack {
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
                    }
                    .opacity(textOpacity)
                }
                .padding()
                .background(Color.black.opacity(0.2))
                
                Spacer()
                
                // Holographic Arc Reactor Core representation
                ZStack {
                    // Outer structural rings
                    Circle()
                        .stroke(starkCyan.opacity(0.3), lineWidth: 1)
                        .frame(width: 320, height: 320)
                    
                    Circle()
                        .stroke(starkCyan.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                        .frame(width: 300, height: 300)
                        .rotationEffect(.degrees(rotatingAngle))
                    
                    Circle()
                        .trim(from: 0, to: lineProgress)
                        .stroke(starkWhite, lineWidth: 4)
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(-90))
                    
                    // Technical diagram lines
                    Path { path in
                        path.move(to: CGPoint(x: 150, y: 0))
                        path.addLine(to: CGPoint(x: 150, y: 300))
                        path.move(to: CGPoint(x: 0, y: 150))
                        path.addLine(to: CGPoint(x: 300, y: 150))
                    }
                    .trim(from: 0, to: lineProgress)
                    .stroke(starkCyan.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .frame(width: 300, height: 300)
                    
                    // Core Geometry (Simulated Item)
                    Path { path in
                        let width: CGFloat = 160
                        let height: CGFloat = 160
                        path.move(to: CGPoint(x: width/2, y: 0))
                        path.addLine(to: CGPoint(x: width, y: height/2))
                        path.addLine(to: CGPoint(x: width/2, y: height))
                        path.addLine(to: CGPoint(x: 0, y: height/2))
                        path.closeSubpath()
                    }
                    .trim(from: 0, to: lineProgress)
                    .stroke(starkCyan, lineWidth: 3)
                    .frame(width: 160, height: 160)
                    .background(
                        Path { path in
                            let width: CGFloat = 160
                            let height: CGFloat = 160
                            path.move(to: CGPoint(x: width/2, y: 0))
                            path.addLine(to: CGPoint(x: width, y: height/2))
                            path.addLine(to: CGPoint(x: width/2, y: height))
                            path.addLine(to: CGPoint(x: 0, y: height/2))
                            path.closeSubpath()
                        }
                        .fill(starkCyan.opacity(0.15))
                        .opacity(textOpacity)
                    )
                    
                    // Center Core text
                    VStack {
                        Text("CORE")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(starkWhite)
                        Text(entry.mass)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(starkCyan)
                    }
                    .opacity(textOpacity)
                }
                .padding(.vertical, 30)
                
                Spacer()
                
                // Extracted Information Schematic Table
                if showDetails {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("STRUCTURAL SCHEMATIC")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(starkWhite)
                            Spacer()
                            Text(entry.scanQuality)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(starkCyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(starkCyan.opacity(0.15))
                                .cornerRadius(4)
                        }
                        .padding()
                        .background(Color.black.opacity(0.4))
                        
                        VStack(spacing: 0) {
                            BlueprintDetailRow(label: "DIMENSIONS", value: entry.dimensions, color: starkCyan)
                            Divider().background(starkCyan.opacity(0.3))
                            BlueprintDetailRow(label: "MATERIAL", value: entry.material, color: starkCyan)
                            Divider().background(starkCyan.opacity(0.3))
                            BlueprintDetailRow(label: "ESTIMATED MASS", value: entry.mass, color: starkCyan)
                        }
                        .padding()
                        .background(Color.black.opacity(0.2))
                    }
                    .frame(maxWidth: .infinity)
                    .border(starkCyan.opacity(0.5), width: 1)
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotatingAngle = 360
            }
            withAnimation(.easeInOut(duration: 2.0)) {
                lineProgress = 1.0
                textOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showDetails = true
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct BlueprintDetailRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(color.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
    }
}

@available(iOS 16.0, *)
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

#endif

