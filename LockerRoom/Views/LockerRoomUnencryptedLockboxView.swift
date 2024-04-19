//
//  LockerRoomUnencryptedLockboxView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import SwiftUI

enum LockerRoomUnencryptedLockboxViewStyle {
    case add
    case encrypt
    case encrypting
}

private class LockerRoomUnencryptedLockboxConfiguration: ObservableObject {
    @Published var name = ""
    @Published var size = 0
}

struct LockerRoomUnencryptedLockboxView: View {
    @Binding var showView: Bool
    @Binding var unencryptedLockbox: UnencryptedLockbox?

    @State var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    var body: some View {
        VStack {
            switch viewStyle {
            case .add:
                LockerRoomUnencryptedLockboxAddView(showView: $showView, unencryptedLockbox: $unencryptedLockbox, viewStyle: $viewStyle)
            case .encrypt:
                LockerRoomUnencryptedLockboxEncryptView(showView: $showView, unencryptedLockbox: $unencryptedLockbox, viewStyle: $viewStyle)
            case .encrypting:
                LockerRoomUnencryptedLockboxEncryptingView(showView: $showView, unencryptedLockbox: $unencryptedLockbox)
            }
        }
        .frame(width: 300)
        .padding()
    }
}

private struct LockerRoomUnencryptedLockboxAddView: View {
    @Binding var showView: Bool
    @Binding var unencryptedLockbox: UnencryptedLockbox?
    @Binding var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    @StateObject var unencryptedLockboxConfiguration = LockerRoomUnencryptedLockboxConfiguration()
    
    let lockerRoomManager = LockerRoomManager.shared
    
    var body: some View {
        Text("Create a New Lockbox")
            .padding()
        
        VStack {
            HStack {
                Text("Name")
                Spacer()
            }
            TextField("", text: $unencryptedLockboxConfiguration.name)
        }
        .padding()
        
        VStack {
            HStack {
                Text("Size (MB)")
                Spacer()
            }
            TextField("", value: $unencryptedLockboxConfiguration.size, format: .number)
        }
        .padding()
        
        HStack {
            Spacer()
            
            Button("Add") {
                let name = unencryptedLockboxConfiguration.name
                guard !name.isEmpty else {
                    print("[Error] LockerRoom cannot add a new decrypted lockbox with missing name")
                    showView = false
                    return
                }
                
                let size = unencryptedLockboxConfiguration.size
                guard size > 0 else {
                    print("[Error] LockerRoom cannot add a new decrypted lockbox \(name) of size \(size)MB")
                    showView = false
                    return
                }
                
                guard let unencryptedLockbox = lockerRoomManager.addUnencryptedLockbox(name: name, size: size) else {
                    print("[Error] LockerRoom failed to create a new unencrypted lockbox \(name) of size \(size)MB")
                    showView = false
                    return
                }
                print("[Default] LockerRoom created a new unencrypted lockbox \(name) of size \(size)MB")
                self.unencryptedLockbox = unencryptedLockbox
                viewStyle = .encrypt
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .tint(.blue)
                        
            Button("Close") {
                showView = false
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape)
        }
        .padding()
    }
}

private struct LockerRoomUnencryptedLockboxEncryptView: View {
    @Binding var showView: Bool
    @Binding var unencryptedLockbox: UnencryptedLockbox?
    @Binding var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    let lockerRoomManager = LockerRoomManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: -12) {
                Image(systemName: "lock.open")
                
                if let unencryptedLockbox {
                    Text("Secure Lockbox \(unencryptedLockbox.metadata.name)")
                        .padding()
                } else {
                    Text("Missing Lockbox to Secure")
                        .padding()
                }
            }
        
            HStack {
                Button("Encrypt") {
                    viewStyle = .encrypting
                    Task {
                        encrypt()
                        showView = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .tint(.blue)
                
                Button("Later") {
                    showView = false
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)
            }
        }
    }
    
    private func encrypt() {
        guard let unencryptedLockbox else {
            print("[Error] LockerRoom is missing an unencrypted lockbox to encrypt")
            return
        }
        
        let symmetricKeyData = LockboxKeyGenerator.generateSymmetricKeyData()
        
        var encryptedSymmetricKeysBySerialNumber = [UInt32:Data]()
        var encryptionLockboxKeys = [LockboxKey]()
        
        for lockboxKey in lockerRoomManager.lockboxKeys {
            guard let encryptedSymmetricKeyData = LockboxKeyCryptor.encrypt(symmetricKeyData: symmetricKeyData, lockboxKey: lockboxKey) else {
                print("[Error] LockerRoom failed to encrypt a symmetric key with lockbox key \(lockboxKey.name)")
                continue
            }
            encryptedSymmetricKeysBySerialNumber[lockboxKey.serialNumber] = encryptedSymmetricKeyData
            encryptionLockboxKeys.append(lockboxKey)
        }
        
        guard !encryptedSymmetricKeysBySerialNumber.isEmpty else {
            print("[Error] LockerRoom failed to encrypt a symmetric key")
            return
        }
        
        print("[Default] LockerRoom encrypted a symmetric key")
        
        let name = unencryptedLockbox.metadata.name
        
        guard let encryptedContent = LockboxCryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
            print("[Error] LockerRoom failed to encrypt an unencrypted lockbox \(name)")
            return
        }
        print("[Default] LockerRoom encrypted an unencrypted lockbox \(name)")
        
        guard lockerRoomManager.removeUnencryptedLockbox(name: name) else { // TODO: Unencrypted lockbox is removed before encrypted lockbox is added. May cause data loss.
            print("[Error] LockerRoom failed to removed an unencrypted lockbox \(name)")
            return
        }
        print("[Default] LockerRoom removed an unencrypted lockbox \(name)")
        
        guard lockerRoomManager.addEncryptedLockbox(name: name, size: unencryptedLockbox.metadata.size, encryptedContent: encryptedContent, encryptedSymmetricKeysBySerialNumber: encryptedSymmetricKeysBySerialNumber, encryptionLockboxKeys: encryptionLockboxKeys) != nil else {
            print("[Error] LockerRoom failed to add an encrypted lockbox \(name)")
            return
        }
        print("[Default] LockerRoom added an encrypted lockbox \(name)")
    }
}

private struct LockerRoomUnencryptedLockboxEncryptingView: View {
    @Binding var showView: Bool
    @Binding var unencryptedLockbox: UnencryptedLockbox?
    
    var body: some View {
        if let unencryptedLockbox {
            Text("Encrypting \(unencryptedLockbox.metadata.name)")
                .padding()
        } else {
            Text("Missing Lockbox to Encrypt")
        }
        
        Spacer()
        
        ProgressView().progressViewStyle(CircularProgressViewStyle())
        
        Spacer()
        
        Button("Close") {
            showView = false
        }
        .padding()
    }
}
