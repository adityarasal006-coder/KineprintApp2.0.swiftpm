import Foundation

public enum AvatarBackgroundTheme: String, CaseIterable, Identifiable {
    case eventHorizon = "Event Horizon"
    case nebulaVoid = "Nebula Void"
    case quantumFoam = "Quantum Foam"
    case hyperspace = "Hyperspace"
    case deepCosmos = "Deep Cosmos"
    
    public var id: String { self.rawValue }
    
    public static var `default`: AvatarBackgroundTheme {
        return .nebulaVoid
    }
}
