//
//  AppBlockerUtil.swift
//  1unlock
//
//  Created by Shukri on 07/10/2025.
//

import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class AppBlockerUtil { // Simplified from the provided code
    let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("1unlock")) // Use a unique name
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
       // ... (applyRestrictions, removeRestrictions from above) ...
       func startMonitoringSchedule() {
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
               try center.startMonitoring(Self.activityName, during: schedule)
               print("Monitoring started successfully.")
           } catch {
               print("Error starting DeviceActivity monitoring: \(error)")
           }
       }
       func stopMonitoring() {
           print("Stopping DeviceActivity monitoring...")
           // Stop monitoring for all activities or specify names
           center.stopMonitoring([Self.activityName])
           print("Monitoring stopped.")
       }
       // Combined Activation Logic (Similar to provided code)
       func activateRestrictions(selection: FamilyActivitySelection) {
           lastSelection = selection
           applyRestrictions(selection: selection) // Step 2: Define rules
           startMonitoringSchedule()             // Step 3: Activate schedule
       }
       // Combined Deactivation Logic
       func deactivateRestrictions() {
           removeRestrictions() // Step 2: Clear rules
           stopMonitoring()     // Step 3: Deactivate schedule
       }
       // Temporarily lift restrictions for one minute, then re-apply the last selection
       func unlockForOneMinute() {
           print("Unlocking for 1 minute...")
           stopMonitoring()
           removeRestrictions()
           DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
               guard let self = self else { return }
               guard let selection = self.lastSelection else {
                   print("No previous selection found. Skipping re-activation.")
                   return
               }
               self.activateRestrictions(selection: selection)
               print("Restrictions re-applied after 1 minute.")
           }
       }
   }

