//
//  NotificationsDelegate.swift
//  1unlock
//

import Foundation
import UserNotifications

final class NotificationsDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationsDelegate()

    // Called when user taps a notification while app is foreground/background
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationCenter.default.post(name: .openUnlock, object: nil)
        completionHandler()
    }

    // Show alerts while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}


