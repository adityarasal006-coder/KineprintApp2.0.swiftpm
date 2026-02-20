import SwiftUI

@available(macOS 12.0, *)
@available(iOS 16.0, *)
@main
struct KineprintApp: App {
    var body: some Scene {
        WindowGroup {
            KineprintView()
        }
    }
}
