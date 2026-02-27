import SwiftUI
import Combine
import SceneKit

@MainActor
public class KineprintViewModel: ObservableObject {
    @Published public var showVectors = true
    @Published public var recordingPath = false
    @Published public var freezeFrameMode = false
    @Published public var trackingActive = false
    @Published public var lidarAvailable = false
    @Published public var publishedPapers: [ResearchPaper] = []
    @Published public var isSidebarExpanded = false
    
    // Personalization & State
    @AppStorage("userName") public var userName: String = ""
    @AppStorage("avatarType") public var avatarType: CoreShape = .sphere
    @AppStorage("avatarColorName") public var avatarColorName: String = "cyan"
    @AppStorage("customAvatarColorHex") public var customAvatarColorHex: String = "#00FFFF"
    @AppStorage("profileImageData") public var profileImageData: Data?
    @AppStorage("useCustomColor") public var useCustomColor: Bool = false
    @AppStorage("avatarBgStyle") public var avatarBgStyle: String = AvatarBackgroundTheme.nebulaVoid.rawValue
    
    public var backgroundTheme: AvatarBackgroundTheme {
        get { AvatarBackgroundTheme(rawValue: avatarBgStyle) ?? .nebulaVoid }
        set { avatarBgStyle = newValue.rawValue }
    }
    
    public var customAvatarColor: Color {
        get { Color(hex: customAvatarColorHex) }
        set { customAvatarColorHex = newValue.toHex() }
    }
    
    public var avatarColor: Color {
        useCustomColor ? customAvatarColor : Color.fromName(avatarColorName)
    }
    @AppStorage("isOnboardingComplete") public var isOnboardingComplete: Bool = false
    @Published public var assistantStyle: AssistantStyle = .guided
    @Published public var measurementUnits: MeasurementUnits = .metric
    @Published public var isBooting = true
    
    // Chart data
    @Published public var selectedMetric: ChartMetric = .velocity
    @Published public var chartData: [ChartDataPoint] = []
    
    // Live readouts
    @Published public var currentSpeed: Double = 0
    @Published public var currentAccelMagnitude: Double = 0
    @Published public var totalDistance: Double = 0
    
    // Buddy system
    @Published public var buddyMessage: String = "Ready to assist."
    @Published public var buddyStatus: BuddyStatus = .idle
    
    // Internal data storage
    private var velocityHistory: [Double] = []
    private var accelerationHistory: [Double] = []
    private var positionHistory: [Double] = []
    private var dataIndex: Int = 0
    private var lastPosition: SIMD3<Float>?
    
    // Use shared instances or inject
    private let physicsEngine = PhysicsEngine.shared
    
    public init() {
        lidarAvailable = false
    }
    
    public func completeOnboarding(with name: String) {
        self.userName = name
        self.isOnboardingComplete = true
        self.isBooting = true // Trigger boot animation after onboarding
    }
    
    public func toggleVectors() {
        showVectors.toggle()
    }
    
    public func recordPath() {
        recordingPath.toggle()
    }
    
    public func freezeFrame() {
        freezeFrameMode.toggle()
    }
    
    public func clearData() {
        chartData = []
        velocityHistory = []
        accelerationHistory = []
        positionHistory = []
        dataIndex = 0
        currentSpeed = 0
        currentAccelMagnitude = 0
        totalDistance = 0
        lastPosition = nil
        trackingActive = false
    }
    
    public func startTrackingObject(at position: SIMD3<Float>) {
        trackingActive = true
        lastPosition = position
    }
    
    public func updateTrackedObject(position: SIMD3<Float>, velocity: SIMD3<Float>, acceleration: SIMD3<Float>) {
        guard trackingActive else { return }
        
        let speed = Double(length(velocity))
        let accelMag = Double(length(acceleration))
        let posY = Double(position.y)
        
        // Update live readouts
        currentSpeed = speed
        currentAccelMagnitude = accelMag
        
        // Accumulate distance
        if let last = lastPosition {
            totalDistance += Double(length(position - last))
        }
        lastPosition = position
        
        // Store history
        velocityHistory.append(speed)
        accelerationHistory.append(accelMag)
        positionHistory.append(posY)
        
        // Trim to last 200 samples
        if velocityHistory.count > 200 { velocityHistory.removeFirst() }
        if accelerationHistory.count > 200 { accelerationHistory.removeFirst() }
        if positionHistory.count > 200 { positionHistory.removeFirst() }
        
        dataIndex += 1
        
        // Update chart based on selected metric
        updateChartData()
        
        // Update buddy system
        updateBuddySystem(speed: speed, acceleration: accelMag)
    }
    
    private func updateBuddySystem(speed: Double, acceleration: Double) {
        if speed > 0.5 && acceleration > 0.5 {
            buddyStatus = .tracking
            buddyMessage = "Detecting dynamic motion. Velocity: \(String(format: "%.2f", speed)) m/s"
        } else if speed < 0.1 && acceleration < 0.1 {
            buddyStatus = .idle
            buddyMessage = "Object appears stationary. Stable position detected."
        } else if acceleration > 5.0 {
            buddyStatus = .warning
            buddyMessage = "High acceleration detected! \(String(format: "%.2f", acceleration)) m/s²"
        } else if speed > 2.0 {
            buddyStatus = .providingInsight
            buddyMessage = "Fast movement detected. Consider slowing down for precision."
        } else {
            buddyStatus = .tracking
            buddyMessage = "Tracking in progress. All systems nominal."
        }
        
        if assistantStyle == .guided {
            switch buddyStatus {
            case .tracking:
                buddyMessage += " Continue smooth movements."
            case .warning:
                buddyMessage += " Exercise caution."
            case .providingInsight:
                buddyMessage += " Tip: Smooth motions yield better data."
            default:
                break
            }
        }
    }
    
    public func updateChartData() {
        let source: [Double]
        switch selectedMetric {
        case .velocity: source = velocityHistory
        case .acceleration: source = accelerationHistory
        case .position: source = positionHistory
        }
        
        chartData = source.enumerated().map { ChartDataPoint(index: $0.offset, value: $0.element) }
    }
    
    public func stopTracking() {
        trackingActive = false
    }

    public func publishPaper(title: String, content: String) {
        let paper = ResearchPaper(id: UUID(), date: Date(), title: title, content: content)
        publishedPapers.append(paper)
    }
}
