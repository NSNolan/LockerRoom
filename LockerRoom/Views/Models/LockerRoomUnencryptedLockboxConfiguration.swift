//
//  LockerRoomUnencryptedLockboxConfiguration.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 4/29/24.
//

import Foundation

@Observable class LockerRoomUnencryptedLockboxConfiguration {
    static let maxSizeInMegabytes = 100 * 1024 // 100GB
    
    var name = ""
    var sizeString = ""
    var size = LockboxSize(unit: .megabytes, value: 0)
    var unit = LockboxUnit.megabytes
    
    enum LockboxUnit: String, CaseIterable, Identifiable {
        case megabytes = "Megabytes"
        case gigabytes = "Gigabytes"
        
        var id: String { self.rawValue }
    }
    
    struct LockboxSize {
        var unit: LockboxUnit
        var value: Int
        
        var megabytes: Int {
            switch unit {
            case .megabytes:
                return value
            case .gigabytes:
                return value * 1024
            }
        }
    }
    
    var invalid: Bool {
        let sizeInMegabytes = size.megabytes
        return (name.isEmpty || sizeInMegabytes <= 0 || sizeInMegabytes > Self.maxSizeInMegabytes)
    }
}
