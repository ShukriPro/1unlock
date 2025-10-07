//
//  ContentView.swift
//  1unlock
//
//  Created by Shukri on 07/10/2025.
//

import FamilyControls
import SwiftUI
class AuthorizationManager: ObservableObject {
    @Published var authorizationStatus: FamilyControls.AuthorizationStatus = .notDetermined
    init() {
        // Check initial status if needed when the app starts
        Task {
            await checkAuthorization()
        }
    }
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual) // Use .individual for non-Family Sharing apps
            self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        } catch {
            // Handle errors appropriately (e.g., logging, showing an alert)
            print("Failed to request authorization: \(error)")
            self.authorizationStatus = .denied // Or handle specific errors
        }
    }
    func checkAuthorization() async {
         self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }
}
// Example Usage in a SwiftUI View
struct ContentView: View {
    @StateObject var authManager = AuthorizationManager()
    var body: some View {
        VStack {
            ProfileEditorView()
            HomeView()
        }
        
//        VStack {
//            Text("Authorization Status: \(String(describing: authManager.authorizationStatus))")
//            ProfileEditorView()
//            if authManager.authorizationStatus == .notDetermined {
//                Button("Request Authorization") {
//                    Task {
//                        await authManager.requestAuthorization()
//                    }
//                }
//            } else if authManager.authorizationStatus == .approved {
//                Text("Authorization Granted!")
//                // Proceed with FamilyControls features...
//                ProfileEditorView()
//            } else {
//                Text("Authorization Denied or Restricted. Please enable in Settings.")
//                // Guide user to Settings if needed
//            }
//        }
//        .padding()
    }
}
#Preview {
    ContentView()
}
