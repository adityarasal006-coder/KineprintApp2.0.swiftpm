import SwiftUI

// MARK: - Shared Core Branding system

public struct CoreDisplayView: View {
    public let type: CoreShape
    public let color: Color
    
    public init(type: CoreShape, color: Color) {
        self.type = type
        self.color = color
    }
    
    public var body: some View {
        ZStack {
            // Background Pulse for the chosen color
            Circle()
                .fill(color.opacity(0.12))
                .glow(color: color.opacity(0.3), radius: 20)
            
            // Outer Frame
            Circle()
                .stroke(color.opacity(0.4), lineWidth: 1)
                .padding(4)
            
            // Abstract Core Icon
            Image(systemName: type.icon)
                .resizable()
                .scaledToFit()
                .padding(25)
                .foregroundColor(color)
                .shadow(color: color.opacity(0.8), radius: 10)
        }
    }
}





// MARK: - Core Identity Circle
public struct CoreIdentityCircle: View {
    public let avatarType: CoreShape
    public let avatarColor: Color
    public let backgroundTheme: AvatarBackgroundTheme
    public let profileImageData: Data?
    public let size: CGFloat
    
    @State private var radarRotation: Double = 0
    
    public init(avatarType: CoreShape, avatarColor: Color, backgroundTheme: AvatarBackgroundTheme, profileImageData: Data? = nil, size: CGFloat = 200) {
        self.avatarType = avatarType
        self.avatarColor = avatarColor
        self.backgroundTheme = backgroundTheme
        self.profileImageData = profileImageData
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Ambient glow matching avatar color
            RadialGradient(
                gradient: Gradient(colors: [avatarColor.opacity(0.3), .clear]),
                center: .center,
                startRadius: size * 0.1,
                endRadius: size * 0.75
            )
            .frame(width: size * 1.5, height: size * 1.5)
            
            // Outer ring system
            Circle()
                .stroke(avatarColor.opacity(0.2), lineWidth: 1)
                .frame(width: size * 1.25, height: size * 1.25)
                .rotationEffect(.degrees(radarRotation / 2))
                
            // Tick marks
            Circle()
                .stroke(avatarColor.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [4, 16]))
                .frame(width: size * 1.15, height: size * 1.15)
                .rotationEffect(.degrees(-radarRotation))
            
            // Scanner sweep
            if size > 100 { // Only show sweep on larger versions
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.clear, avatarColor.opacity(0.8)]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: max(2, size * 0.02), lineCap: .round)
                    )
                    .frame(width: size * 1.3, height: size * 1.3)
                    .rotationEffect(.degrees(radarRotation))
            }
            
            // The User's Background Theme (clipped perfectly inside the circle!)
            AvatarBackgroundEngine(theme: backgroundTheme, color: avatarColor)
                .frame(width: size, height: size)
                .clipShape(Circle())
            
            // The user's specific Neural Identity Core
            if let imageData = profileImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(avatarColor, lineWidth: 2))
            } else {
                Avatar3DView(avatarType: avatarType, avatarColor: avatarColor, isExpanded: false)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            }
            
            // Glass reflections over the top
            Circle()
                .stroke(LinearGradient(colors: [.white.opacity(0.5), .clear, .clear, .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                radarRotation = 360
            }
        }
    }
}

// MARK: - Legacy Structural Aesthetics

public struct EngineeringGridBackground: View {
    public let cyanColor: Color
    @State private var phase: CGFloat = 0
    @State private var matrixDots: [(CGPoint, String)] = []
    
    public init(cyanColor: Color) {
        self.cyanColor = cyanColor
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated Matrix Hex Background
                ForEach(0..<matrixDots.count, id: \.self) { i in
                    Text(matrixDots[i].1)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(cyanColor.opacity(0.15))
                        .position(matrixDots[i].0)
                        .animation(.linear(duration: Double.random(in: 1...3)), value: matrixDots[i].0)
                }
                
                // Animated Holo-Grid
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let spacing: CGFloat = 40
                    
                    // Vertical lines (static horizontal positions, but we could animate phase)
                    for i in stride(from: 0, through: width, by: spacing) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i, y: height))
                    }
                    
                    // Horizontal lines slowly drifting down
                    for i in stride(from: -spacing, through: height + spacing, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: i + phase))
                        path.addLine(to: CGPoint(x: width, y: i + phase))
                    }
                }
                .stroke(cyanColor.opacity(0.2), lineWidth: 1)
                // Add a glowing central mask so the edges fade out into darkness
                .mask(
                    RadialGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0.8), .clear]), center: .center, startRadius: 50, endRadius: geometry.size.height / 1.5)
                )
            }
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    phase = 40
                }
                // Generate random floating hex codes
                for _ in 0..<30 {
                    let randomPoint = CGPoint(x: CGFloat.random(in: 0...geometry.size.width), y: CGFloat.random(in: 0...geometry.size.height))
                    let letters = "0123456789ABCDEF"
                    let randomHex = "0x" + String((0..<4).map{ _ in letters.randomElement()! })
                    matrixDots.append((randomPoint, randomHex))
                }
            }
            .onReceive(Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()) { _ in
                // Slowly perturb the hex codes to look alive
                for i in 0..<matrixDots.count {
                    let old = matrixDots[i].0
                    let newPoint = CGPoint(x: old.x + CGFloat.random(in: -10...10), y: old.y + CGFloat.random(in: -10...10))
                    matrixDots[i].0 = newPoint
                }
            }
        }
    }
}

public struct BlueprintDataNode: View {
    public let title: String
    public let val1: String
    public let val2: String
    public let color: Color
    
    public init(title: String, val1: String, val2: String, color: Color) {
        self.title = title
        self.val1 = val1
        self.val2 = val2
        self.color = color
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.6))
            Text(val1)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(val2)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color.opacity(0.8))
            Rectangle()
                .frame(height: 1)
                .foregroundColor(color.opacity(0.3))
        }
        .frame(minWidth: 100, alignment: .leading)
    }
}

