//
//  LockboxStreaming.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 7/18/24.
//

import Foundation

import os.log

protocol LockboxStreaming {
    static func streams(name: String, isEncrypted: Bool, isExternal: Bool, lockerRoomStore: LockerRoomStoring) -> (input: InputStream, output: OutputStream)?
}

extension LockboxStreaming {
    static func streams(name: String, isEncrypted: Bool, isExternal: Bool, lockerRoomStore: LockerRoomStoring) -> (input: InputStream, output: OutputStream)? {
        if isExternal { // External lockbox streams must be configured by the Launch Daemon.
            return (InputStream(), OutputStream())
        }
        
        let unencryptedContentURL = lockerRoomStore.lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let unencryptedContentPath = unencryptedContentURL.path(percentEncoded: false)
        
        let encryptedContentURL = lockerRoomStore.lockerRoomURLProvider.urlForLockboxEncryptedContent(name: name)
        let encryptedContentPath = encryptedContentURL.path(percentEncoded: false)
        
        let inputPath: String
        let outputPath: String
        if isEncrypted {
            inputPath = encryptedContentPath
            outputPath = unencryptedContentPath
        } else {
            inputPath = unencryptedContentPath
            outputPath = encryptedContentPath
        }
        
        guard let inputStream = InputStream(fileAtPath: inputPath) else {
            Logger.persistence.error("Lockbox streaming failed to create input stream for \(name) at path \(inputPath)")
            return nil
        }
        
        guard let outputStream = OutputStream(toFileAtPath: outputPath, append: false) else {
            Logger.persistence.error("Lockbox streaming failed to create output stream  for \(name) to path \(outputPath)")
            return nil
        }
        
        return (inputStream, outputStream)
    }
}
