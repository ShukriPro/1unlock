//
//  _unlockApp.swift
//  1unlock
//
//  Created by Shukri on 07/10/2025.
//

import SwiftUI
import SwiftData

@main
struct _unlockApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: BlockedProfiles.self)
    }
}
