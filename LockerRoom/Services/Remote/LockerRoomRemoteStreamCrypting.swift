//
//  LockerRoomRemoteStreamCrypting.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/27/24.
//

import Foundation

@objc
protocol LockerRoomRemoteStreamCrypting {
    func encrypt(inputPath: String, outputPath: String, symmetricKeyData: Data, _ replyHandler: @escaping (Bool) -> Void)
    func decrypt(inputPath: String, outputPath: String, symmetricKeyData: Data, _ replyHandler: @escaping (Bool) -> Void)
    func encryptExtractingComponents(inputPath: String, outputPath: String, symmetricKeyData: Data, _ replyHandler: @escaping (LockboxCryptorComponents?) -> Void)
    func decryptWithComponents(inputPath: String, outputPath: String, symmetricKeyData: Data, components: LockboxCryptorComponents, _ replyHandler: @escaping (Bool) -> Void)
}
