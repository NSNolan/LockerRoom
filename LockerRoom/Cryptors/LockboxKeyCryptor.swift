//
//  LockboxKeyCryptor.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/21/24.
//

import Foundation

import YubiKit

protocol LockboxKeyCrypting {
    func encrypt(symmetricKeyData: Data, lockboxKey: LockboxKey) -> Data?
    func decrypt(encryptedSymmetricKeysBySerialNumber: [UInt32:Data], lockboxKeysBySerialNumber:[UInt32:LockboxKey]) async -> Data?
}

struct LockboxKeyCryptor: LockboxKeyCrypting {
    func encrypt(symmetricKeyData: Data, lockboxKey: LockboxKey) -> Data? {
        guard let publicKey = lockboxKey.publicKey else {
            print("[Error] Lockbox key cryptor failed to copy public key from lockbox key \(lockboxKey)")
            return nil
        }
        
        let algorithm = lockboxKey.algorithm.secKeyAlgorithm
        
        var error: Unmanaged<CFError>?
        if let encryptedSymmetricKey = SecKeyCreateEncryptedData(publicKey, algorithm, symmetricKeyData as CFData, &error) {
            print("[Default] Lockbox key cryptor encrypted symmetric key \(encryptedSymmetricKey) using algorithm \(algorithm.rawValue)")
            return encryptedSymmetricKey as Data
        } else if let error {
            print("[Error] Lockbox key cryptor failed to encrypt symmetric key using algorithm \(algorithm.rawValue) with error \(error)")
            return nil
        } else {
            print("[Error] Lockbox key cryptor failed to encrypt symmetric key using algorithm \(algorithm.rawValue)")
            return nil
        }
    }
    
    func decrypt(encryptedSymmetricKeysBySerialNumber: [UInt32:Data], lockboxKeysBySerialNumber:[UInt32:LockboxKey]) async -> Data? {
        do {
            let connection = try await ConnectionHelper.anyWiredConnection()
            defer { Task { await connection.close(error: nil) } }
            do {
                let session = try await PIVSession.session(withConnection: connection)
                do {
                    let serialNumber = try await session.getSerialNumber()
                    guard let encryptedSymmetricKey = encryptedSymmetricKeysBySerialNumber[serialNumber] else {
                        print("[Error] Lockbox key cryptor failed to get encrypted symmetric key for serial number \(serialNumber)")
                        return nil
                    }
                    guard let lockboxKey = lockboxKeysBySerialNumber[serialNumber] else {
                        print("[Error] Lockbox key cryptor failed to get lockbox key for serial number \(serialNumber)")
                        return nil
                    }
                    
                    let slot = lockboxKey.slot
                    let algorithm = lockboxKey.algorithm.secKeyAlgorithm
                    do {
                        let decryptedSymmetricKey: Data
                        if lockboxKey.slot.isExperimental {
                            decryptedSymmetricKey = try await session.decryptWithKeyInRawSlot(
                                connection: connection,
                                rawSlot: slot.rawSlot,
                                algorithm: algorithm,
                                encrypted: encryptedSymmetricKey
                            )
                        } else {
                            decryptedSymmetricKey = try await session.decryptWithKeyInSlot(
                                slot: slot.pivSlot,
                                algorithm: algorithm,
                                encrypted: encryptedSymmetricKey
                            )
                        }
                        print("[Default] Lockbox key cryptor decrypted symmetric key \(decryptedSymmetricKey) using slot \(slot) algorithm \(algorithm.rawValue)")
                        return decryptedSymmetricKey
                    } catch {
                        print("[Error] Lockbox key cryptor failed to decrypt using slot \(slot) algorithm (algorithm) with error \(error)")
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
