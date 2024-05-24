//
//  LockerRoomLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import Foundation

struct LockerRoomLockbox: Identifiable, Equatable {
    let id: UUID
    let name: String
    let size: Int
    let isEncrypted: Bool
    let isExternal: Bool
    let encryptionKeyNames: [String]
}

extension UnencryptedLockbox.Metadata {
    var lockerRoomLockbox: LockerRoomLockbox {
        return LockerRoomLockbox(
            id: id,
            name: name,
            size: size,
            isEncrypted: isEncrypted,
            isExternal: isExternal,
            encryptionKeyNames: [String]()
        )
    }
}

extension EncryptedLockbox.Metadata {
    var lockerRoomLockbox: LockerRoomLockbox {
        return LockerRoomLockbox(
            id: id,
            name: name,
            size: size,
            isEncrypted: isEncrypted,
            isExternal: isExternal,
            encryptionKeyNames: encryptionLockboxKeys.map { $0.name }
        )
    }
}
