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
                            print("[Error] Lockbox key generator failed to create management key data from hex encoded string: \(managementKeyString)")
                            return nil
                        }
                        try await session.authenticateWith(managementKey: managementKeyData, keyType: managementKeyType)
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
}

private extension LockboxKey.Slot {
    var pivSlot: PIVSlot {
        switch self {
        case .pivAuthentication:
            return .authentication
        case .digitalSignature:
            return .signature
        case .keyManagement:
            return .keyManagement
        case .cardAuthentication:
            return .cardAuth
        case .attestation:
            return .attestation
        case .experimental:
            let experimentalRawValue: UInt8 = 0x82 // TODO: Results in EXC_BAD_ACCESS
            return unsafeBitCast(experimentalRawValue, to: PIVSlot.self)
        }
    }    
}

private extension LockboxKey.Algorithm {
    var pivKeyType: PIVKeyType {
        switch self {
        case .RSA1024:
            return .RSA1024
        case .RSA2048:
            return .RSA2048
        }
    }
}

private extension LockboxKey.PinPolicy {
    var pivPinPolicy: PIVPinPolicy {
        switch self {
        case .never:
            return .never
        case .once:
            return .once
        case .always:
            return .always
        }
    }
}

private extension LockboxKey.TouchPolicy {
    var pivTouchPolicy: PIVTouchPolicy {
        switch self {
        case .never:
            return .never
        case .always:
            return .always
        case .cached:
            return .cached
        }
    }
}
