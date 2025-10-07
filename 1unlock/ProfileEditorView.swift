//
//  ProfileEditorView.swift
//  1unlock
//
//  Created by Shukri on 07/10/2025.
//

import SwiftUI
import FamilyControls
import SwiftData

#if !canImport(FamilyControls)
struct FamilyActivitySelection {
    var applicationTokens: Set<String> = []
    var categoryTokens: Set<String> = []
    var webDomainTokens: Set<String> = []
}
extension View {
    func familyActivityPicker(isPresented: Binding<Bool>, selection: Binding<FamilyActivitySelection>) -> some View { self }
}
#endif

#if !canImport(DeviceActivity)
class AppBlockerUtil {
    func activateRestrictions(selection: FamilyActivitySelection) {}
    func deactivateRestrictions() {}
    func unlockForOneMinute() {}
}
#endif

struct ProfileEditorView: View {
    // State to store the user's selection
    @State private var activitySelection = FamilyActivitySelection()
    // State to control the presentation of the picker
    @State private var isPickerPresented = false
    // Utility to apply/remove blocking based on the selection
    private let blockerUtil = AppBlockerUtil()
    var body: some View {
        VStack {
            Text("Selected \(activitySelection.applicationTokens.count) apps, \(activitySelection.categoryTokens.count) categories, \(activitySelection.webDomainTokens.count) websites")
            Button("Select Apps & Websites") {
                isPickerPresented = true
            }
            .padding(.bottom, 8)

            HStack(spacing: 16) {
                Button("Activate Blocking") {
                    blockerUtil.activateRestrictions(selection: activitySelection)
                }
                Button("Deactivate Blocking") {
                    blockerUtil.deactivateRestrictions()
                }
                Button("Unlock 1 min") {
                    blockerUtil.unlockForOneMinute()
                }
            }
        }
        // The magic modifier!
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $activitySelection
        )
        .onChange(of: activitySelection) { newSelection in
            // Handle the updated selection - maybe save it?
            print("Selection Updated!")
            // In a real app, you'd likely save 'newSelection'
            // to your data model (like the 'BlockedProfiles' model).
            saveSelection(newSelection)
        }
        .onAppear {
            // Load previously saved selection from App Group so counts persist across launches
            #if os(iOS)
            if let saved = SharedState.loadSelection() {
                activitySelection = saved
            }
            #endif
        }
    }
    func saveSelection(_ selection: FamilyActivitySelection) {
        // Placeholder: Implement saving logic here
        // e.g., update your SwiftData model:
        // try? BlockedProfiles.updateProfile(profile, in: context, selection: selection)
        print("Saving selection...")
        #if os(iOS)
        SharedState.saveSelection(selection)
        #endif
    }
}
