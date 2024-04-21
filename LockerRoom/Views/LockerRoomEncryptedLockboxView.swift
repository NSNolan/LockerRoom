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

private struct LockerRoomEncryptedLockboxDecryptView: View {
    @Binding var showView: Bool
    @Binding var encryptedLockbox: EncryptedLockbox?
    @Binding var viewStyle: LockerRoomEncryptedLockboxViewStyle
    
    let lockerRoomManager = LockerRoomManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: -12) {
                Image(systemName: "lock")
                
                if let encryptedLockbox {
                    Text("Open Lockbox \(encryptedLockbox.metadata.name)")
                        .padding()
                } else {
                    Text("Missing Lockbox to Open")
                        .padding()
                }
            }
            
            HStack {
                Button("Decrypt") {
                    viewStyle = .waitingForKey
                    
                    guard let encryptedLockbox else {
                        print("[Error] LockerRoom is missing an encrypted lockbox to decrypt")
                        showView = false
                        return
                    }
                    
                    Task {
                        guard let symmetricKeyData = await lockerRoomManager.decryptKey(forLockbox: encryptedLockbox) else {
                            print("[Error] LockerRoom failed to decrypt lockbox symmetric key")
                            showView = false
                            return
                        }
                        
                        viewStyle = .decrypting
                        lockerRoomManager.decrypt(lockbox: encryptedLockbox, symmetricKeyData: symmetricKeyData)
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
}

private struct LockerRoomEncryptedLockboxWaitingForKeyView: View {
    @Binding var showView: Bool
    @Binding var encryptedLockbox: EncryptedLockbox?
    @Binding var viewStyle: LockerRoomEncryptedLockboxViewStyle
    
    var body: some View {
        if let encryptedLockbox {
            Text("Insert YubiKit to Decrypt \(encryptedLockbox.metadata.name)")
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

private struct LockerRoomEncryptedLockboxDecryptingView: View {
    @Binding var showView: Bool
    @Binding var encryptedLockbox: EncryptedLockbox?
    
    var body: some View {
        if let encryptedLockbox {
            Text("Decrypting \(encryptedLockbox.metadata.name)")
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
