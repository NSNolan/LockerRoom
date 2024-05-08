//
//  LockerRoomYubiKeyExperimental.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 4/17/24.
//

import Foundation

import CryptoTokenKit
import YubiKit

// This code has been taken and modified from the YubiKey SDK to support key generation
// and message decryption using non-standard PIV Slots. The YubiKey SDK does not have `PIVSlot`
// representations for the 20 retired slots (82-95) availabe on YubiKey. This is accomplished by
// sending ADPU commands with the raw slot value.

extension PIVSession {
    fileprivate static let insAuthenticate: UInt8 = 0x87
    fileprivate static let insGenerateAsymetric: UInt8 = 0x47
    fileprivate static let tagAuthResponse: TKTLVTag = 0x82
    fileprivate static let tagDynAuth: TKTLVTag = 0x7c
    fileprivate static let tagChallenge: TKTLVTag = 0x81
    fileprivate static let tagGenAlgorithm: TKTLVTag = 0x80
    fileprivate static let tagPinPolicy: TKTLVTag = 0xaa
    fileprivate static let tagTouchpolicy: TKTLVTag = 0xab
    
    func generateKeyInRawSlot(connection: Connection, rawSlot: UInt8, type: PIVKeyType, pinPolicy: PIVPinPolicy = .`defaultPolicy`, touchPolicy: PIVTouchPolicy = .`defaultPolicy`) async throws -> SecKey {
        try checkKeyFeatures(keyType: type, pinPolicy: pinPolicy, touchPolicy: touchPolicy, generateKey: true)
        
        let records: [TKBERTLVRecord] = [
            TKBERTLVRecord(tag: Self.tagGenAlgorithm, value: type.rawValue.data),
            pinPolicy != .`defaultPolicy` ? TKBERTLVRecord(tag: Self.tagPinPolicy, value: pinPolicy.rawValue.data) : nil,
            touchPolicy != .`defaultPolicy` ? TKBERTLVRecord(tag: Self.tagTouchpolicy, value: touchPolicy.rawValue.data) : nil
        ].compactMap { $0 }
        
        let command = TKBERTLVRecord(tag: 0xac, records: records).data
        let apdu = APDU(cla: 0, ins: Self.insGenerateAsymetric, p1: 0, p2: rawSlot, command: command)
        let result = try await connection.send(apdu: apdu)
        
        guard let records = TKBERTLVRecord.sequenceOfRecords(from: result),
              let record = records.recordWithTag(0x7F49),
              let records = TKBERTLVRecord.sequenceOfRecords(from: record.value) else {
            throw PIVSessionError.invalidResponse
        }
        
        switch type {
        case .ECCP256, .ECCP384:
            guard let eccKeyData = records.recordWithTag(0x86)?.value else {
                throw PIVSessionError.invalidResponse
            }
            
            let attributes = [kSecAttrKeyType: kSecAttrKeyTypeEC,
                             kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary
            var error: Unmanaged<CFError>?
            guard let publicKey = SecKeyCreateWithData(eccKeyData as CFData, attributes, &error) else {
                throw error!.takeRetainedValue() as Error
            }
            
            return publicKey
        case .RSA1024, .RSA2048:
            guard let modulus = records.recordWithTag(0x81)?.value,
                  let exponentData = records.recordWithTag(0x82)?.value else {
                throw PIVSessionError.invalidResponse
            }
            
            let modulusData = UInt8(0x00).data + modulus
            var data = Data()
            data.append(TKBERTLVRecord(tag: 0x02, value: modulusData).data)
            data.append(TKBERTLVRecord(tag: 0x02, value: exponentData).data)
            
            let keyRecord = TKBERTLVRecord(tag: 0x30, value: data)
            let attributes = [
                kSecAttrKeyType: kSecAttrKeyTypeRSA,
                kSecAttrKeyClass: kSecAttrKeyClassPublic
            ] as CFDictionary
            
            var error: Unmanaged<CFError>?
            guard let publicKey = SecKeyCreateWithData(keyRecord.data as CFData, attributes, &error) else {
                throw error!.takeRetainedValue() as Error
            }
            
            return publicKey
        case .unknown:
            throw PIVSessionError.unknownKeyType
        }
    }
    
    public func decryptWithKeyInRawSlot(connection: Connection, rawSlot: UInt8, algorithm: SecKeyAlgorithm, encrypted data: Data) async throws -> Data {
        let keyType: PIVKeyType
        switch data.count {
        case 1024 / 8:
            keyType = .RSA1024
        case 2048 / 8:
            keyType = .RSA2048
        default:
            throw PIVSessionError.invalidCipherTextLength
        }
        
        let result = try await usePrivateKeyInRawSlot(connection: connection, rawSlot: rawSlot, keyType: keyType, message: data)
        return try PIVPadding.unpadRSAData(result, algorithm: algorithm)
    }
    
    private func checkKeyFeatures(keyType: PIVKeyType, pinPolicy: PIVPinPolicy, touchPolicy: PIVTouchPolicy, generateKey: Bool) throws {
        if keyType == .ECCP384 {
            guard self.supports(PIVSessionFeature.p384) else { throw SessionError.notSupported }
        }
        if pinPolicy != .`defaultPolicy` || touchPolicy != .`defaultPolicy` {
            guard self.supports(PIVSessionFeature.usagePolicy) else { throw SessionError.notSupported }
        }
        if generateKey && (keyType == .RSA1024 || keyType == .RSA2048) {
            guard self.supports(PIVSessionFeature.rsaGeneration) else { throw SessionError.notSupported }
        }
    }
    
    private func usePrivateKeyInRawSlot(connection: Connection, rawSlot: UInt8, keyType: PIVKeyType, message: Data) async throws -> Data {
        var recordsData = Data()
        recordsData.append(TKBERTLVRecord(tag: Self.tagAuthResponse, value: Data()).data)
        recordsData.append(TKBERTLVRecord(tag: Self.tagChallenge, value: message).data)
        
        let command = TKBERTLVRecord(tag: Self.tagDynAuth, value: recordsData).data
        let apdu = APDU(cla: 0, ins: Self.insAuthenticate, p1: keyType.rawValue, p2: rawSlot, command: command, type: .extended)
        let resultData = try await connection.send(apdu: apdu)
        
        guard let result = TKBERTLVRecord.init(from: resultData), result.tag == Self.tagDynAuth else {
            throw PIVSessionError.responseDataNotTLVFormatted
        }
        
        guard let data = TKBERTLVRecord(from: result.value), data.tag == Self.tagAuthResponse else {
            throw PIVSessionError.responseDataNotTLVFormatted
        }
        
        return data.value
    }
}

extension UInt8 {
    var data: Data {
        var int = self
        return Data(bytes: &int, count: MemoryLayout<UInt8>.size)
    }
}

extension Sequence where Element == TKTLVRecord {
    func recordWithTag(_ tag: TKTLVTag) -> TKTLVRecord? {
        return self.first(where: { $0.tag == tag })
    }
}

private enum PIVPadding {
    static func unpadRSAData(_ data: Data, algorithm: SecKeyAlgorithm) throws -> Data {
        let size: UInt
        switch data.count {
        case 1024 / 8:
            size = 1024
        case 2048 / 8:
            size = 2048
        default:
            throw PIVPaddingError.wrongInputBufferSize
        }
        
        let attributes = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits: size
        ] as [CFString : Any]
        
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error),
              let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw error!.takeRetainedValue() as Error
        }
        
        guard let encryptedData = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionRaw, data as CFData, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        guard let decryptedData = SecKeyCreateDecryptedData(privateKey, algorithm, encryptedData, &error) else {
            throw error!.takeRetainedValue() as Error
        }
        
        return decryptedData as Data
    }
}

