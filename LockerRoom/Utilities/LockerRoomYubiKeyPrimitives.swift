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
        case .experimental:
            let experimentalRawValue: UInt8 = 0x82 // TODO: Results in EXC_BAD_ACCESS
            return unsafeBitCast(experimentalRawValue, to: PIVSlot.self)
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
