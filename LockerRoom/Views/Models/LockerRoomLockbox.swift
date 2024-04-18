//
//  LockerRoomLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import Foundation

struct LockerRoomLockbox: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let size: Int
    let url: URL
    let isEncrypted: Bool
    let encryptionKeyNames: [String]
}
