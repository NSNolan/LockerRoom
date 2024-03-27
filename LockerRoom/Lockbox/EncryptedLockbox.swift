//
//  EncryptedLockbox.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

class EncryptedLockbox {
    let name: String
    
    internal let lockboxStore: LockboxStoring
    
    init(name: String, lockboxStore: LockboxStoring) {
        self.name = name
        self.lockboxStore = lockboxStore
    }
    
    func create(encryptedContent: Data, encryptedSymmetricKey: Data) -> Bool {
        self.encryptedContent = encryptedContent
        if self.encryptedContent == encryptedContent { // TODO: this seems a wee bit inefficient
            self.encryptedSymmetricKey = encryptedSymmetricKey
            if self.encryptedSymmetricKey == encryptedSymmetricKey {
                return true
            } else {
                print("[Error] Encrypted lockbox failed to persist \(name)")
                _ = destroy()
                return false
            }
        } else {
            print("[Error] Encrypted lockbox failed to persist \(name)")
            _ = destroy()
            return false
        }
    }
    
    func destroy() -> Bool {
        self.encryptedContent = nil
        self.encryptedSymmetricKey = nil
        guard self.lockboxStore.removeLockbox(name: name) else {
            print("[Error] Encrypted lockbox failed to remove \(name)")
            return false
        }
        return true
    }
    
    private(set) var encryptedContent: Data? {
        get {
            guard let data = lockboxStore.readFromLockbox(name: name, fileType: .encryptedContentFileType) else {
                print("[Error] Encrypted lockbox failed to read encrypted content for \(name)")
                return nil
            }
            return data
        }
        set(newEncryptedContent) {
            guard lockboxStore.writeToLockbox(data: newEncryptedContent, name: name, fileType: .encryptedContentFileType) else {
                print("[Error] Encrypted lockbox failed to write encrypted content for \(name)")
                return
            }
        }
    }
    
    private(set) var encryptedSymmetricKey: Data? {
        get {
            guard let data = lockboxStore.readFromLockbox(name: name, fileType: .encryptedSymmetricKeyFileType) else {
                print("[Error] Encrypted lockbox failed to read encrypted symmetric key for \(name)")
                return nil
            }
            return data
        }
        set(newEncryptedSymmetricKey) {
            guard lockboxStore.writeToLockbox(data: newEncryptedSymmetricKey, name: name, fileType: .encryptedSymmetricKeyFileType) else {
                print("[Error] Encrypted lockbox failed to write encrypted symmetric key for \(name)")
                return
            }
        }
    }
}
