import Foundation

public struct ResearchPaper: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let title: String
    public let content: String
    
    public init(id: UUID = UUID(), date: Date = Date(), title: String, content: String) {
        self.id = id
        self.date = date
        self.title = title
        self.content = content
    }
}
