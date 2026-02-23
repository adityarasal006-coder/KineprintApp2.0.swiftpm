import SwiftUI

// MARK: - Shared Core Branding system

public enum CoreShape: String, CaseIterable, Identifiable {
    case sphere, tetrahedron, torus, helix, icosahedron, box
    case robot1, robot2, robot3, robot4, scout, warrior, titan, core, drone, spark, android, nexus
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .sphere, .robot1, .scout: return "circle.fill"
        case .tetrahedron, .robot2, .warrior: return "triangle.fill"
        case .torus, .robot3, .titan: return "largecircle.fill.circle"
        case .helix, .robot4, .core: return "infinity.circle.fill"
        case .icosahedron, .drone, .spark: return "hexagon.fill"
        case .box, .android, .nexus: return "square.fill"
        }
    }
    
    public var name: String {
        switch self {
        case .sphere, .robot1, .scout: return "Quantum Orb"
        case .tetrahedron, .robot2, .warrior: return "Singularity Point"
        case .torus, .robot3, .titan: return "Energy Torus"
        case .helix, .robot4, .core: return "DNA Helix Core"
        case .icosahedron, .drone, .spark: return "Icosahedron"
        case .box, .android, .nexus: return "Tesseract"
        }
    }
    
    public static var allModels: [CoreShape] {
        return [.sphere, .tetrahedron, .torus, .helix, .icosahedron, .box]
    }
}

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

extension View {
    public func glow(color: Color, radius: CGFloat) -> some View {
        self.shadow(color: color, radius: radius)
            .shadow(color: color, radius: radius / 2)
    }
}

extension Color {
    public static func fromName(_ name: String) -> Color {
        switch name {
        case "orange": return .orange
        case "pink": return .pink
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        default: return .cyan
        }
    }
    
    // Hex Support for AppStorage
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    
    public func toHex() -> String {
        let uic = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uic.getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "#%06x", rgb)
    }
}

// MARK: - Core Identity Circle
public struct CoreIdentityCircle: View {
    public let avatarType: CoreShape
    public let avatarColor: Color
    public let backgroundTheme: AvatarBackgroundTheme
    public let size: CGFloat
    
    @State private var radarRotation: Double = 0
    
    public init(avatarType: CoreShape, avatarColor: Color, backgroundTheme: AvatarBackgroundTheme, size: CGFloat = 200) {
        self.avatarType = avatarType
        self.avatarColor = avatarColor
        self.backgroundTheme = backgroundTheme
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
            Avatar3DView(avatarType: avatarType, avatarColor: avatarColor, isExpanded: false)
                .frame(width: size, height: size)
                .clipShape(Circle())
            
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
