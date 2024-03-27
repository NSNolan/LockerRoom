//
//  LockboxCryptor.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

import CryptoKit

struct LockboxCryptor {
    static let fileManager = FileManager.default
    
    static func generateSymmetricKeyData() -> Data {
        let symmetricKey = SymmetricKey(size: .bits256)
        return symmetricKey.withUnsafeBytes { Data($0) }
    }
    
    static func encrypt(lockbox: UnencryptedLockbox, symmetricKeyData: Data) -> Data? {
        let symmetricKey = SymmetricKey(data: symmetricKeyData)
        guard let unencryptedContent = lockbox.unecryptedContent else {
            print("[Error] Lockbox cryptor failed to read unencrypted lockbox content")
            return nil
        }
        
        do {
            guard let encryptedContent = try AES.GCM.seal(unencryptedContent, using: symmetricKey).combined else {
                print("[Error] Lockbox cryptor failed to combine encrypted lockbox cipher text")
                return nil
                
            }
            print("[Default] Lockbox cryptor encrypted content \(encryptedContent)")
            return encryptedContent
        } catch {
            print("[Error] Lockbox cryptor failed to encrypt lockbox content with error \(error)")
            return nil
        }
    }

    static func decrypt(lockbox: EncryptedLockbox, symmetricKeyData: Data) -> Data? {
        let symmetricKey = SymmetricKey(data: symmetricKeyData)
        guard let encryptedContent = lockbox.encryptedContent else {
            print("[Error] Lockbox cryptor failed to read encrypted lockbox content")
            return nil
        }
        
        do {
            let encryptedContentBox = try AES.GCM.SealedBox(combined: encryptedContent)
            do {
                let unencryptedContent = try AES.GCM.open(encryptedContentBox, using: symmetricKey)
                print("[Default] Lockbox cryptor decrypted content \(unencryptedContent)")
                return unencryptedContent
            } catch {
                print("[Error] Lockbox cryptor failed to decrypt lockbox content with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Lockbox cryptor failed to seal encrypted lockbox content with error \(error)")
            return nil
        }
    }
}
