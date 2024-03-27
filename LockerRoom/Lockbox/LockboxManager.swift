//
//  LockboxManager.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

class LockboxManager: ObservableObject {
    private let fileManager = FileManager.default
    
    internal let lockboxStore: LockboxStoring
    
    @Published var lockboxMetadatas = [LockerRoomLockboxMetadata]()
    
    static let shared = LockboxManager()
    
    private init(lockboxStore: LockboxStoring = LockboxStore.shared) {        
        self.lockboxStore = lockboxStore
        self.lockboxMetadatas = updateLockboxMetadatas()
    }
    
    func addUnencryptedLockbox(name: String, size: Int) -> UnencryptedLockbox? {
        guard !lockboxStore.lockboxExists(name: name) else {
            print("[Error] Lockbox manager failed to add unencrypted lockbox \(name) to existing path")
            return nil
        } 
        
        let unencryptedLockbox = UnencryptedLockbox(name: name, lockboxStore: lockboxStore)
        guard unencryptedLockbox.create(withSize: size) else {
            print("[Error] Lockbox manager failed to add unencrypted lockbox \(name) to path")
            return nil
        }
        
        self.lockboxMetadatas = updateLockboxMetadatas()
        return unencryptedLockbox
    }
    
    func addUnencryptedLockbox(name: String, unencryptedContent: Data) -> UnencryptedLockbox? {
        guard !lockboxStore.lockboxExists(name: name) else {
            print("[Error] Lockbox manager failed to add unencrypted lockbox \(name) to existing path with existing data \(unencryptedContent)")
            return nil
        }
        
        let unencryptedLockbox = UnencryptedLockbox(name: name, exists: true, lockboxStore: lockboxStore)
        guard unencryptedLockbox.create(withSize: 0, orExistingData: unencryptedContent) else {
            print("[Error] Lockbox manager failed to add unencrypted lockbox \(name) to path with existing data \(unencryptedContent)")
            return nil
        }
        
        self.lockboxMetadatas = updateLockboxMetadatas()
        return unencryptedLockbox
    }
    
    func addEncryptedLockbox(name: String, encryptedContent: Data, encryptedSymmetricKey: Data) -> EncryptedLockbox? {
        guard !lockboxStore.lockboxExists(name: name) else {
            print("[Error] Lockbox manager failed to add encrypted lockbox \(name) to existing path")
            return nil
        }

        let encryptedLockbox = EncryptedLockbox(name: name, lockboxStore: lockboxStore)
        guard encryptedLockbox.create(encryptedContent: encryptedContent, encryptedSymmetricKey: encryptedSymmetricKey) else {
            print("[Error] Lockbox manager failed to add encrypted lockbox \(name)")
            return nil
        }
        
        self.lockboxMetadatas = updateLockboxMetadatas()
        return encryptedLockbox
    }
    
    func removeUnencryptedLockbox(name: String) -> Bool {
        guard lockboxStore.lockboxExists(name: name) else {
            print("[Error] Lockbox manager failed to remove unencrypted lockbox \(name) at non-existing path")
            return false
        }
        
        let existingUnencryptedLockbox = UnencryptedLockbox(name: name, exists: true, lockboxStore: lockboxStore)
        guard existingUnencryptedLockbox.destroy() else {
            print("[Error] Lockbox manager failed to remove unencrypted lockbox \(name)")
            return false
        }
        
        self.lockboxMetadatas = updateLockboxMetadatas()
        return true
    }
    
    func removeEncryptedLockbox(name: String) -> Bool {
        guard lockboxStore.lockboxExists(name: name) else {
            print("[Error] Lockbox manager failed to remove encrypted lockbox \(name) at non-existing path")
            return false
        }
        
        let existingEncryptedLockbox = EncryptedLockbox(name: name, lockboxStore: lockboxStore)
        guard existingEncryptedLockbox.destroy() else {
            print("[Error] Lockbox manager failed to remove encrypted lockbox \(name)")
            return false
        }
        
        self.lockboxMetadatas = updateLockboxMetadatas()
        return true
    }
    
    private func updateLockboxMetadatas() -> [LockerRoomLockboxMetadata] {
        var results = [LockerRoomLockboxMetadata]()
        
        do {
            let lockboxURLs = lockboxStore.allLockboxURLs()
            for lockboxURL in lockboxURLs {
                let lockboxName = lockboxURL.lastPathComponent
                let isEncrypted = lockboxStore.lockboxFileExists(name: lockboxName, fileType: .encryptedContentFileType) &&
                                  lockboxStore.lockboxFileExists(name: lockboxName, fileType: .encryptedSymmetricKeyFileType)
                let size: Int
                if isEncrypted {
                    size = lockboxStore.lockboxFileSize(name: lockboxName, fileType: .encryptedContentFileType)
                } else {
                    size = lockboxStore.lockboxFileSize(name: lockboxName, fileType: .unencryptedContentFileType)
                }
                
                let metadata = LockerRoomLockboxMetadata(name: lockboxName, size: size, url: lockboxURL, isEncrypted: isEncrypted)
                results.append(metadata)
            }
        }
        
        return results
    }
}
