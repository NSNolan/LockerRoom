//
//  LockerRoomKeyMetadata.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import Foundation

import YubiKit

struct LockerRoomKeyMetadata: Identifiable {
    let id = UUID()
    let name: String
    let serialNumber: UInt32
    let slot: LockboxKey.Slot
    let algorithm: LockboxKey.Algorithm
    let pinPolicy: LockboxKey.PinPolicy
    let touchPolicy: LockboxKey.TouchPolicy
    let managementKeyString: String
}

extension LockboxKey.Slot: Identifiable {
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
    
    var id: String { self.rawValue }
}

extension LockboxKey.Algorithm: Identifiable {
    var pivKeyType: PIVKeyType {
        switch self {
        case .RSA1024:
            return .RSA1024
        case .RSA2048:
            return .RSA2048
        }
    }
    
    var id: String { self.rawValue }
}

extension LockboxKey.PinPolicy: Identifiable {
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
    
    var id: String { self.rawValue }
}

extension LockboxKey.TouchPolicy: Identifiable {
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
    
    var id: String { self.rawValue }
}
