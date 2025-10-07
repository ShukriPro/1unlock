//
//  ShieldActionExtension.swift
//  ShieldActionExtension
//
//  Created by Shukri on 07/10/2025.
//

@_exported import Foundation
#if os(iOS)
import ManagedSettings
import ManagedSettingsUI
import UserNotifications

// Override the functions below to customize the shield actions used in various situations.
// The system provides a default response for any functions that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Handle the action as needed.
        switch action {
        case .primaryButtonPressed:
            scheduleReturnToAppNotification()
            completionHandler(.defer)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            fatalError()
        }
    }
    
    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Handle the action as needed.
        if action == .primaryButtonPressed { scheduleReturnToAppNotification(); completionHandler(.close) }
        else { completionHandler(.defer) }
    }
    
    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        // Handle the action as needed.
        if action == .primaryButtonPressed { scheduleReturnToAppNotification(); completionHandler(.close) }
        else { completionHandler(.defer) }
    }

    private func scheduleReturnToAppNotification() {
        let center = UNUserNotificationCenter.current()
        // Requesting permission here is safe; user may have already granted in the app
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Tap to continue in 1unlock"
            content.body = "Open the app to finish unlocking."
            content.userInfo = ["route": "unlock"]
            // Fire immediately
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            let request = UNNotificationRequest(identifier: "return_to_app_now", content: content, trigger: trigger)
            center.add(request, withCompletionHandler: nil)
        }
    }
}
#endif
