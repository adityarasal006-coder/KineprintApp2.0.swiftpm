import SwiftUI

public struct LogItem: Identifiable {
    public let id = UUID()
    public let time: String
    public let msg: String
    public let type: LogType
    
    public enum LogType {
        case normal, success, error
    }
    
    public init(time: String, msg: String, type: LogType) {
        self.time = time
        self.msg = msg
        self.type = type
    }
}
