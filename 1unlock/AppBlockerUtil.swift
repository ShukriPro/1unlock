//
//  AppBlockerUtil.swift
//  1unlock
//
//  Created by Shukri on 07/10/2025.
//

#if os(iOS)
import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

// Shared configuration for app and extension
enum SharedConfig {
    static let appGroupId = "group.com.shukri.1unlock"
    static let storeName = ManagedSettingsStore.Name("1unlock")
    static let blockerActivity = DeviceActivityName("com.shukri.1unlock.blockerActivity")
    static let unlockWindowActivity = DeviceActivityName("com.shukri.1unlock.unlockWindow")
    static let unlockUsageActivity = DeviceActivityName("com.shukri.1unlock.unlockUsageActivity")
    static let unlockUsageEvent = DeviceActivityEvent.Name("com.shukri.1unlock.unlockUsageLimit")
}

// Shared state persisted to the App Group so the extension can read it
enum SharedState {
    private static var defaults: UserDefaults { UserDefaults(suiteName: SharedConfig.appGroupId)! }

    static var unlockUntil: Date? {
        get { defaults.object(forKey: "unlockUntil") as? Date }
        set { defaults.set(newValue, forKey: "unlockUntil") }
    }

    static func saveSelection(_ selection: FamilyActivitySelection) {
        // FamilyActivitySelection conforms to Codable on supported SDKs
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: "selectionData")
        }
    }

    static func loadSelection() -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: "selectionData") else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }
}

class AppBlockerUtil { // Simplified from the provided code
    let store = ManagedSettingsStore(named: SharedConfig.storeName) // Use a unique name
    let center = DeviceActivityCenter()
    private var lastSelection: FamilyActivitySelection?
    
    
    func applyRestrictions(selection: FamilyActivitySelection) {
            print("Applying restrictions...")
            // Extract tokens from the selection
            let applicationTokens = selection.applicationTokens
            let categoryTokens = selection.categoryTokens
            let webTokens = selection.webDomainTokens
            // Apply tokens to the shield configuration
            store.shield.applications = applicationTokens.isEmpty ? nil : applicationTokens
            store.shield.applicationCategories = categoryTokens.isEmpty ? nil : .specific(categoryTokens)
            store.shield.webDomains = webTokens.isEmpty ? nil : webTokens
            print("Restrictions applied to ManagedSettingsStore.")
            // NOTE: This only defines the rules. DeviceActivity makes them active.
        }
        func removeRestrictions() {
            print("Removing restrictions...")
            // Clear the shield configuration
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
            print("Restrictions removed from ManagedSettingsStore.")
            // NOTE: Also need to stop DeviceActivity monitoring.
        }
    
       // Define a unique name for your activity
       static let activityName = DeviceActivityName("com.shukri.1unlock.blockerActivity")
       static let unlockWindowActivity = DeviceActivityName("com.shukri.1unlock.unlockWindow")
       // Always-on monitoring for blocker activity (24/7)
       func startAlwaysOnMonitoring() {
           // Define a schedule. This example is 24/7, repeating daily.
           let schedule = DeviceActivitySchedule(
               intervalStart: DateComponents(hour: 0, minute: 0),
               intervalEnd: DateComponents(hour: 23, minute: 59),
               repeats: true,
               warningTime: nil // No warning needed for simple blocking
           )
           print("Starting DeviceActivity monitoring for schedule...")
           do {
               // Start monitoring. This tells the system to check the 'store'
               // associated with this activity during the 'schedule'.
               try center.startMonitoring(SharedConfig.blockerActivity, during: schedule)
               print("Monitoring started successfully.")
           } catch {
               print("Error starting DeviceActivity monitoring: \(error)")
           }
       }
       // One-shot unlock window monitoring for a duration (in seconds)
       func startUnlockWindowSchedule(durationSeconds: TimeInterval) {
           let now = Date()
           let end = now.addingTimeInterval(durationSeconds)
           let startComps = Calendar.current.dateComponents([.hour, .minute, .second], from: now)
           let endComps = Calendar.current.dateComponents([.hour, .minute, .second], from: end)

           let schedule = DeviceActivitySchedule(
               intervalStart: startComps,
               intervalEnd: endComps,
               repeats: false,
               warningTime: nil
           )
           print("Starting unlock window monitoring for \(Int(durationSeconds))s...")
           do {
               try center.startMonitoring(SharedConfig.unlockWindowActivity, during: schedule)
               print("Unlock window monitoring started successfully.")
           } catch {
               print("Error starting unlock window monitoring: \(error)")
           }
       }
       // Unlock via usage event: allow usage for a threshold, then re-lock
       func startUnlockUsageEventMonitoring(selection: FamilyActivitySelection, thresholdSeconds: Int) {
           // 24/7 schedule so the extension can receive event callbacks
           let schedule = DeviceActivitySchedule(
               intervalStart: DateComponents(hour: 0, minute: 0),
               intervalEnd: DateComponents(hour: 23, minute: 59),
               repeats: true,
               warningTime: nil
           )
           // Define an event that triggers after N seconds of usage of the selected tokens
           let event = DeviceActivityEvent(
               applications: selection.applicationTokens,
               categories: selection.categoryTokens,
               webDomains: selection.webDomainTokens,
               threshold: DateComponents(second: thresholdSeconds)
           )
           let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [
               SharedConfig.unlockUsageEvent: event
           ]
           print("Starting unlock usage event monitoring for \(thresholdSeconds)s...")
           do {
               try center.startMonitoring(SharedConfig.unlockUsageActivity, during: schedule, events: events)
               print("Unlock usage event monitoring started successfully.")
           } catch {
               print("Error starting unlock usage event monitoring: \(error)")
           }
       }
       func stopMonitoring() {
           print("Stopping DeviceActivity monitoring...")
           // Stop monitoring for all activities or specify names
           center.stopMonitoring([SharedConfig.blockerActivity, SharedConfig.unlockWindowActivity])
           print("Monitoring stopped.")
       }
       // Combined Activation Logic (Similar to provided code)
       func activateRestrictions(selection: FamilyActivitySelection) {
           lastSelection = selection
           SharedState.saveSelection(selection)
           SharedState.unlockUntil = nil
           applyRestrictions(selection: selection) // define rules
           startAlwaysOnMonitoring()               // ensure always-on schedule active
       }
       // Combined Deactivation Logic
       func deactivateRestrictions() {
           removeRestrictions() // Step 2: Clear rules
           stopMonitoring()     // Step 3: Deactivate schedule
       }
       // Temporarily lift restrictions for one minute of usage (event-based), then re-apply the last selection
       func unlockForOneMinute() {
           print("Unlocking for 1 minute of usage (via DeviceActivity event)...")
           guard let selection = lastSelection ?? SharedState.loadSelection() else {
               print("No previous selection found. Skipping unlock.")
               return
           }
           // Clear immediately so user can open the allowed app
           store.shield.applications = nil
           store.shield.applicationCategories = nil
           store.shield.webDomains = nil
           // Start usage-threshold monitoring; extension will re-apply on event
           startUnlockUsageEventMonitoring(selection: selection, thresholdSeconds: 60)
       }
   }
#endif

