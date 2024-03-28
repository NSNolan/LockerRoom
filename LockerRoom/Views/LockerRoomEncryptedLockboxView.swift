//
//  LockerRoomEncryptLockboxView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/24/24.
//

import SwiftUI

enum LockerRoomEncryptedLockboxViewStyle {
    case decrypt
    case waitingForKey
    case decrypting
}

struct LockerRoomEncryptedLockboxView: View {
    @Binding var showView: Bool
    @Binding var encryptedLockbox: EncryptedLockbox?
    
    @State var viewStyle: LockerRoomEncryptedLockboxViewStyle
            
    var body: some View {
        VStack {
            switch viewStyle {
            case .decrypt:
                LockerRoomEncryptedLockboxDecryptView(showView: $showView, encryptedLockbox: $encryptedLockbox, viewStyle: $viewStyle)
            case .waitingForKey:
                LockerRoomEncryptedLockboxWaitingForKeyView(showView: $showView, encryptedLockbox: $encryptedLockbox, viewStyle: $viewStyle)
            case .decrypting:
                LockerRoomEncryptedLockboxDecryptingView(showView: $showView, encryptedLockbox: $encryptedLockbox)
            }
        }
        .frame(width: 300)
        .padding()
    }
}

struct LockerRoomEncryptedLockboxDecryptView: View {
    @Binding var showView: Bool
    @Binding var encryptedLockbox: EncryptedLockbox?
    @Binding var viewStyle: LockerRoomEncryptedLockboxViewStyle
    
    let lockboxManager = LockboxManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: -12) {
                Image(systemName: "lock")
                
                if let encryptedLockbox {
                    Text("Open Lockbox \(encryptedLockbox.name)")
                        .padding()
                } else {
                    Text("Missing Lockbox to Open")
                        .padding()
                }
            }
            
            HStack {
                Button("Decrypt") {
                    viewStyle = .waitingForKey
                    Task {
                        await decrypt()
                        showView = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button("Later") {
                    showView = false
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
    }
    
    private func decrypt() async {
        guard let encryptedLockbox else {
            print("[Error] LockerRoom is missing an encrypted lockbox to decrypt")
            return
        }
        
        let name = encryptedLockbox.name
        let encryptedSymmetricKey = encryptedLockbox.encryptedSymmetricKey
        
        guard !encryptedSymmetricKey.isEmpty else {
            print("[Error] LockerRoom is missing an encrypted symmetric to decrypt")
            return
        }
        
        guard let symmetricKeyData = await LockboxKeyCryptor.decrypt(encryptedSymmetricKey:encryptedSymmetricKey) else {
            print("[Error] LockerRoom failed to decrypt an encrypted symmetric key")
            return
        }
        print("[Default] LockerRoom decrypted an encrypted symmetric key")
        
        DispatchQueue.main.async {
            viewStyle = .decrypting
            
            guard let content = LockboxCryptor.decrypt(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData) else {
                print("[Error] LockerRoom failed to decrypt an encrypted lockbox \(name)")
                return
            }
            print("[Default] LockerRoom decrypted an encrypted lockbox \(name)")
            
            guard lockboxManager.removeEncryptedLockbox(name: name) else { // TODO: Encrypted lockbox is removed before unencrypted lockbox is added. May cause data loss.
                print("[Error] LockerRoom failed to remove an encrypted lockbox \(name)")
                return
            }
            print("[Default] LockerRoom removed an encrypted lockbox \(name)")
            
            guard lockboxManager.addUnencryptedLockbox(name: name, unencryptedContent: content) != nil else {
                print("[Error] LockerRoom failed to add an unencrypted lockbox \(name) with content")
                return
            }
            print("[Default] LockerRoom added an unencrypted lockbox \(name) with content")
        }
    }
}

struct LockerRoomEncryptedLockboxWaitingForKeyView: View {
    @Binding var showView: Bool
    @Binding var encryptedLockbox: EncryptedLockbox?
    @Binding var viewStyle: LockerRoomEncryptedLockboxViewStyle
    
    var body: some View {
        if let encryptedLockbox {
            Text("Insert YubiKit to Decrypt \(encryptedLockbox.name)")
                .padding()
        } else {
            Text("Missing Lockbox to Decrypt")
                .padding()
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

struct LockerRoomEncryptedLockboxDecryptingView: View {
    @Binding var showView: Bool
    @Binding var encryptedLockbox: EncryptedLockbox?
    
    var body: some View {
        if let encryptedLockbox {
            Text("Decrypting \(encryptedLockbox.name)")
                .padding()
        } else {
            Text("Missing Lockbox to Decrypt")
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
