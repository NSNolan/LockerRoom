//
//  LockboxManager.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

class LockboxManager: ObservableObject {
    private let fileManager = FileManager.default
    
    internal let lockerRoomStore: LockerRoomStoring
    
    @Published var lockboxMetadatas = [LockerRoomLockboxMetadata]()
    
    static let shared = LockboxManager()
    
    private init(lockerRoomStore: LockerRoomStoring = LockerRoomStore.shared) {
        self.lockerRoomStore = lockerRoomStore
        self.lockboxMetadatas = updateLockboxMetadatas()
    }
    
    func addUnencryptedLockbox(name: String, size: Int) -> UnencryptedLockbox? {
        guard !lockerRoomStore.lockboxExists(name: name) else {
            print("[Error] Lockbox manager failed to add unencrypted lockbox \(name) to existing path")
            return nil
        } 
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, size: size, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Lockbox manager failed to add unencrypted lockbox \(name) to path")
            return nil
        }
        
        self.lockboxMetadatas = updateLockboxMetadatas()
        return unencryptedLockbox
    }
    
    func addUnencryptedLockbox(name: String, unencryptedContent: Data) -> UnencryptedLockbox? {
        guard !lockerRoomStore.lockboxExists(name: name) else {
            print("[Error] Lockbox manager failed to add unencrypted lockbox \(name) to existing path with existing data \(unencryptedContent)")
            return nil
        }
        
        guard let unencryptedLockbox = UnencryptedLockbox.create(name: name, unencryptedContent: unencryptedContent, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Lockbox manager failed to add unencrypted lockbox \(name) to path with existing data \(unencryptedContent)")
            return nil
        }
        
        self.lockboxMetadatas = updateLockboxMetadatas()
        return unencryptedLockbox
    }
    
    func addEncryptedLockbox(name: String, encryptedContent: Data, encryptedSymmetricKey: Data) -> EncryptedLockbox? {
        guard !lockerRoomStore.lockboxExists(name: name) else {
            print("[Error] Lockbox manager failed to add encrypted lockbox \(name) to existing path")
            return nil
        }

        guard let encryptedLockbox = EncryptedLockbox.create(name: name, encryptedContent: encryptedContent, encryptedSymmetricKey: encryptedSymmetricKey, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Lockbox manager failed to add encrypted lockbox \(name)")
            return nil
        }
        
        self.lockboxMetadatas = updateLockboxMetadatas()
        return encryptedLockbox
    }
    
    func removeUnencryptedLockbox(name: String) -> Bool {
        guard lockerRoomStore.lockboxExists(name: name) else {
            print("[Error] Lockbox manager failed to remove non-existing unencrypted lockbox \(name)")
            return false
        }
        
        guard UnencryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Lockbox manager failed to remove unencrypted lockbox \(name)")
            return false
        }
        
        self.lockboxMetadatas = updateLockboxMetadatas()
        return true
    }
    
    func removeEncryptedLockbox(name: String) -> Bool {
        guard lockerRoomStore.lockboxExists(name: name) else {
            print("[Error] Lockbox manager failed to remove encrypted non-existing lockbox \(name)")
            return false
        }
        
        guard EncryptedLockbox.destroy(name: name, lockerRoomStore: lockerRoomStore) else {
            print("[Error] Lockbox manager failed to remove encrypted lockbox \(name)")
            return false
        }
        
        self.lockboxMetadatas = updateLockboxMetadatas()
        return true
    }
    
    private func updateLockboxMetadatas() -> [LockerRoomLockboxMetadata] {
        var results = [LockerRoomLockboxMetadata]()
        
        do {
            let lockboxURLs = lockerRoomStore.allLockboxURLs()
            for lockboxURL in lockboxURLs {
                let lockboxName = lockboxURL.lastPathComponent
                let isEncrypted = lockerRoomStore.lockboxFileExists(name: lockboxName, fileType: .encryptedContentFileType) &&
                                  lockerRoomStore.lockboxFileExists(name: lockboxName, fileType: .encryptedSymmetricKeyFileType)
                let size: Int
                if isEncrypted {
                    size = lockerRoomStore.lockboxFileSize(name: lockboxName, fileType: .encryptedContentFileType)
                } else {
                    size = lockerRoomStore.lockboxFileSize(name: lockboxName, fileType: .unencryptedContentFileType)
                }
                
                let metadata = LockerRoomLockboxMetadata(name: lockboxName, size: size, url: lockboxURL, isEncrypted: isEncrypted)
                results.append(metadata)
            }
        }
        
        return results
    }
}
