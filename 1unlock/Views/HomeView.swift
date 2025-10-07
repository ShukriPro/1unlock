//
//  HomeView.swift
//  1unlock
//
//  Shows selected apps (name + icon) from saved FamilyActivitySelection
//

import SwiftUI

#if os(iOS)
import FamilyControls

struct HomeView: View {
    @State private var selection = FamilyActivitySelection()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Apps")
                .font(.headline)

            if selection.applicationTokens.isEmpty {
                Text("No apps selected")
                    .foregroundColor(.secondary)
            } else {
                List(Array(selection.applicationTokens), id: \.self) { token in
                    Label(token) // system resolves name + icon
                }
                .listStyle(.plain)
            }
        }
        .padding()
        .onAppear {
            if let saved = SharedState.loadSelection() {
                selection = saved
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectionDidChange)) { _ in
            if let saved = SharedState.loadSelection() {
                selection = saved
            }
        }
    }
}
#endif


