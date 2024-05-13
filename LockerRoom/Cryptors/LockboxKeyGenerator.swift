//
//  LockboxKeyGenerator.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/27/24.
//

import Foundation

import CryptoKit
import os.log
import YubiKit

protocol LockboxKeyGenerating {
    func generateSymmetricKeyData() -> Data
    func generatePublicKeyDataFromDevice(
        slot: LockboxKey.Slot,
        algorithm: LockboxKey.Algorithm,
        pinPolicy: LockboxKey.PinPolicy,
        touchPolicy: LockboxKey.TouchPolicy,
        managementKeyString: String
    ) async -> (publicKey: SecKey, serialNumber: UInt32)?
}

struct LockboxKeyGenerator: LockboxKeyGenerating {
    func generateSymmetricKeyData() -> Data {
        let symmetricKey = SymmetricKey(size: .bits256)
        return symmetricKey.withUnsafeBytes { Data($0) }
    }
    
    func generatePublicKeyDataFromDevice(
        slot: LockboxKey.Slot,
        algorithm: LockboxKey.Algorithm,
        pinPolicy: LockboxKey.PinPolicy,
        touchPolicy: LockboxKey.TouchPolicy,
        managementKeyString: String
    ) async -> (publicKey: SecKey, serialNumber: UInt32)? {
        do {
            let connection = try await ConnectionHelper.anyWiredConnection()
            defer { Task { await connection.close(error: nil) } }
            
            do {
                let session = try await PIVSession.session(withConnection: connection)
                do {
                    let managementKeyMetadata = try await session.getManagementKeyMetadata()
                    do {
                        let managementKeyType = managementKeyMetadata.keyType
                        guard let managementKeyData = Data(hexEncodedString: managementKeyString) else {
                            Logger.cryptor.error("Lockbox key generator failed to create management key data from hex encoded string: \(managementKeyString)")
                            return nil
                        }
                        try await session.authenticateWith(managementKey: managementKeyData, keyType: managementKeyType)
                        do {
                            let publicKey: SecKey
                            if slot.isExperimental {
                                publicKey = try await session.generateKeyInRawSlot(
                                    connection: connection,
                                    rawSlot: slot.rawSlot,
                                    type: algorithm.pivKeyType,
                                    pinPolicy: pinPolicy.pivPinPolicy,
                                    touchPolicy: touchPolicy.pivTouchPolicy
                                )
                            } else {
                                publicKey = try await session.generateKeyInSlot(
                                    slot: slot.pivSlot,
                                    type: algorithm.pivKeyType,
                                    pinPolicy: pinPolicy.pivPinPolicy,
                                    touchPolicy: touchPolicy.pivTouchPolicy
                                )
                            }
                            Logger.cryptor.log("Lockbox key generator generated public key \(publicKey.hashValue) for slot \(slot.rawValue) with algorithm \(algorithm.rawValue) pin policy \(pinPolicy.rawValue) touch policy \(touchPolicy.rawValue)")
                            
                            do {
                                let serialNumber = try await session.getSerialNumber()
                                Logger.cryptor.log("Lockbox key generator received serial number \(serialNumber) for public key for slot \(slot.rawValue) with algorithm \(algorithm.rawValue) pin policy \(pinPolicy.rawValue) touch policy \(touchPolicy.rawValue)")
                                return (publicKey, serialNumber)
                            } catch {
                                Logger.cryptor.error("Lockbox key generator failed to get serial number with error \(error) for slot \(slot.rawValue) with algorithm \(algorithm.rawValue) pin policy \(pinPolicy.rawValue) touch policy \(touchPolicy.rawValue)")
                                return nil
                            }
                        } catch {
                            Logger.cryptor.error("Lockbox key generator failed to generate public key for slot \(slot.rawValue) with algorithm \(algorithm.rawValue) pin policy \(pinPolicy.rawValue) touch policy \(touchPolicy.rawValue)")
                            return nil
                        }
                    } catch {
                        Logger.cryptor.error("Lockbox key generator failed to authenticate management key for slot \(slot.rawValue) with algorithm \(algorithm.rawValue) pin policy \(pinPolicy.rawValue) touch policy \(touchPolicy.rawValue)")
                        return nil
                    }
                } catch {
                    Logger.cryptor.error("Lockbox key generator failed to get management key metadata for slot \(slot.rawValue) with algorithm \(algorithm.rawValue) pin policy \(pinPolicy.rawValue) touch policy \(touchPolicy.rawValue)")
                    return nil
                }
            } catch {
                Logger.cryptor.error("Lockbox key generator failed to create PIV session from connection with error \(error)")
                return nil
            }
        } catch {
            Logger.cryptor.error("Lockbox key generator failed to find a wired connection with error \(error)")
            return nil
        }
    }
}
