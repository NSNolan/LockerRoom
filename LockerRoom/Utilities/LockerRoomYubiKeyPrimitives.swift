//
//  LockerRoomYubiKeyPrimitives.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 4/2/24.
//

import Foundation

import YubiKit

extension LockboxKey.Slot {
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
        case .experimental82, .experimental83, .experimental84, .experimental85, .experimental86,
             .experimental87, .experimental88, .experimental89, .experimental8a, .experimental8b,
             .experimental8c, .experimental8d, .experimental8e, .experimental8f, .experimental90,
             .experimental91, .experimental92, .experimental93, .experimental94, .experimental95:
            fatalError("PIV Slot does not supported for experimental slot values")
        }
    }
    
    var rawSlot: UInt8 {
        switch self {
        case .pivAuthentication:
            return PIVSlot.authentication.rawValue
        case .digitalSignature:
            return PIVSlot.signature.rawValue
        case .keyManagement:
            return PIVSlot.keyManagement.rawValue
        case .cardAuthentication:
            return PIVSlot.cardAuth.rawValue
        case .attestation:
            return PIVSlot.attestation.rawValue
        case .experimental82:
            return 0x82
        case .experimental83:
            return 0x83
        case .experimental84:
            return 0x84
        case .experimental85:
            return 0x85
        case .experimental86:
            return 0x86
        case .experimental87:
            return 0x87
        case .experimental88:
            return 0x88
        case .experimental89:
            return 0x89
        case .experimental8a:
            return 0x8a
        case .experimental8b:
            return 0x8b
        case .experimental8c:
            return 0x8c
        case .experimental8d:
            return 0x8d
        case .experimental8e:
            return 0x8e
        case .experimental8f:
            return 0x8f
        case .experimental90:
            return 0x90
        case .experimental91:
            return 0x91
        case .experimental92:
            return 0x92
        case .experimental93:
            return 0x93
        case .experimental94:
            return 0x94
        case .experimental95:
            return 0x95
        }
    }
}

extension LockboxKey.Algorithm {
    var pivKeyType: PIVKeyType {
        switch self {
        case .RSA1024:
            return .RSA1024
        case .RSA2048:
            return .RSA2048
        }
    }
}

extension LockboxKey.PinPolicy {
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

extension LockboxKey.TouchPolicy {
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
