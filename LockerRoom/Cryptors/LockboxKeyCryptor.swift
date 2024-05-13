//
//  LockboxKeyCryptor.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/21/24.
//

import Foundation

import os.log
import YubiKit

protocol LockboxKeyCrypting {
    func encrypt(symmetricKeyData: Data, lockboxKey: LockboxKey) -> Data?
    func decrypt(encryptedSymmetricKeysBySerialNumber: [UInt32:Data], lockboxKeysBySerialNumber:[UInt32:LockboxKey]) async -> Data?
}

struct LockboxKeyCryptor: LockboxKeyCrypting {
    func encrypt(symmetricKeyData: Data, lockboxKey: LockboxKey) -> Data? {
        guard let publicKey = lockboxKey.publicKey else {
            Logger.cryptor.error("Lockbox key cryptor failed to copy public key from lockbox key \(lockboxKey)")
            return nil
        }
        
        let algorithm = lockboxKey.algorithm.secKeyAlgorithm
        
        var error: Unmanaged<CFError>?
        if let encryptedSymmetricKey = SecKeyCreateEncryptedData(publicKey, algorithm, symmetricKeyData as CFData, &error) {
            Logger.cryptor.log("Lockbox key cryptor encrypted symmetric key \(encryptedSymmetricKey) using algorithm \(algorithm.rawValue)")
            return encryptedSymmetricKey as Data
        } else if let error {
            Logger.cryptor.error("Lockbox key cryptor failed to encrypt symmetric key using algorithm \(algorithm.rawValue) with error \(String(describing: error))")
            return nil
        } else {
            Logger.cryptor.error("Lockbox key cryptor failed to encrypt symmetric key using algorithm \(algorithm.rawValue)")
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
                        Logger.cryptor.error("Lockbox key cryptor failed to get encrypted symmetric key for serial number \(serialNumber)")
                        return nil
                    }
                    guard let lockboxKey = lockboxKeysBySerialNumber[serialNumber] else {
                        Logger.cryptor.error("Lockbox key cryptor failed to get lockbox key for serial number \(serialNumber)")
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
                        Logger.cryptor.log("Lockbox key cryptor decrypted symmetric key \(decryptedSymmetricKey) using slot \(slot.rawValue) algorithm \(algorithm.rawValue)")
                        return decryptedSymmetricKey
                    } catch {
                        Logger.cryptor.error("Lockbox key cryptor failed to decrypt using slot \(slot.rawValue) algorithm \(algorithm.rawValue) with error \(error))")
                        return nil
                    }
                } catch {
                    Logger.cryptor.error("Lockbox key cryptor failed to get serial number with error \(error)")
                    return nil
                }
            } catch {
                Logger.cryptor.error("Lockbox key cryptor failed to create PIV session from connection with error \(error)")
                return nil
            }
        } catch {
            Logger.cryptor.error("Lockbox key cryptor failed to find a wired connection with error \(error)")
            return nil
        }
    }
}
