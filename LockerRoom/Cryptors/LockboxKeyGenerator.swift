//
//  LockboxKeyGenerator.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/27/24.
//

import Foundation

import CryptoKit
import YubiKit

struct LockboxKeyGenerator {
    static func generateSymmetricKeyData() -> Data {
        let symmetricKey = SymmetricKey(size: .bits256)
        return symmetricKey.withUnsafeBytes { Data($0) }
    }
    
    static func generatePublicKeyDataFromDevice(
        slot: LockerRoom.LockerRoomKeyMetadata.Slot,
        algorithm: LockerRoom.LockerRoomKeyMetadata.Algorithm,
        pinPolicy: LockerRoom.LockerRoomKeyMetadata.PinPolicy,
        touchPolicy: LockerRoom.LockerRoomKeyMetadata.TouchPolicy
    ) async -> (publicKey: SecKey, serialNumber: UInt32)? {
        do {
            let connection = try await ConnectionHelper.anyWiredConnection()
            defer { Task { await closeConnection(connection: connection) } }
            do {
                let session = try await PIVSession.session(withConnection: connection)
                let defaultManagementKey = Data(hexEncodedString: "c4b4b9040f8e950063b8cbd21a972827d6f520b76d665ff2dad1e2703c7d63a8")!
                do {
                    let managementKeyMetadata = try await session.getManagementKeyMetadata()
                    do {
                        let managementKeyType = managementKeyMetadata.keyType
                        try await session.authenticateWith(managementKey: defaultManagementKey, keyType: managementKeyType)
                        do {
                            let publicKey = try await session.generateKeyInSlot(
                                slot: slot.pivSlot,
                                type: algorithm.pivKeyType,
                                pinPolicy: pinPolicy.pivPinPolicy,
                                touchPolicy: touchPolicy.pivTouchPolicy
                            )
                            print("[Default] Lockbox key generator generated public key \(publicKey) for slot \(slot) with algorithm \(algorithm) pin policy \(pinPolicy) touch policy \(touchPolicy)")
                            do {
                                let serialNumber = try await session.getSerialNumber()
                                print("[Default] Lockbox key generator received serial number \(serialNumber) for public key for slot \(slot) with algorithm \(algorithm) pin policy \(pinPolicy) touch policy \(touchPolicy)")
                                return (publicKey, serialNumber)
                            } catch {
                                print("[Error] Lockbox key generator failed to get serial number with error \(error) for slot \(slot) with algorithm \(algorithm) pin policy \(pinPolicy) touch policy \(touchPolicy)")
                                return nil
                            }
                        } catch {
                            print("[Error] Lockbox key generator failed to generate public key for slot \(slot) with algorithm \(algorithm) pin policy \(pinPolicy) touch policy \(touchPolicy)")
                            return nil
                        }
                    } catch {
                        print("[Error] Lockbox key generator failed to authenticate management key for slot \(slot) with algorithm \(algorithm) pin policy \(pinPolicy) touch policy \(touchPolicy)")
                        return nil
                    }
                } catch {
                    print("[Error] Lockbox key generator failed to get management key metadata for slot \(slot) with algorithm \(algorithm) pin policy \(pinPolicy) touch policy \(touchPolicy)")
                    return nil
                }
            } catch {
                print("[Error] Lockbox key generator failed to create PIV session from connection \(connection) with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Lockbox key generator failed to find a wired connection with error \(error)")
            return nil
        }
    }
    
    private static func closeConnection(connection: Connection) async -> Bool {
        if let error = await connection.connectionDidClose() {
            print("[Error] Lockbox key generator failed to close connection with error \(error)")
            return false
        } else {
            print("[Default] Lockbox key generator did close connection")
        }
        return true
    }
}
