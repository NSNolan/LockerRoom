//
//  LockboxKeyCryptor.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/21/24.
//

import Foundation

import YubiKit

struct LockboxKeyCryptor {
    static func encrypt(symmetricKey: Data, lockboxKey: LockboxKey) -> Data? {
        guard let publicKey = lockboxKey.publicKey else {
            print("[Error] Lockbox key cryptor failed to copy public key from lockbox key \(lockboxKey)")
            return nil
        }
        
        var error: Unmanaged<CFError>?
        if let encryptedSymmetricKey = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionOAEPSHA256, symmetricKey as CFData, &error) { // TODO: Only use RSA algorithm
            print("[Default] Lockbox key cryptor encrypted symmetric key \(encryptedSymmetricKey)")
            return encryptedSymmetricKey as Data
        } else if let error {
            print("[Error] Lockbox key cryptor failed to encrypt symmetric key with error \(error)")
            return nil
        } else {
            print("[Error] Lockbox key cryptor failed to encrypt symmetric key")
            return nil
        }
    }
    
    static func decrypt(encryptedSymmetricKeysBySerialNumber: [UInt32:Data]) async -> Data? {
        do {
            let connection = try await ConnectionHelper.anyWiredConnection()
            defer { Task { await connection.close(error: nil) } }
            do {
                let session = try await PIVSession.session(withConnection: connection)
                do {
                    let serialNumber = try await session.getSerialNumber()
                    guard let encryptedSymmetricKey = encryptedSymmetricKeysBySerialNumber[serialNumber] else {
                        print("[Error] Lockbox key cryptor failed to get encryptedSymmetricKey for serial number \(serialNumber)")
                        return nil
                    }

                    do {
                        let decryptedSymmetricKey = try await session.decryptWithKeyInSlot(slot: .cardAuth, algorithm: .rsaEncryptionOAEPSHA256, encrypted: encryptedSymmetricKey) // TODO: Only using cardAuth slot and RSA algorithm to decrypt
                        print("[Default] Lockbox key cryptor decrypted symmetric key \(decryptedSymmetricKey)")
                        return decryptedSymmetricKey
                    } catch {
                        print("[Error] Lockbox key cryptor failed to decrypt using slot \(PIVSlot.cardAuth) with error \(error)") // TODO: Update this log line from cardAuth being hardcoded
                        return nil
                    }
                } catch {
                    print("[Error] Lockbox key cryptor failed to get serial number with error \(error)")
                    return nil
                }
            } catch {
                print("[Error] Lockbox key cryptor failed to create PIV session from connection \(connection) with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Lockbox key cryptor failed to find a wired connection with error \(error)")
            return nil
        }
    }
}
