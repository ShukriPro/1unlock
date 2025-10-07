//
//  BlockedProfiles.swift
//  1unlock
//
//  Created by Shukri on 07/10/2025.
//

import Foundation
import SwiftData
import FamilyControls

@Model
class BlockedProfiles {
    var selectedActivity: FamilyActivitySelection // Stores the result from the picker
    
    init(selectedActivity: FamilyActivitySelection = FamilyActivitySelection()) {
        self.selectedActivity = selectedActivity
    }
}