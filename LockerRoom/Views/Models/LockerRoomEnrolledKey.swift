//
//  LockerRoomEnrolledKey.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import Foundation

struct LockerRoomEnrolledKey: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let serialNumber: UInt32
    let slot: LockboxKey.Slot
    let algorithm: LockboxKey.Algorithm
    let pinPolicy: LockboxKey.PinPolicy
    let touchPolicy: LockboxKey.TouchPolicy
    
    fileprivate init(name: String, serialNumber: UInt32, slot: LockboxKey.Slot, algorithm: LockboxKey.Algorithm, pinPolicy: LockboxKey.PinPolicy, touchPolicy: LockboxKey.TouchPolicy) {
        self.name = name
        self.serialNumber = serialNumber
        self.slot = slot
        self.algorithm = algorithm
        self.pinPolicy = pinPolicy
        self.touchPolicy = touchPolicy
    }
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

extension LockboxKey {
    var lockerRoomEnrolledKey: LockerRoomEnrolledKey {
        return LockerRoomEnrolledKey(
            name: name,
            serialNumber: serialNumber,
            slot: slot,
            algorithm: algorithm,
            pinPolicy: pinPolicy,
            touchPolicy: touchPolicy
        )
    }
}
