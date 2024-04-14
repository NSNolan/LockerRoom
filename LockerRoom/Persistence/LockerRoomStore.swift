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
    func addLockbox(name: String) -> Bool // Called before `hdiutil` creates a unencrypted lockbox disk image because it will not create intermediary directories itself.
    func removeLockbox(name: String) -> Bool
    
    func readUnencryptedLockbox(name: String) -> Data?
    func writeUnencryptedLockbox(_ data: Data?, name: String) -> Bool
    
    func readEncryptedLockbox(name: String) -> EncryptedLockbox?
    func writeEncryptedLockbox(_ lockbox: EncryptedLockbox?, name: String) -> Bool
    
    func lockboxExists(name: String) -> Bool
    var lockboxMetadatas: [LockerRoomLockboxMetadata] { get }
    
    // Lockbox Keys
    func removeLockboxKey(name: String) -> Bool
    
    func readLockboxKey(name: String) -> LockboxKey?
    func writeLockboxKey(_ key: LockboxKey?, name: String) -> Bool
    
    func lockboxKeyExists(name: String) -> Bool
    var lockboxKeys: [LockboxKey] { get }
    var lockboxKeyMetadatas: [LockerRoomLockboxKeyMetadata] { get }
}

struct LockerRoomStore: LockerRoomStoring {
    private let fileManager = FileManager.default
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()
    
    internal var lockerRoomURLProvider: LockerRoomURLProviding
        
    init(lockerRoomURLProvider: LockerRoomURLProviding = LockerRoomURLProvider()) {
        self.lockerRoomURLProvider = lockerRoomURLProvider
        encoder.outputFormat = .xml
    }
    
