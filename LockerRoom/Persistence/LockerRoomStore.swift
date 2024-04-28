//
//  LockerRoomStore.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/25/24.
//

import Foundation

protocol LockerRoomStoring {
    var lockerRoomURLProvider: LockerRoomURLProviding { get }
    
    // Lockboxes
    func readUnencryptedLockboxMetadata(name: String) -> UnencryptedLockbox.Metadata?
    func writeUnencryptedLockboxMetadata(_ lockboxMetadata: UnencryptedLockbox.Metadata) -> Bool
    
    func readEncryptedLockboxMetadata(name: String) -> EncryptedLockbox.Metadata?
    func writeEncryptedLockboxMetadata(_ lockboxMetadata: EncryptedLockbox.Metadata) -> Bool
    
    func lockboxExists(name: String) -> Bool
    func removeLockbox(name: String) -> Bool
    func removeUnencryptedContent(name: String) -> Bool
    func removeEncryptedContent(name: String) -> Bool
    
    var unencryptedLockboxMetdatas: [UnencryptedLockbox.Metadata] { get }
    var encryptedLockboxMetadatas: [EncryptedLockbox.Metadata] { get }
    
    // Lockbox Keys
    func readLockboxKey(name: String) -> LockboxKey?
    func writeLockboxKey(_ key: LockboxKey?, name: String) -> Bool
    
    func lockboxKeyExists(name: String) -> Bool
    func removeLockboxKey(name: String) -> Bool
    
    var lockboxKeys: [LockboxKey] { get }
}

struct LockerRoomStore: LockerRoomStoring {
    private let fileManager = FileManager.default
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()
    
    internal var lockerRoomURLProvider: LockerRoomURLProviding
        
    init(lockerRoomURLProvider: LockerRoomURLProviding) {
        self.lockerRoomURLProvider = lockerRoomURLProvider
        encoder.outputFormat = .xml
    }
    
    func readUnencryptedLockboxMetadata(name: String) -> UnencryptedLockbox.Metadata? {
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Locker room store failed to read unencrypted lockbox \(name) at non-existing path \(lockboxPath)")
            return nil
        }
        
