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
            if viewStyle == .decrypt {
                LockerRoomEncryptedLockboxDecryptView(showView: $showView, encryptedLockbox: $encryptedLockbox, viewStyle: $viewStyle)
            } else if viewStyle == .waitingForKey {
                LockerRoomEncryptedLockboxWaitingForKeyView(showView: $showView, encryptedLockbox: $encryptedLockbox, viewStyle: $viewStyle)
            } else if viewStyle == .decrypting {
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
    
    @State var showLockImage = true
    
    let lockboxManager = LockboxManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: -12) {
                if showLockImage {
                    Image(systemName: "lock")
                } else {
                    Image(systemName: "lock.open")
                }
                
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
                    guard let encryptedLockbox else {
                        print("[Error] LockerRoom is missing an encrypted lockbox to decrypt")
                        return
                    }
                    
                    viewStyle = .waitingForKey
                    
                    Task {
                        let name = encryptedLockbox.name
                        
                        guard let encryptedSymmetricKey = encryptedLockbox.encryptedSymmetricKey else {
                            print("[Error] LockerRoom is missing an encrypted symmetric to decrypt")
                            return
                        }
                        
                        guard let symmetricKeyData = await LockboxKeyCryptor.decrypt(encryptedSymmetricKey:encryptedSymmetricKey) else {
                            print("[Error] LockerRoom failed to decrypt an encrypted symmetric key")
                            return
                        }
                        print("[Default] LockerRoom decrypted an encrypted symmetric key")
                        
                        viewStyle = .decrypting
                        
                        guard let content = LockboxCryptor.decrypt(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData) else {
                            print("[Error] LockerRoom failed to decrypt an encrypted lockbox \(name)")
                            return
                        }
                        print("[Default] LockerRoom decrypted an encrypted lockbox \(name)")
                        
                        // TODO: Encrypted lockbox is removed before unencrypted lockbox is added. Could lead to data loss.
                        guard lockboxManager.removeEncryptedLockbox(name: name) else {
                            print("[Error] LockerRoom failed to remove an encrypted lockbox \(name)")
                            return
                        }
                        print("[Default] LockerRoom removed an encrypted lockbox \(name)")
                        
                        guard lockboxManager.addUnencryptedLockbox(name: name, unencryptedContent: content) != nil else {
                            print("[Error] LockerRoom failed to add an unencrypted lockbox \(name) with content")
                            return
                        }
                        print("[Default] LockerRoom added an unencrypted lockbox \(name) with content")
                        
                        showLockImage = false
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