    func addLockbox(name: String) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Locker room store failed to add lockbock with empty name")
            return false
        }
        
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        guard !fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Locker room store failed to add lockbock \(name) at existing path \(lockboxPath)")
            return false
        }
        
        do {
            try fileManager.createDirectory(at: lockboxURL, withIntermediateDirectories: true)
            return true
        } catch {
            print("[Error] Locker room store failed to add lockbox \(name) at path \(lockboxPath)")
            return false
        }
    }
    
    func removeLockbox(name: String) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Locker room store failed to remove lockbock with empty name")
            return false
        }
        
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
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
    
    func readUnencryptedLockbox(name: String) -> Data? {
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        guard fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Locker room store failed to read unencrypted lockbox \(name) at non-existing path \(lockboxPath)")
            return nil
        }
        
        let lockboxFileURL = lockerRoomURLProvider.urlForUnencryptedLockboxFile(name: name)
        let lockboxFilePath = lockboxFileURL.path()
        
        guard fileManager.fileExists(atPath: lockboxFilePath) else {
            print("[Error] Locker room store failed to read unencrypted lockbox \(name) at non-existing file path \(lockboxFilePath)")
            return nil
        }
        
        do {
            return try Data(contentsOf: lockboxFileURL, options: .mappedIfSafe)
        } catch {
            print("[Error] Locker room store failed to read unencrypted lockbox \(name) with error \(error)")
            return nil
        }
    }
    
    func writeUnencryptedLockbox(_ data: Data?, name: String) -> Bool {
        let lockboxFileURL = lockerRoomURLProvider.urlForUnencryptedLockboxFile(name: name)
        let lockboxFilePath = lockboxFileURL.path()
        
        guard let data else {
            do {
                try fileManager.removeItem(at: lockboxFileURL)
                return true
            } catch {
                print("[Error] Locker room store failed to remove unencrypted lockbox \(name) at path \(lockboxFilePath) with error \(error)")
                return false
            }
        }
        
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        if !fileManager.fileExists(atPath: lockboxPath) {
            do {
                try fileManager.createDirectory(at: lockboxURL, withIntermediateDirectories: true)
            } catch {
                print("[Error] Locker room store failed to write unencrypted lockbox directory \(name) at path \(lockboxPath)")
                return false
            }
        }
        
        do {
            try data.write(to: lockboxFileURL, options: .atomic)
            return true
        } catch {
            print("[Error] Locker room store failed to write unencrypted lockbox \(name) with error \(error)")
            return false
        }
    }
    
    func readEncryptedLockbox(name: String) -> EncryptedLockbox? {
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        guard fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Locker room store failed to read encrypted lockbox \(name) at non-existing path \(lockboxPath)")
            return nil
        }
        
        let lockboxFileURL = lockerRoomURLProvider.urlForEncryptedLockboxFile(name: name)
        let lockboxFilePath = lockboxFileURL.path()
        
        guard fileManager.fileExists(atPath: lockboxFilePath) else {
            print("[Error] Locker room store failed to read encrypted lockbox \(name) at non-existing file path \(lockboxFilePath)")
            return nil
        }
        
        do {
            let lockboxPlistData = try Data(contentsOf: lockboxFileURL, options: .mappedIfSafe)
            
            do {
                 return try decoder.decode(EncryptedLockbox.self, from: lockboxPlistData)
            } catch {
                print("[Error] Locker room store failed to decode encrypted lockbox \(name) with plist data \(lockboxPlistData) at path \(lockboxFilePath) with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Locker room store failed to read encrypted lockbox \(name) with error \(error)")
            return nil
        }
    }
    
    func writeEncryptedLockbox(_ lockbox: EncryptedLockbox?, name: String) -> Bool {
        let lockboxFileURL = lockerRoomURLProvider.urlForEncryptedLockboxFile(name: name)
        let lockboxFilePath = lockboxFileURL.path()
        
        guard let lockbox else {
            do {
                try fileManager.removeItem(at: lockboxFileURL)
                return true
            } catch {
                print("[Error] Locker room store failed to remove encrypted lockbox \(name) at path \(lockboxFilePath) with error \(error)")
                return false
            }
        }
        
        do {
            let lockboxPlistData = try encoder.encode(lockbox)
            let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
            let lockboxPath = lockboxURL.path()
            
            if !fileManager.fileExists(atPath: lockboxPath) {
                do {
                    try fileManager.createDirectory(at: lockboxURL, withIntermediateDirectories: true)
                } catch {
                    print("[Error] Locker room store failed to create encrypted lockbox directory \(name) at path \(lockboxPath)")
                    return false
                }
            }
            
            do {
                try lockboxPlistData.write(to: lockboxFileURL, options: .atomic)
                return true
            } catch {
                print("[Error] Locker room store failed to write encryped lockbox \(name) with plist data \(lockboxPlistData) to path \(lockboxFileURL)")
                return false
            }
        } catch {
            print("[Error] Locker room store failed to encode encrypted lockbox \(name) at path \(lockboxFilePath) with error \(error)")
        }
        return true
    }
    
    func lockboxExists(name: String) -> Bool {
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        return fileManager.fileExists(atPath: lockboxPath)
    }
    
    var lockboxMetadatas: [LockerRoomLockboxMetadata] {
        let baseLockboxesURL = lockerRoomURLProvider.urlForLockboxes
        
        do {
            let lockboxURLs = try fileManager.contentsOfDirectory(at: baseLockboxesURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]).filter { lockboxURL in
                var isDirectory: ObjCBool = false
                let lockboxPath = lockboxURL.path()
                if fileManager.fileExists(atPath: lockboxPath, isDirectory: &isDirectory) {
                    return isDirectory.boolValue
                } else {
                    return false
                }
            }
            
            return lockboxURLs.map { lockboxURL in
                let lockboxName = lockboxURL.lastPathComponent
                let isEncrypted = isLockboxEncrypted(name: lockboxName)
                let size: Int
                if isEncrypted {
                    size = lockboxEncryptedSize(name: lockboxName)
                } else {
                    size = lockboxUnencryptedSize(name: lockboxName)
                }

                return LockerRoomLockboxMetadata(name: lockboxName, size: size, url: lockboxURL, isEncrypted: isEncrypted)
            }
        } catch {
            print("[Warning] Locker room store failed to get lockbox URLs with error \(error)")
            return [LockerRoomLockboxMetadata]()
        }
    }
    
    private func isLockboxEncrypted(name: String) -> Bool {
        let encryptedLockboxFileURL = lockerRoomURLProvider.urlForEncryptedLockboxFile(name: name)
        let encryptedLockboxFilePath = encryptedLockboxFileURL.path()
        
        let unencryptedLockboxFileURL = lockerRoomURLProvider.urlForUnencryptedLockboxFile(name: name)
        let unencryptedLockboxFilePath = unencryptedLockboxFileURL.path()
        
        return fileManager.fileExists(atPath: encryptedLockboxFilePath) && !fileManager.fileExists(atPath: unencryptedLockboxFilePath)
    }
    
    private func lockboxUnencryptedSize(name: String) -> Int {
        let lockboxFileURL = lockerRoomURLProvider.urlForUnencryptedLockboxFile(name: name)
        return lockboxFileSize(name: name, lockboxFileURL: lockboxFileURL)
    }
    
    private func lockboxEncryptedSize(name: String) -> Int {
        let lockboxFileURL = lockerRoomURLProvider.urlForEncryptedLockboxFile(name: name)
        return lockboxFileSize(name: name, lockboxFileURL: lockboxFileURL)
    }
    
    private func lockboxFileSize(name: String, lockboxFileURL: URL) -> Int {
        let lockboxFilePath = lockboxFileURL.path()
        do {
            let fileAttributes = try fileManager.attributesOfItem(atPath: lockboxFilePath)
            if let size = fileAttributes[.size] as? Int {
                return size / (1024 * 1024) // Convert to MBs
            } else {
                print("[Error] Locker room store failed to cast lockbox file size as Int")
                return 0
            }
        } catch {
            print("[Error] Locker room store failed to get lockbox file attributes at path \(lockboxFilePath) with error \(error)")
            return 0
        }
    }
    
    func removeLockboxKey(name: String) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Locker room store failed to remove key with empty name")
            return false
        }
        
        let keyURL = lockerRoomURLProvider.urlForKey(name: name)
        let keyPath = keyURL.path()
        
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
    
    func readLockboxKey(name: String) -> LockboxKey? {
        let keyURL = lockerRoomURLProvider.urlForKey(name: name)
        let keyPath = keyURL.path()
        
        guard fileManager.fileExists(atPath: keyPath) else {
            print("[Error] Locker room store failed to read key \(name) at non-existing path \(keyPath)")
            return nil
        }
        
        let keyFileURL = lockerRoomURLProvider.urlForKeyFile(name: name)
        let keyFilePath = keyFileURL.path()
        
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
        let keyFilePath = keyFileURL.path()
        
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
            let keyPath = keyURL.path()
            
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
        let keyPath = keyURL.path()
        return fileManager.fileExists(atPath: keyPath)
    }
    
    var lockboxKeys: [LockboxKey] {
        let baseKeysURL = lockerRoomURLProvider.urlForKeys
        
        do {
            let keyURLs = try fileManager.contentsOfDirectory(at: baseKeysURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]).filter { keyURL in
                var isDirectory: ObjCBool = false
                let keyPath = keyURL.path()
                if fileManager.fileExists(atPath: keyPath, isDirectory: &isDirectory) {
                    return isDirectory.boolValue
                } else {
                    return false
                }
            }
            let keyNames = keyURLs.map { $0.lastPathComponent }
            
            var keys = [LockboxKey]()
            for keyName in keyNames {
                guard let key = readLockboxKey(name: keyName) else {
                    print("[Error] Locker room store failed to read key \(keyName)")
                    continue
                }
                keys.append(key)
            }
            
            return keys
        } catch {
            print("[Warning] Locker room store failed to get key URLs with error \(error)")
            return [LockboxKey]()
        }
    }
    
    var lockboxKeyMetadatas: [LockerRoomLockboxKeyMetadata] {
        return lockboxKeys.map { $0.metadata }
    }
}
