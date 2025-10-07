//
//  _unlockApp.swift
//  1unlock
//
//  Created by Shukri on 07/10/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct _unlockApp: App {
    @State private var showUnlock = false
    var body: some Scene {
        WindowGroup {
            ContentView()
                .fullScreenCover(isPresented: $showUnlock) {
                    UnlockView()
                }
                .onReceive(NotificationCenter.default.publisher(for: .openUnlock)) { _ in
                    showUnlock = true
                }
        }
        .modelContainer(for: BlockedProfiles.self)
    }
}
