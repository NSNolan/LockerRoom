//
//  LockerRoomKeyMetadata.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import Foundation

import YubiKit

struct LockerRoomKeyMetadata: Identifiable {
    enum Slot: String, CaseIterable, Identifiable {
        case pivAuthentication = "PIV Authentication (9A)"
        case digitalSignature = "Digital Signature (9C)"
        case keyManagement = "Key Management (9D)"
        case cardAuthentication = "Card Authentication (9E)"
        case attestation = "Attestation (F9)"
        case experimental = "Experimental (82)"
        
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
    
    enum Algorithm: String, CaseIterable, Identifiable {
        case RSA1024 = "RSA 1024"
        case RSA2048 = "RSA 2048"
        
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
    
    enum PinPolicy: String, CaseIterable, Identifiable {
        case never = "Never"
        case once = "Once"
        case always = "Always"
        
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
    
    enum TouchPolicy: String, CaseIterable, Identifiable {
        case never = "Never"
        case always = "Always"
        case cached = "Cached"
        
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
    
    let id = UUID()
    let name: String
    let serialNumber: UInt32
    let slot: Slot
    let algorithm: Algorithm
    let pinPolicy: PinPolicy
    let touchPolicy: TouchPolicy
    let managementKeyString: String
    let publicKey: SecKey
}
