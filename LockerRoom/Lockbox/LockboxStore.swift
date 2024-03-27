//
//  LockboxStore.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/25/24.
//

import Foundation

protocol LockboxStoring {
    var lockboxURLProvider: LockboxURLProviding { get }
    
    func addLockbox(name: String) -> Bool
    func removeLockbox(name: String) -> Bool
    
    func readFromLockbox(name: String, fileType: LockboxFileType) -> Data?
    func writeToLockbox(data: Data?, name: String, fileType: LockboxFileType) -> Bool
    
    func lockboxExists(name: String) -> Bool
    func lockboxFileExists(name: String, fileType: LockboxFileType) -> Bool
    func allLockboxURLs() -> [URL]
    
    func lockboxSize(name: String, fileType: LockboxFileType) -> Int
    func lockboxFileSize(name: String, fileType: LockboxFileType) -> Int
}

struct LockboxStore: LockboxStoring {
    private let fileManager = FileManager.default
    
    internal var lockboxURLProvider: LockboxURLProviding
    
    static let shared = LockboxStore()
    
    private init(lockboxURLProvider: LockboxURLProviding = LockboxURLProvider()) {
        self.lockboxURLProvider = lockboxURLProvider
    }
    
    func addLockbox(name: String) -> Bool {
        let lockboxURL = lockboxURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        do {
            try fileManager.createDirectory(at: lockboxURL, withIntermediateDirectories: true)
            return true
        } catch {
            print("[Error] Lockbox store failed to add lockbox \(name) at path \(lockboxPath)")
            return false
        }
    }
    
    func removeLockbox(name: String) -> Bool {
        let lockboxURL = lockboxURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        do {
            try fileManager.removeItem(at: lockboxURL)
            return true
        } catch {
            print("[Error] Lockbox store failed to remove lockbox \(name) at path \(lockboxPath)")
            return false
        }
    }
    
    func readFromLockbox(name: String, fileType: LockboxFileType) -> Data? {
        let lockboxURL = lockboxURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        guard fileManager.fileExists(atPath: lockboxPath) else {
            print("[Error] Lockbox store failed to find lockbox \(name) at path \(lockboxPath)")
            return nil
        }
        
        let lockboxFileURL = lockboxURLProvider.urlForLockboxFile(name: name, type: fileType)
        let lockboxFilePath = lockboxFileURL.path()
        
        guard fileManager.fileExists(atPath: lockboxFilePath) else {
            print("[Error] Lockbox store failed to find lockbox file for \(name) of type \(fileType) at path \(lockboxFilePath)")
            return nil
        }
        
        do {
            return try Data(contentsOf: lockboxFileURL, options: .mappedIfSafe)
        } catch {
            print("[Error] Lockbox store failed to read lockbox file for \(name) of type \(fileType) with error \(error)")
            return nil
        }
    }
    
    func writeToLockbox(data: Data?, name: String, fileType: LockboxFileType) -> Bool {
        let lockboxFileURL = lockboxURLProvider.urlForLockboxFile(name: name, type: fileType)
        let lockboxFilePath = lockboxFileURL.path()
        
        guard let data else {
            do {
                try fileManager.removeItem(at: lockboxFileURL)
                return true
            } catch {
                print("[Error] Lockbox store failed to remove lockbox file for \(name) of type \(fileType) at path \(lockboxFilePath) with error \(error)")
                return false
            }
        }
        
        let lockboxURL = lockboxURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        
        if !fileManager.fileExists(atPath: lockboxPath) {
            do {
                try fileManager.createDirectory(at: lockboxURL, withIntermediateDirectories: true)
            } catch {
                print("[Error] Lockbox store failed to create lockbox directory for \(name) at path \(lockboxPath)")
                return false
            }
        }
        
        do {
            try data.write(to: lockboxFileURL, options: .atomic)
            return true
        } catch {
            print("[Error] Lockbox store failed to write data for \(name) of type \(fileType) to path \(lockboxFilePath)")
            return false
        }
    }
    
    func lockboxExists(name: String) -> Bool {
        let lockboxURL = lockboxURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        return fileManager.fileExists(atPath: lockboxPath)
    }
    
    func lockboxFileExists(name: String, fileType: LockboxFileType) -> Bool {
        let lockboxFileURL = lockboxURLProvider.urlForLockboxFile(name: name, type: fileType)
        let lockboxFilePath = lockboxFileURL.path()
        return fileManager.fileExists(atPath: lockboxFilePath)
    }
    
    func allLockboxURLs() -> [URL] {
        let lockboxesURL = lockboxURLProvider.urlForLockboxes
        do {
            let lockboxURLS = try fileManager.contentsOfDirectory(at: lockboxesURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]).filter { lockboxURL in
                var isDirectory: ObjCBool = false
                let lockboxPath = lockboxURL.path()
                if fileManager.fileExists(atPath: lockboxPath, isDirectory: &isDirectory) {
                    return isDirectory.boolValue
                } else {
                    return false
                }
            }
            return lockboxURLS
        } catch {
            print("[Error] Lockbox store failed to get all lockbox URLs with error \(error)")
            return [URL]()
        }
    }
    
    func lockboxSize(name: String, fileType: LockboxFileType) -> Int {
        let lockboxURL = lockboxURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path()
        do {
            let fileAttributes = try fileManager.attributesOfItem(atPath: lockboxPath)
            if let size = fileAttributes[.size] as? Int {
                return size / (1024 * 1024) // Convert to MBs
            } else {
                print("[Error] Lockbox store failed to cast lockbox size as Int")
                return 0
            }
        } catch {
            print("[Error] Lockbox store failed to get lockbox attributes at path \(lockboxPath) with error \(error)")
            return 0
        }
    }
    
    func lockboxFileSize(name: String, fileType: LockboxFileType) -> Int {
        let lockboxFileURL = lockboxURLProvider.urlForLockboxFile(name: name, type: fileType)
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
}
