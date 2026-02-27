import Foundation

public enum ChartMetric: String, CaseIterable {
    case velocity
    case acceleration
    case position
}

public enum AssistantStyle: String, CaseIterable {
    case quiet
    case guided
}

public enum MeasurementUnits: String, CaseIterable {
    case metric
    case imperial
}

public enum BuddyStatus {
    case idle
    case tracking
    case warning
    case providingInsight
    case celebrating
}

public enum TemperatureUnit: String, CaseIterable, Hashable {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"
}

public enum RenderingQuality: String, CaseIterable, Hashable {
    case high = "High"
    case balanced = "Balanced"
    case efficient = "Efficient"
}

public enum LiDARDensity: String, CaseIterable, Hashable {
    case detailed = "Detailed"
    case standard = "Standard"
    case light = "Light"
}
