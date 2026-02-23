#if os(iOS)
import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {}
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    print("Error requesting notification auth: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func scheduleScanCompleteNotification(itemName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Kineprint Analysis Complete"
        content.body = "Deep scan of \(itemName) has been processed and saved to your Research Archive."
        content.sound = .default
        
        // Trigger 2 seconds after scheduling (acting as an offline ping)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.0, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Kineprint Lab is Ready"
        content.body = "Return to analyze more components and build out your structural database."
        content.sound = .default
        
        // Trigger at 10 AM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
#endif
