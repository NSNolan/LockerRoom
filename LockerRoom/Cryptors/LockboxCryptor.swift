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
    func encryptExtractingComponents(lockbox: UnencryptedLockbox, symmetricKeyData: Data) -> LockboxCryptorComponents?
    func decryptWithComponents(lockbox: EncryptedLockbox, symmetricKeyData: Data, components: LockboxCryptorComponents) -> Bool
}

struct LockboxCryptor: LockboxCrypting {
    private let streamCryptor = LockboxStreamCryptor()
    private let lockerRoomDefaults: LockerRoomDefaulting
    
    init(lockerRoomDefaults: LockerRoomDefaulting) {
        self.lockerRoomDefaults = lockerRoomDefaults
    }
    
    func encrypt(lockbox: UnencryptedLockbox, symmetricKeyData: Data) -> Bool {
        return streamCryptor.encrypt(
            inputStream: lockbox.inputStream,
            outputStream: lockbox.outputStream,
            chunkSizeInBytes: lockerRoomDefaults.cryptorChunkSizeInBytes,
            symmetricKeyData: symmetricKeyData
        )
    }
    
    func decrypt(lockbox: EncryptedLockbox, symmetricKeyData: Data) -> Bool {
        return streamCryptor.decrypt(
            inputStream: lockbox.inputStream,
            outputStream: lockbox.outputStream,
            symmetricKeyData: symmetricKeyData
        )
    }
    
    func encryptExtractingComponents(lockbox: UnencryptedLockbox, symmetricKeyData: Data) -> LockboxCryptorComponents? {
        return streamCryptor.encryptExtractingComponents(
            inputStream: lockbox.inputStream, 
            outputStream: lockbox.outputStream,
            chunkSizeInBytes: lockerRoomDefaults.cryptorChunkSizeInBytes,
            symmetricKeyData: symmetricKeyData
        )
    }
    
    func decryptWithComponents(lockbox: EncryptedLockbox, symmetricKeyData: Data, components: LockboxCryptorComponents) -> Bool {
        return streamCryptor.decryptWithComponents(
            inputStream: lockbox.inputStream,
            outputStream: lockbox.outputStream,
            symmetricKeyData: symmetricKeyData,
            components: components
        )
    }
}
