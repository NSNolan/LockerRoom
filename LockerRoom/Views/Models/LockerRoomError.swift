//
//  LockerRoomError.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 4/25/24.
//

import Foundation

enum LockerRoomError: Error {
    case failedToAttachLockbox
    case failedToCreateLockbox
    case failedToCreateLockboxKey
    case failedToDecryptLockbox
    case failedToDecryptLockboxSymmetricKey
    case failedToEncryptLockbox
    case failedToFindSelectedLockbox
    case failedToRemoveLockbox
    case missingLockbox
    
    var nonLocalizedDescription: String {
        switch self {
        case .failedToAttachLockbox:
            return "Failed to attach lockbox."
        case .failedToCreateLockbox:
            return "Failed to create lockbox."
        case .failedToCreateLockboxKey:
            return "Failed to create lockbox key."
        case .failedToDecryptLockbox:
            return "Failed to decrypt lockbox."
        case .failedToDecryptLockboxSymmetricKey:
            return "Failed to decrypt lockbox symmetric key."
        case .failedToEncryptLockbox:
            return "Failed to encrypt lockbox."
        case .failedToFindSelectedLockbox:
            return "Failed to find selected lockbox."
        case .failedToRemoveLockbox:
            return "Failed to remove lockbox."
        case .missingLockbox:
            return "Lockbox is missing."
        }
    }
}