        let lockboxMetadataURL = lockerRoomURLProvider.urlForLockboxMetadata(name: name)
        let lockboxMetadataPath = lockboxMetadataURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: lockboxMetadataPath) else {
            print("[Error] Locker room store failed to read unencrypted lockbox metadata \(name) at non-existing path \(lockboxMetadataPath)")
            return nil
        }
        
        do {
            let metadataPlistData = try Data(contentsOf: lockboxMetadataURL, options: .mappedIfSafe)
            
            do {
                return try decoder.decode(UnencryptedLockbox.Metadata.self, from: metadataPlistData)
            } catch {
                print("[Error] Locker room store failed to decode unencrypted lockbox metadata \(name) with plist data \(metadataPlistData) at path \(lockboxMetadataPath) with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Locker room store failed to read unencrypted lockbox metadata \(name) at path \(lockboxMetadataPath) with error \(error)")
            return nil
        }
    }
    
    func writeUnencryptedLockboxMetadata(_ lockboxMetadata: UnencryptedLockbox.Metadata) -> Bool {
        let name = lockboxMetadata.name
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path(percentEncoded: false)
        
        if !fileManager.fileExists(atPath: lockboxPath) {
            do {
                try fileManager.createDirectory(at: lockboxURL, withIntermediateDirectories: true)
            } catch {
                print("[Error] Locker room store failed to write unencrypted lockbox directory \(name) at path \(lockboxPath) with \(error)")
                return false
            }
        }
        
        let lockboxMetadataURL = lockerRoomURLProvider.urlForLockboxMetadata(name: name)
        let lockboxMetadataPath = lockboxMetadataURL.path(percentEncoded: false)
        
        do {
            let metadataPlistData = try encoder.encode(lockboxMetadata)
            do {
                try metadataPlistData.write(to: lockboxMetadataURL, options: .atomic)
                return true
            } catch {
                print("[Error] Locker room store failed to write unencrypted lockbox metadata \(name) with plist data \(metadataPlistData) to path \(lockboxMetadataPath) with error \(error)")
                return false
            }
            
        } catch {
            print("[Error] Locker room store failed to encode unencrypted lockbox metadata \(name) with metadata \(lockboxMetadata) with error \(error)")
            return false
        }
    }
    
    func readEncryptedLockboxMetadata(name: String) -> EncryptedLockbox.Metadata? {
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Locker room store failed to read encrypted lockbox \(name) at non-existing path \(lockboxPath)")
            return nil
        }
        
        let lockboxMetadataURL = lockerRoomURLProvider.urlForLockboxMetadata(name: name)
        let lockboxMetadataPath = lockboxMetadataURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: lockboxMetadataPath) else {
            print("[Error] Locker room store failed to read encrypted lockbox metadata \(name) at non-existing path \(lockboxMetadataPath)")
            return nil
        }
        
        do {
            let metadataPlistData = try Data(contentsOf: lockboxMetadataURL, options: .mappedIfSafe)
            
            do {
                return try decoder.decode(EncryptedLockbox.Metadata.self, from: metadataPlistData)
            } catch {
                print("[Error] Locker room store failed to decode encrypted lockbox metadata \(name) with plist data \(metadataPlistData) at path \(lockboxMetadataPath) with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Locker room store failed to read encrypted lockbox metadata \(name) at path \(lockboxMetadataPath) with error \(error)")
            return nil
        }
    }
    
    func writeEncryptedLockboxMetadata(_ lockboxMetadata: EncryptedLockbox.Metadata) -> Bool {
        let name = lockboxMetadata.name
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path(percentEncoded: false)
        
        if !fileManager.fileExists(atPath: lockboxPath) {
            do {
                try fileManager.createDirectory(at: lockboxURL, withIntermediateDirectories: true)
            } catch {
                print("[Error] Locker room store failed to write encrypted lockbox directory \(name) at path \(lockboxPath) with \(error)")
                return false
            }
        }
        
        let lockboxMetadataURL = lockerRoomURLProvider.urlForLockboxMetadata(name: name)
        let lockboxMetadataPath = lockboxMetadataURL.path(percentEncoded: false)
        
        do {
            let metadataPlistData = try encoder.encode(lockboxMetadata)
            do {
                try metadataPlistData.write(to: lockboxMetadataURL, options: .atomic)
                return true
            } catch {
                print("[Error] Locker room store failed to write encrypted lockbox metadata \(name) with plist data \(metadataPlistData) to path \(lockboxMetadataPath) with error \(error)")
                return false
            }
            
        } catch {
            print("[Error] Locker room store failed to encode encrypted lockbox metadata \(name) with metadata \(lockboxMetadata) with error \(error)")
            return false
        }
    }
    
    func lockboxExists(name: String) -> Bool {
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path(percentEncoded: false)
        return fileManager.fileExists(atPath: lockboxPath)
    }
    
    func removeLockbox(name: String) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Locker room store failed to remove lockbock with empty name")
            return false
        }
        
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Locker room store failed to remove lockbox \(name) at non-existing path \(lockboxPath)")
            return false
        }
        
        do {
            try fileManager.removeItem(at: lockboxURL)
            return true
        } catch {
            print("[Error] Locker room store failed to remove lockbox \(name) at path \(lockboxPath)")
            return false
        }
    }
    
    func removeUnencryptedContent(name: String) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Locker room store failed to remove lockbox unencrypted content with empty name")
            return false
        }
        
        let lockboxUnencryptedContentURL = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let lockboxUnencryptedContentPath = lockboxUnencryptedContentURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: lockboxUnencryptedContentPath) else {
            print("[Error] Locker room store failed to remove lockbox unencrypted content \(name) at non-existing path \(lockboxUnencryptedContentPath)")
            return false
        }
        
        do {
            try fileManager.removeItem(at: lockboxUnencryptedContentURL)
            return true
        } catch {
            print("[Error] Locker room store failed to remove lockbox unencrypted content \(name) at path \(lockboxUnencryptedContentPath)")
            return false
        }
    }
    
    func removeEncryptedContent(name: String) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Locker room store failed to remove lockbox encrypted content with empty name")
            return false
        }
        
        let lockboxEncryptedContentURL = lockerRoomURLProvider.urlForLockboxEncryptedContent(name: name)
        let lockboxEncryptedContentPath = lockboxEncryptedContentURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: lockboxEncryptedContentPath) else {
            print("[Error] Locker room store failed to remove lockbox encrypted content \(name) at non-existing path \(lockboxEncryptedContentPath)")
            return false
        }
        
        do {
            try fileManager.removeItem(at: lockboxEncryptedContentURL)
            return true
        } catch {
            print("[Error] Locker room store failed to remove lockbox encrypted content \(name) at path \(lockboxEncryptedContentPath)")
            return false
        }
    }
    
    var unencryptedLockboxMetdatas: [UnencryptedLockbox.Metadata] {
        return lockboxNames(wantsEncrypted: false).compactMap { lockboxName in
            guard let metadata = readUnencryptedLockboxMetadata(name: lockboxName) else {
                print("[Error] Locker room store failed to read unencrypted lockbox metadata \(lockboxName)")
                return nil
            }
            return metadata
        }
    }
    
    var encryptedLockboxMetadatas: [EncryptedLockbox.Metadata] {
        return lockboxNames(wantsEncrypted: true).compactMap { lockboxName in
            guard let metadata = readEncryptedLockboxMetadata(name: lockboxName) else {
                print("[Error] Locker room store failed to read encrypted lockbox metadata \(lockboxName)")
                return nil
            }
            return metadata
        }
    }
    
    private func lockboxNames(wantsEncrypted: Bool) -> [String] {
        let baseLockboxesURL = lockerRoomURLProvider.urlForLockboxes
        
        do {
            let lockboxURLs = try fileManager.contentsOfDirectory(at: baseLockboxesURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]).filter { lockboxURL in
                var isDirectory: ObjCBool = false
                let lockboxPath = lockboxURL.path(percentEncoded: false)
                
                guard fileManager.fileExists(atPath: lockboxPath, isDirectory: &isDirectory) else {
                    return false
                }
                return isDirectory.boolValue
            }
            
            return lockboxURLs.compactMap { lockboxURL -> String? in
                let lockboxName = lockboxURL.lastPathComponent
                let isEncrypted = isLockboxEncrypted(name: lockboxName)
                
                guard isEncrypted == wantsEncrypted else {
                    return nil
                }
                return lockboxName
            }
        } catch {
            print("[Warning] Locker room store failed to get lockbox URLs with error \(error)")
            return [String]()
        }
    }
    
    private func isLockboxEncrypted(name: String) -> Bool {
        let lockboxEncryptedContentURL = lockerRoomURLProvider.urlForLockboxEncryptedContent(name: name)
        let lockboxEncryptedContentPath = lockboxEncryptedContentURL.path(percentEncoded: false)
        
        let lockboxUnencryptedContentURL = lockerRoomURLProvider.urlForLockboxUnencryptedContent(name: name)
        let lockboxUnencryptedContentPath = lockboxUnencryptedContentURL.path(percentEncoded: false)
        
        return fileManager.fileExists(atPath: lockboxEncryptedContentPath) && !fileManager.fileExists(atPath: lockboxUnencryptedContentPath)
    }
    
    func readLockboxKey(name: String) -> LockboxKey? {
        let keyURL = lockerRoomURLProvider.urlForKey(name: name)
        let keyPath = keyURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: keyPath) else {
            print("[Error] Locker room store failed to read key \(name) at non-existing path \(keyPath)")
            return nil
        }
        
        let keyFileURL = lockerRoomURLProvider.urlForKeyFile(name: name)
        let keyFilePath = keyFileURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: keyFilePath) else {
            print("[Error] Locker room store failed to read key \(name) at non-existing file path \(keyFilePath)")
            return nil
        }
        
        do {
            let keyPlistData = try Data(contentsOf: keyFileURL, options: .mappedIfSafe)
            
            do {
                 return try decoder.decode(LockboxKey.self, from: keyPlistData)
            } catch {
                print("[Error] Locker room store failed to decode key \(name) with plist data \(keyPlistData) at path \(keyFilePath) with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Locker room store failed to read key \(name) with error \(error)")
            return nil
        }
    }
    
    func writeLockboxKey(_ key: LockboxKey?, name: String) -> Bool {
        let keyFileURL = lockerRoomURLProvider.urlForKeyFile(name: name)
        let keyFilePath = keyFileURL.path(percentEncoded: false)
        
        guard let key else {
            do {
                try fileManager.removeItem(at: keyFileURL)
                return true
            } catch {
                print("[Error] Locker room store failed to remove key \(name) at path \(keyFilePath) with error \(error)")
                return false
            }
        }
        
        do {
            let keyPlistData = try encoder.encode(key)
            let keyURL = lockerRoomURLProvider.urlForKey(name: name)
            let keyPath = keyURL.path(percentEncoded: false)
            
            if !fileManager.fileExists(atPath: keyPath) {
                do {
                    try fileManager.createDirectory(at: keyURL, withIntermediateDirectories: true)
                } catch {
                    print("[Error] Locker room store failed to create key directory \(name) at path \(keyPath)")
                    return false
                }
            }
            
            do {
                try keyPlistData.write(to: keyFileURL, options: .atomic)
                return true
            } catch {
                print("[Error] Locker room store failed to write key \(name) with plist data \(keyPlistData) to path \(keyFileURL)")
                return false
            }
        } catch {
            print("[Error] Locker room store failed to encode key \(name) at path \(keyFilePath) with error \(error)")
        }
        return true
    }
    
    func lockboxKeyExists(name: String) -> Bool {
        let keyURL = lockerRoomURLProvider.urlForKey(name: name)
        let keyPath = keyURL.path(percentEncoded: false)
        return fileManager.fileExists(atPath: keyPath)
    }
    
    func removeLockboxKey(name: String) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Locker room store failed to remove key with empty name")
            return false
        }
        
        let keyURL = lockerRoomURLProvider.urlForKey(name: name)
        let keyPath = keyURL.path(percentEncoded: false)
        
        guard fileManager.fileExists(atPath: keyPath) else {
            print("[Error] Locker room store failed to remove key \(name) at non-existing path \(keyPath)")
            return false
        }
        
        do {
            try fileManager.removeItem(at: keyURL)
            return true
        } catch {
            print("[Error] Locker room store failed to remove key \(name) at path \(keyPath)")
            return false
        }
    }
    
    var lockboxKeys: [LockboxKey] {
        let baseKeysURL = lockerRoomURLProvider.urlForKeys
        
        do {
            let keyURLs = try fileManager.contentsOfDirectory(at: baseKeysURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]).filter { keyURL in
                var isDirectory: ObjCBool = false
                let keyPath = keyURL.path(percentEncoded: false)
                
                guard fileManager.fileExists(atPath: keyPath, isDirectory: &isDirectory) else {
                    return false
                }
                return isDirectory.boolValue
            }
            
            return keyURLs.compactMap { keyURL -> LockboxKey? in
                let keyName = keyURL.lastPathComponent
                
                guard let key = readLockboxKey(name: keyName) else {
                    print("[Error] Locker room store failed to read key \(keyName)")
                    return nil
                }
                return key
            }
        } catch {
            print("[Warning] Locker room store failed to get key URLs with error \(error)")
            return [LockboxKey]()
        }
    }
}
