import Foundation

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
