//
//  LockboxCryptor.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

protocol LockboxCrypting {
    func encrypt(lockbox: UnencryptedLockbox, symmetricKeyData: Data) -> Bool
    func decrypt(lockbox: EncryptedLockbox, symmetricKeyData: Data) -> Bool
}

struct LockboxCryptor: LockboxCrypting {
    let streamCryptor = LockboxStreamCryptor()
    
    func encrypt(lockbox: UnencryptedLockbox, symmetricKeyData: Data) -> Bool {
        return streamCryptor.encrypt(inputStream: lockbox.inputStream, outputStream: lockbox.outputStream, symmetricKeyData: symmetricKeyData)
    }
    
    func decrypt(lockbox: EncryptedLockbox, symmetricKeyData: Data) -> Bool {
        return streamCryptor.decrypt(inputStream: lockbox.inputStream, outputStream: lockbox.outputStream, symmetricKeyData: symmetricKeyData)
    }
}
