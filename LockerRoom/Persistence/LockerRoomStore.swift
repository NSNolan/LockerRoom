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
    var lockerRoomLockboxes: [LockerRoomLockbox] { get }
    
    // Lockbox Keys
    func removeLockboxKey(name: String) -> Bool
    
    func readLockboxKey(name: String) -> LockboxKey?
    func writeLockboxKey(_ key: LockboxKey?, name: String) -> Bool
    
    func lockboxKeyExists(name: String) -> Bool
    var lockboxKeys: [LockboxKey] { get }
    var lockerRoomEnrolledKeys: [LockerRoomEnrolledKey] { get }
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
        let lockboxPath = lockboxURL.path(percentEncoded:false)
        
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
        let lockboxPath = lockboxURL.path(percentEncoded:false)
        
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
        let lockboxPath = lockboxURL.path(percentEncoded:false)
        
        guard fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Locker room store failed to read unencrypted lockbox \(name) at non-existing path \(lockboxPath)")
            return nil
        }
        
        let lockboxFileURL = lockerRoomURLProvider.urlForUnencryptedLockboxFile(name: name)
        let lockboxFilePath = lockboxFileURL.path(percentEncoded:false)
        
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
        let lockboxFilePath = lockboxFileURL.path(percentEncoded:false)
        
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
        let lockboxPath = lockboxURL.path(percentEncoded:false)
        
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
        let lockboxPath = lockboxURL.path(percentEncoded:false)
        
        guard fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Locker room store failed to read encrypted lockbox \(name) at non-existing path \(lockboxPath)")
            return nil
        }
        
        let lockboxFileURL = lockerRoomURLProvider.urlForEncryptedLockboxFile(name: name)
        let lockboxFilePath = lockboxFileURL.path(percentEncoded:false)
        
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
        let lockboxFilePath = lockboxFileURL.path(percentEncoded:false)
        
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
            let lockboxPath = lockboxURL.path(percentEncoded:false)
            
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
        let lockboxPath = lockboxURL.path(percentEncoded:false)
        return fileManager.fileExists(atPath: lockboxPath)
    }
    
    var lockerRoomLockboxes: [LockerRoomLockbox] {
        let baseLockboxesURL = lockerRoomURLProvider.urlForLockboxes
        
        do {
            let lockboxURLs = try fileManager.contentsOfDirectory(at: baseLockboxesURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]).filter { lockboxURL in
                var isDirectory: ObjCBool = false
                let lockboxPath = lockboxURL.path(percentEncoded:false)
                if fileManager.fileExists(atPath: lockboxPath, isDirectory: &isDirectory) {
                    return isDirectory.boolValue
                } else {
                    return false
                }
            }
            
            return lockboxURLs.compactMap { lockboxURL -> LockerRoomLockbox? in
                let lockboxName = lockboxURL.lastPathComponent
                let isEncrypted = isLockboxEncrypted(name: lockboxName)
                let size: Int
                let encryptionKeyNames: [String]
                if isEncrypted {
                    guard let encryptedLockbox = readEncryptedLockbox(name: lockboxName) else { // TODO: The entire encrypted lockbox content is read into memory when creating lockboxes for the UI.
                        print("[Error] Locker room store failed to read unencrypted lockbox \(lockboxName)")
                        return nil
                    }
                    size = encryptedLockbox.size
                    encryptionKeyNames = encryptedLockbox.encryptionLockboxKeys.map { $0.name }
                } else {
                    size = lockboxUnencryptedSize(name: lockboxName)
                    encryptionKeyNames = [String]()
                }

                return LockerRoomLockbox(name: lockboxName, size: size, url: lockboxURL, isEncrypted: isEncrypted, encryptionKeyNames: encryptionKeyNames)
            }
        } catch {
            print("[Warning] Locker room store failed to get lockbox URLs with error \(error)")
            return [LockerRoomLockbox]()
        }
    }
    
    private func isLockboxEncrypted(name: String) -> Bool {
        let encryptedLockboxFileURL = lockerRoomURLProvider.urlForEncryptedLockboxFile(name: name)
        let encryptedLockboxFilePath = encryptedLockboxFileURL.path(percentEncoded:false)
        
        let unencryptedLockboxFileURL = lockerRoomURLProvider.urlForUnencryptedLockboxFile(name: name)
        let unencryptedLockboxFilePath = unencryptedLockboxFileURL.path(percentEncoded:false)
        
        return fileManager.fileExists(atPath: encryptedLockboxFilePath) && !fileManager.fileExists(atPath: unencryptedLockboxFilePath)
    }
    
    private func lockboxUnencryptedSize(name: String) -> Int {
        let lockboxFileURL = lockerRoomURLProvider.urlForUnencryptedLockboxFile(name: name)
        return lockboxFileSize(name: name, lockboxFileURL: lockboxFileURL)
    }
    
    private func lockboxFileSize(name: String, lockboxFileURL: URL) -> Int {
        let lockboxFilePath = lockboxFileURL.path(percentEncoded:false)
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
        let keyPath = keyURL.path(percentEncoded:false)
        
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
        let keyPath = keyURL.path(percentEncoded:false)
        
        guard fileManager.fileExists(atPath: keyPath) else {
            print("[Error] Locker room store failed to read key \(name) at non-existing path \(keyPath)")
            return nil
        }
        
        let keyFileURL = lockerRoomURLProvider.urlForKeyFile(name: name)
        let keyFilePath = keyFileURL.path(percentEncoded:false)
        
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
        let keyFilePath = keyFileURL.path(percentEncoded:false)
        
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
            let keyPath = keyURL.path(percentEncoded:false)
            
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
        let keyPath = keyURL.path(percentEncoded:false)
        return fileManager.fileExists(atPath: keyPath)
    }
    
    var lockboxKeys: [LockboxKey] {
        let baseKeysURL = lockerRoomURLProvider.urlForKeys
        
        do {
            let keyURLs = try fileManager.contentsOfDirectory(at: baseKeysURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]).filter { keyURL in
                var isDirectory: ObjCBool = false
                let keyPath = keyURL.path(percentEncoded:false)
                if fileManager.fileExists(atPath: keyPath, isDirectory: &isDirectory) {
                    return isDirectory.boolValue
                } else {
                    return false
                }
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
    
    var lockerRoomEnrolledKeys: [LockerRoomEnrolledKey] {
        return lockboxKeys.map { $0.lockerRoomEnrolledKey }
    }
}
