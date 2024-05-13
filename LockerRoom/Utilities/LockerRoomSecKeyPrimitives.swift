//
//  LockerRoomSecKeyPrimitives.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 4/2/24.
//

import Foundation

import os.log

extension SecKey {
    var data: Data? {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(self, &error) as Data? else {
            Logger.utilities.error("Failed to convert public key to data: \(error.debugDescription)")
            return nil
        }
        return data
    }
}

extension Data {
    var publicKey: SecKey? {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(self as CFData, attributes as CFDictionary, &error) else {
            Logger.utilities.error("Failed to convert data to public key: \(error.debugDescription)")
            return nil
        }
        return key
    }
}

extension LockboxKey.Algorithm {
    var secKeyAlgorithm: SecKeyAlgorithm {
        switch self {
        case .RSA1024, .RSA2048:
            return .rsaEncryptionOAEPSHA256
        }
    }
}
