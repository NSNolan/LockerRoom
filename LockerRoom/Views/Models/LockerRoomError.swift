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
    case failedToCreateExternalLockbox
    case failedToDecryptLockbox
    case failedToDecryptLockboxSymmetricKey
    case failedToEncryptLockbox
    case failedToFindSelectedLockbox
    case failedToOpenLockbox
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
        case .failedToCreateExternalLockbox:
            return "Failed to create external lockbox."
        case .failedToDecryptLockbox:
            return "Failed to decrypt lockbox."
        case .failedToDecryptLockboxSymmetricKey:
            return "Failed to decrypt lockbox symmetric key."
        case .failedToEncryptLockbox:
            return "Failed to encrypt lockbox."
        case .failedToFindSelectedLockbox:
            return "Failed to find selected lockbox."
        case .failedToOpenLockbox:
            return "Failed to open lockbox."
        case .failedToRemoveLockbox:
            return "Failed to remove lockbox."
        case .missingLockbox:
            return "Lockbox is missing."
        }
    }
}
