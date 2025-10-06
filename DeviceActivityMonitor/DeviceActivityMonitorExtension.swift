//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitor
//
//  Created by Shukri on 07/10/2025.
//

#if os(iOS)
import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

// Shared configuration (match the app target)
enum SharedConfig {
    static let appGroupId = "group.com.shukri.1unlock"
    static let storeName = ManagedSettingsStore.Name("1unlock")
    static let blockerActivity = DeviceActivityName("com.shukri.1unlock.blockerActivity")
    static let unlockWindowActivity = DeviceActivityName("com.shukri.1unlock.unlockWindow")
    static let unlockUsageActivity = DeviceActivityName("com.shukri.1unlock.unlockUsageActivity")
    static let unlockUsageEvent = DeviceActivityEvent.Name("com.shukri.1unlock.unlockUsageLimit")
}

// Shared state persisted via App Group
enum SharedState {
    private static var defaults: UserDefaults { UserDefaults(suiteName: SharedConfig.appGroupId)! }

    static var unlockUntil: Date? {
        get { defaults.object(forKey: "unlockUntil") as? Date }
        set { defaults.set(newValue, forKey: "unlockUntil") }
    }

    static func loadSelection() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: "selectionData") else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}

// Optionally override any of the functions below.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let store = ManagedSettingsStore(named: SharedConfig.storeName)

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        let now = Date()
        if activity == SharedConfig.blockerActivity {
            if let until = SharedState.unlockUntil, now < until {
                clearShields()
            } else {
                applyShieldsFromSelection()
            }
        } else if activity == SharedConfig.unlockWindowActivity {
            clearShields()
        } else if activity == SharedConfig.unlockUsageActivity {
            // entering a period where we are counting usage; remain unlocked
            clearShields()
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        if activity == SharedConfig.unlockWindowActivity {
            SharedState.unlockUntil = nil
            applyShieldsFromSelection()
        }
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        // When the 60s usage threshold is reached, re-apply shields immediately
        if activity == SharedConfig.unlockUsageActivity && event == SharedConfig.unlockUsageEvent {
            applyShieldsFromSelection()
        }
    }

    // Helpers
    private func clearShields() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    private func applyShieldsFromSelection() {
        guard let selection = SharedState.loadSelection() else { return }
        let apps = selection.applicationTokens
        let cats = selection.categoryTokens
        let webs = selection.webDomainTokens
        store.shield.applications = apps.isEmpty ? nil : apps
        store.shield.applicationCategories = cats.isEmpty ? nil : .specific(cats)
        store.shield.webDomains = webs.isEmpty ? nil : webs
    }
}
#endif
