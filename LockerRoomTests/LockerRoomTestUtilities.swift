//
//  LockerRoomTestUtilities.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/8/24.
//

import Foundation

struct LockerRoomTestUtilities {
    static func createRandomPublicKey() -> SecKey? {
        var error: Unmanaged<CFError>?
        let keyAttributes = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048
        ] as CFDictionary
        
        guard let privateKey = SecKeyCreateRandomKey(keyAttributes, &error) else {
            print("Failed to create private key")
            return nil
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            print("Failed to copy public key")
            return nil
        }
        
        return publicKey
    }
    
    static func createRandomData(size: Int) -> Data? {
        var randomData = Data(count: size)
        
        let randomSuccess = randomData.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                print("Failed to get buffer base address")
                return false
            }
            
            guard SecRandomCopyBytes(kSecRandomDefault, size, baseAddress) == 0 else {
                print("Failed to copy random bytes into buffer")
                return false
            }
            
            return true
        }
        
        guard randomSuccess else {
            print("Failed to generate random data")
            return nil
        }
        
        return randomData
    }
}
