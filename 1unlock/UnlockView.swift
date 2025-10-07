//
//  UnlockView.swift
//  1unlock
//
//  Created by Shukri on 07/10/2025.
//

import SwiftUI

#if os(iOS)
struct UnlockView: View {
    private let blockerUtil = AppBlockerUtil()
    var body: some View {
        Button("Unlock 1 min") {
            blockerUtil.unlockForOneMinute()
        }
    }
}
#else
struct UnlockView: View {
    var body: some View {
        Text("Unlock is available on iOS only")
    }
}
#endif

#Preview {
    UnlockView()
}
