import SwiftUI

// MARK: - Shared Robotics Branding system

public enum RobotType: String, CaseIterable, Identifiable {
    case scout, warrior, titan, core, drone, spark, android, nexus
    case robot1, robot2, robot3, robot4 // Legacy aliases for AppStorage compatibility
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .scout, .robot1: return "robot"
        case .warrior, .robot2: return "shield.machine.fill"
        case .titan, .robot3: return "cpu.fill"
        case .core, .robot4: return "atom"
        case .drone: return "airplane.arrival"
        case .spark: return "bolt.shield.fill"
        case .android: return "brain.head.profile"
        case .nexus: return "square.stack.3d.up.fill"
        }
    }
    
    public var imageName: String {
        switch self {
        case .scout, .robot1: return "robot_1"
        case .warrior, .robot2: return "robot_2"
        case .titan, .robot3: return "robot_3"
        case .core, .robot4: return "robot_4"
        case .drone: return "robot_1"
        case .spark: return "robot_2"
        case .android: return "robot_3"
        case .nexus: return "robot_4"
        }
    }
    
    public static var allModels: [RobotType] {
        return [.scout, .warrior, .titan, .core, .drone, .spark, .android, .nexus]
    }
}

public struct RobotDisplayView: View {
    public let type: RobotType
    public let color: Color
    
    public init(type: RobotType, color: Color) {
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
            
            // The Actual Robot Cutout
            // Using a blend trick to remove the white background from the generated images
            Image(type.imageName)
                .resizable()
                .scaledToFit()
                .padding(15)
                .colorInvert() // Background White -> Black
                .blendMode(.screen) // Black becomes transparent, artwork stays visible
                .shadow(color: color.opacity(0.8), radius: 10)
                .overlay(
                    // Inner Glow based on the chosen color
                    Image(type.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(15)
                        .colorInvert()
                        .blendMode(.screen)
                        .colorMultiply(color.opacity(0.8))
                )
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
