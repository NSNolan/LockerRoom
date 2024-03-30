//
//  LockerRoomLockboxKeyMetadata.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import Foundation

struct LockerRoomLockboxKeyMetadata: Identifiable {
    let id = UUID()
    let name: String
    let serialNumber: UInt32
    let slot: LockboxKey.Slot
    let algorithm: LockboxKey.Algorithm
    let pinPolicy: LockboxKey.PinPolicy
    let touchPolicy: LockboxKey.TouchPolicy
    let managementKeyString: String
}

extension LockboxKey.Slot: Identifiable {
    var id: String { self.rawValue }
}

extension LockboxKey.Algorithm: Identifiable {
    var id: String { self.rawValue }
}

extension LockboxKey.PinPolicy: Identifiable {
    var id: String { self.rawValue }
}

extension LockboxKey.TouchPolicy: Identifiable {
    var id: String { self.rawValue }
}
