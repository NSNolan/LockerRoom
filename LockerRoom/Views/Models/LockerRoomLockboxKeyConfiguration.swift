//
//  LockerRoomLockboxKeyConfiguration.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 4/29/24.
//

import Foundation

@Observable class LockerRoomLockboxKeyConfiguration {
    var name = ""
    var slot = LockboxKey.Slot.pivAuthentication
    var algorithm = LockboxKey.Algorithm.RSA2048
    var pinPolicy = LockboxKey.PinPolicy.never
    var touchPolicy = LockboxKey.TouchPolicy.never
    var managementKeyString = "010203040506070801020304050607080102030405060708" // Default management key
}
