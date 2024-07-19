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
        
        if isEncrypted {
            guard let inputStream = InputStream(fileAtPath: encryptedContentPath) else {
                Logger.persistence.error("Encrypted lockbox failed to create input stream for \(name) at path \(encryptedContentPath)")
                return nil
            }
            
            guard let outputStream = OutputStream(toFileAtPath: unencryptedContentPath, append: false) else {
                Logger.persistence.error("Encrypted lockbox failed to create output stream  for \(name) to path \(unencryptedContentPath)")
                return nil
            }
            
            return (inputStream, outputStream)
        } else {
            guard let inputStream = InputStream(fileAtPath: unencryptedContentPath) else {
                Logger.persistence.error("Unencrypted lockbox failed to create input stream for \(name) at path \(unencryptedContentPath)")
                return nil
            }
            
            guard let outputStream = OutputStream(toFileAtPath: encryptedContentPath, append: false) else {
                Logger.persistence.error("Unencrypted lockbox failed to create output stream  for \(name) to path \(encryptedContentPath)")
                return nil
            }
            
            return (inputStream, outputStream)
        }
    }
}
