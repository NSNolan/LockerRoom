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
    func addLockbox(name: String) -> Bool // Called before `hdiutil` creates a lockbox disk image because it will not create intermediary directories.
    func removeLockbox(name: String) -> Bool
    
    func readFromLockbox(name: String, fileType: LockerRoomLockboxFileType) -> Data?
    func writeToLockbox(_ data: Data?, name: String, fileType: LockerRoomLockboxFileType) -> Bool
    
    func lockboxExists(name: String) -> Bool
    func lockboxFileExists(name: String, fileType: LockerRoomLockboxFileType) -> Bool
    func lockboxFileSize(name: String, fileType: LockerRoomLockboxFileType) -> Int
    func lockboxURLs() -> [URL]
    
    // Lockbox Keys
    // func addLockboxKey(name: String) -> Bool
    func removeLockboxKey(name: String) -> Bool
    
    func readLockboxKey(name: String, fileType: LockerRoomKeyFileType) -> LockboxKey?
    func writeLockboxKey(_ key: LockboxKey?, name: String, fileType: LockerRoomKeyFileType) -> Bool
    
    func lockboxKeyExists(name: String) -> Bool
    func lockboxKeyURLs() -> [URL]
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
            print("[Error] Lockbox store failed to add lockbock with empty name")
            return false
        }
        
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        guard !fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Lockbox store failed to add lockbock \(name) at existing path \(lockboxPath)")
            return false
        }
        
        do {
            try fileManager.createDirectory(at: lockboxURL, withIntermediateDirectories: true)
            return true
        } catch {
            print("[Error] Lockbox store failed to add lockbox \(name) at path \(lockboxPath)")
            return false
        }
    }
    
    func removeLockbox(name: String) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Lockbox store failed to remove lockbock with empty name")
            return false
        }
        
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        guard fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Lockbox store failed to remove lockbox \(name) at non-existing path \(lockboxPath)")
            return false
        }
        
        do {
            try fileManager.removeItem(at: lockboxURL)
            return true
        } catch {
            print("[Error] Lockbox store failed to remove lockbox \(name) at path \(lockboxPath)")
            return false
        }
    }
    
    func readFromLockbox(name: String, fileType: LockerRoomLockboxFileType) -> Data? {
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        guard fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Lockbox store failed to read lockbox \(name) at non-existing path \(lockboxPath)")
            return nil
        }
        
        let lockboxFileURL = lockerRoomURLProvider.urlForLockboxFile(name: name, type: fileType)
        let lockboxFilePath = lockboxFileURL.path()
        
        guard fileManager.fileExists(atPath: lockboxFilePath) else {
            print("[Error] Lockbox store failed to read lockbox \(name) for type \(fileType) at non-existing file path \(lockboxFilePath)")
            return nil
        }
        
        do {
            return try Data(contentsOf: lockboxFileURL, options: .mappedIfSafe)
        } catch {
            print("[Error] Lockbox store failed to read lockbox \(name) for type \(fileType) with error \(error)")
            return nil
        }
    }
    
    func writeToLockbox(_ data: Data?, name: String, fileType: LockerRoomLockboxFileType) -> Bool {
        let lockboxFileURL = lockerRoomURLProvider.urlForLockboxFile(name: name, type: fileType)
        let lockboxFilePath = lockboxFileURL.path()
        
        guard let data else {
            do {
                try fileManager.removeItem(at: lockboxFileURL)
                return true
            } catch {
                print("[Error] Lockbox store failed to remove lockbox \(name) for type \(fileType) at path \(lockboxFilePath) with error \(error)")
                return false
            }
        }
        
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        if !fileManager.fileExists(atPath: lockboxPath) {
            do {
                try fileManager.createDirectory(at: lockboxURL, withIntermediateDirectories: true)
            } catch {
                print("[Error] Lockbox store failed to write lockbox directory \(name) at path \(lockboxPath)")
                return false
            }
        }
        
        do {
            try data.write(to: lockboxFileURL, options: .atomic)
            return true
        } catch {
            print("[Error] Lockbox store failed to write lockbox \(name) for type \(fileType) with error \(error)")
            return false
        }
    }
    
    func lockboxExists(name: String) -> Bool {
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        return fileManager.fileExists(atPath: lockboxPath)
    }
    
    func lockboxFileExists(name: String, fileType: LockerRoomLockboxFileType) -> Bool {
        let lockboxFileURL = lockerRoomURLProvider.urlForLockboxFile(name: name, type: fileType)
        let lockboxFilePath = lockboxFileURL.path()
        return fileManager.fileExists(atPath: lockboxFilePath)
    }
    
    func lockboxFileSize(name: String, fileType: LockerRoomLockboxFileType) -> Int {
        let lockboxFileURL = lockerRoomURLProvider.urlForLockboxFile(name: name, type: fileType)
        let lockboxFilePath = lockboxFileURL.path()
        do {
            let fileAttributes = try fileManager.attributesOfItem(atPath: lockboxFilePath)
            if let size = fileAttributes[.size] as? Int {
                return size / (1024 * 1024) // Convert to MBs
            } else {
                print("[Error] Lockbox store failed to cast lockbox file size as Int")
                return 0
            }
        } catch {
            print("[Error] Lockbox store failed to get lockbox file attributes at path \(lockboxFilePath) with error \(error)")
            return 0
        }
    }
    
    func lockboxURLs() -> [URL] {
        let lockboxesURL = lockerRoomURLProvider.urlForLockboxes
        do {
            let lockboxURLs = try fileManager.contentsOfDirectory(at: lockboxesURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]).filter { lockboxURL in
                var isDirectory: ObjCBool = false
                let lockboxPath = lockboxURL.path()
                if fileManager.fileExists(atPath: lockboxPath, isDirectory: &isDirectory) {
                    return isDirectory.boolValue
                } else {
                    return false
                }
            }
            return lockboxURLs
        } catch {
            print("[Warning] Lockbox store failed to get lockbox URLs with error \(error)")
            return [URL]()
        }
    }
    
    func removeLockboxKey(name: String) -> Bool {
        guard !name.isEmpty else {
            print("[Error] Lockbox store failed to remove key with empty name")
            return false
        }
        
        let keyURL = lockerRoomURLProvider.urlForKey(name: name)
        let keyPath = keyURL.path()
        
        guard fileManager.fileExists(atPath: keyPath) else {
            print("[Error] Lockbox store failed to remove key \(name) at non-existing path \(keyPath)")
            return false
        }
        
        do {
            try fileManager.removeItem(at: keyURL)
            return true
        } catch {
            print("[Error] Lockbox store failed to remove key \(name) at path \(keyPath)")
            return false
        }
    }
    
    func readLockboxKey(name: String, fileType: LockerRoomKeyFileType) -> LockboxKey? {
        let keyURL = lockerRoomURLProvider.urlForKey(name: name)
        let keyPath = keyURL.path()
        
        guard fileManager.fileExists(atPath: keyPath) else {
            print("[Error] Lockbox store failed to read key \(name) at non-existing path \(keyPath)")
            return nil
        }
        
        let keyFileURL = lockerRoomURLProvider.urlForKeyFile(name: name, type: .publicKeysFileType)
        let keyFilePath = keyFileURL.path()
        
        guard fileManager.fileExists(atPath: keyFilePath) else {
            print("[Error] Lockbox store failed to read key \(name) for type \(fileType) at path \(keyFilePath)")
            return nil
        }
        
        do {
            let keyPlistData = try Data(contentsOf: keyFileURL, options: .mappedIfSafe)
            
            do {
                 return try decoder.decode(LockboxKey.self, from: keyPlistData)
            } catch {
                print("[Error] Lockbox store failed to decode key \(name) with plist data \(keyPlistData) for type \(fileType) at path \(keyFilePath) with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Lockbox store failed to read key \(name) for type \(fileType) with error \(error)")
            return nil
        }
    }
    
    func writeLockboxKey(_ key: LockboxKey?, name: String, fileType: LockerRoomKeyFileType) -> Bool {
        let keyFileURL = lockerRoomURLProvider.urlForKeyFile(name: name, type: .publicKeysFileType)
        let keyFilePath = keyFileURL.path()
        
        guard let key else {
            do {
                try fileManager.removeItem(at: keyFileURL)
                return true
            } catch {
                print("[Error] Lockbox store failed to remove key \(name) for type \(fileType) at path \(keyFilePath) with error \(error)")
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
                    print("[Error] Lockbox store failed to create key directory \(name) at path \(keyPath)")
                    return false
                }
            }
            
            do {
                try keyPlistData.write(to: keyFileURL, options: .atomic)
                return true
            } catch {
                print("[Error] Lockbox store failed to write key \(name) with plist data \(keyPlistData) for type \(fileType) to path \(keyFileURL)")
                return false
            }
        } catch {
            print("[Error] Lockbox store failed to encode key \(name) for type \(fileType) at path \(keyFilePath) with error \(error)")
        }
        return true
    }
    
    func lockboxKeyExists(name: String) -> Bool {
        let keyURL = lockerRoomURLProvider.urlForKey(name: name)
        let keyPath = keyURL.path()
        return fileManager.fileExists(atPath: keyPath)
    }
    
    func lockboxKeyURLs() -> [URL] {
        let keysURL = lockerRoomURLProvider.urlForKeys

        do {
            let keyURLs = try fileManager.contentsOfDirectory(at: keysURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]).filter { keyURL in
                var isDirectory: ObjCBool = false
                let keyPath = keyURL.path()
                if fileManager.fileExists(atPath: keyPath, isDirectory: &isDirectory) {
                    return isDirectory.boolValue
                } else {
                    return false
                }
            }
            return keyURLs
        } catch {
            print("[Warning] Lockbox store failed to get key URLs with error \(error)")
            return [URL]()
        }
    }
}
