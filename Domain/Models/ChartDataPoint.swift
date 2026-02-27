import Foundation

public struct ChartDataPoint: Identifiable {
    public let id = UUID()
    public let index: Int
    public let value: Double
    
    public init(index: Int, value: Double) {
        self.index = index
        self.value = value
    }
}
