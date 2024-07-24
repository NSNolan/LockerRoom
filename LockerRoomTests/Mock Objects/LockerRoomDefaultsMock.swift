//
//  LockerRoomDefaultsMock.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/17/24.
//

import Foundation

struct LockerRoomDefaultsMock: LockerRoomDefaulting {
    var cryptorChunkSizeInBytes: Int = 256 * 1024 // 256 KB
    var diskVerificationEnabled = true
    var experimentalPIVSlotsEnabled = false
    var externalDisksEnabled = false
    var remoteServiceEnabled = false
}
