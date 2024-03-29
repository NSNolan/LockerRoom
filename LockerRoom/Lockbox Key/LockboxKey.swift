//
//  LockboxKey.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import Foundation

struct LockboxKey: Codable {
    enum Slot: String, CaseIterable, Codable {
        case pivAuthentication = "PIV Authentication (9A)"
        case digitalSignature = "Digital Signature (9C)"
        case keyManagement = "Key Management (9D)"
        case cardAuthentication = "Card Authentication (9E)"
        case attestation = "Attestation (F9)"
        case experimental = "Experimental (82)"
    }
    
    enum Algorithm: String, CaseIterable, Codable {
        case RSA1024 = "RSA 1024"
        case RSA2048 = "RSA 2048"
    }
    
    enum PinPolicy: String, CaseIterable, Codable {
        case never = "Never"
        case once = "Once"
        case always = "Always"
    }
    
    enum TouchPolicy: String, CaseIterable, Codable {
        case never = "Never"
        case always = "Always"
        case cached = "Cached"
    }
    
    let name: String
    let serialNumber: UInt32
    let slot: Slot
    let algorithm: Algorithm
    let pinPolicy: PinPolicy
    let touchPolicy: TouchPolicy
    let managementKeyString: String
    let publicKeyData: Data
    
    private init(name: String, serialNumber: UInt32, slot: Slot, algorithm: Algorithm, pinPolicy: PinPolicy, touchPolicy: TouchPolicy, managementKeyString: String, publicKey: SecKey) {
        self.name = name
        self.serialNumber = serialNumber
        self.slot = slot
        self.algorithm = algorithm
        self.pinPolicy = pinPolicy
        self.touchPolicy = touchPolicy
        self.managementKeyString = managementKeyString
        self.publicKeyData = publicKey.data ?? Data()
    }

    var publicKey: SecKey? {
        publicKeyData.publicKey
    }
    
    static func create(name: String, serialNumber: UInt32, slot: Slot, algorithm: Algorithm, pinPolicy: PinPolicy, touchPolicy: TouchPolicy, managementKeyString: String, publicKey: SecKey, lockerRoomStore: LockerRoomStoring) -> LockboxKey? {
        let key = LockboxKey(
            name: name,
            serialNumber: serialNumber,
            slot: slot,
            algorithm: algorithm,
            pinPolicy: pinPolicy,
            touchPolicy: touchPolicy,
            managementKeyString: managementKeyString,
            publicKey: publicKey
        )
        
        guard !lockerRoomStore.lockboxKeyExists(name: name) else {
            print("[Error] Lockbox key failed to create \(name) at existing path")
            return nil
        }
        
        guard lockerRoomStore.writeLockboxKey(key, name: name, fileType: .publicKeysFileType) else {
            print("[Error] Lockbox key failed to write key \(key) for \(name)")
            _ = destroy(name: name, lockerRoomStore: lockerRoomStore)
            return nil
        }
        
        return key
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Lockbox key failed to destory key without a name")
            return false
        }
        
        guard lockerRoomStore.lockboxKeyExists(name: name) else {
            print("[Error] Lockbox key failed to destroy non-existing \(name)")
            return false
        }
        
        guard lockerRoomStore.removeLockbox(name: name) else {
            print("[Error] Lockbox key failed to remove \(name)")
            return false
        }
        
        return true
    }
}

private extension SecKey {
    var data: Data? {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(self, &error) as Data? else {
            print("[Error] Lockbox key failed to convert public key to data: \(error.debugDescription)")
            return nil
        }
        return data
    }
}

private extension Data {
    var publicKey: SecKey? {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(self as CFData, attributes as CFDictionary, &error) else {
            print("[Error] Lockbox key failed to convert data to public key: \(error.debugDescription)")
            return nil
        }
        return key
    }
}
