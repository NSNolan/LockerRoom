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
        
        case experimental82 = "Experimental (82)"
        case experimental83 = "Experimental (83)"
        case experimental84 = "Experimental (84)"
        case experimental85 = "Experimental (85)"
        case experimental86 = "Experimental (86)"
        case experimental87 = "Experimental (87)"
        case experimental88 = "Experimental (88)"
        case experimental89 = "Experimental (89)"
        case experimental8a = "Experimental (8a)"
        case experimental8b = "Experimental (8b)"
        case experimental8c = "Experimental (8c)"
        case experimental8d = "Experimental (8d)"
        case experimental8e = "Experimental (8e)"
        case experimental8f = "Experimental (8f)"
        case experimental90 = "Experimental (90)"
        case experimental91 = "Experimental (91)"
        case experimental92 = "Experimental (92)"
        case experimental93 = "Experimental (93)"
        case experimental94 = "Experimental (94)"
        case experimental95 = "Experimental (95)"
        
        public var isExperimental: Bool {
            return self == .experimental82 || self == .experimental83 || self == .experimental84 || self == .experimental85 ||
                   self == .experimental86 || self == .experimental87 || self == .experimental88 || self == .experimental89 ||
                   self == .experimental8a || self == .experimental8b || self == .experimental8c || self == .experimental8d ||
                   self == .experimental8e || self == .experimental8f || self == .experimental90 || self == .experimental91 ||
                   self == .experimental92 || self == .experimental93 || self == .experimental94 || self == .experimental95
        }
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
    let managementKeyString: String // TODO: Maybe I shouldn't persist the management key 
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
        guard !lockerRoomStore.lockboxKeyExists(name: name) else {
            print("[Error] Lockbox key failed to create \(name) at existing path")
            return nil
        }
        
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
        let keyName = String(serialNumber) // Index keys by their serial number
    
        guard lockerRoomStore.writeLockboxKey(key, name: keyName) else {
            print("[Error] Lockbox key failed to write \(key)")
            return nil
        }
        
        return key
    }
    
    static func destroy(name: String, lockerRoomStore: LockerRoomStoring) -> Bool {        
        guard lockerRoomStore.removeLockboxKey(name: name) else {
            print("[Error] Lockbox key failed to remove \(name)")
            return false
        }
        
        return true
    }
}
