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
    @Binding var lockbox: LockerRoomLockbox?
    
    @State var viewStyle: LockerRoomEncryptedLockboxViewStyle
            
    var body: some View {
        VStack {
            switch viewStyle {
            case .decrypt:
                LockerRoomEncryptedLockboxDecryptView(showView: $showView, lockbox: $lockbox, viewStyle: $viewStyle)
            case .waitingForKey:
                LockerRoomEncryptedLockboxWaitingForKeyView(showView: $showView, lockbox: $lockbox)
            case .decrypting:
                LockerRoomEncryptedLockboxDecryptingView(showView: $showView, lockbox: $lockbox)
            }
        }
        .frame(width: 300)
        .padding()
    }
}

private struct LockerRoomEncryptedLockboxDecryptView: View {
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?
    @Binding var viewStyle: LockerRoomEncryptedLockboxViewStyle
    
    let lockerRoomManager = LockerRoomManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: -12) {
                Image(systemName: "lock")
                
                if let lockbox {
                    Text("Open Lockbox \(lockbox.name)")
                        .padding()
                } else {
                    Text("Missing Lockbox to Open")
                        .padding()
                }
            }
            
            HStack {
                Button("Decrypt") {
                    viewStyle = .waitingForKey
                    
                    guard let lockbox else {
                        print("[Error] LockerRoom is missing an encrypted lockbox to decrypt")
                        showView = false
                        return
                    }
                    
                    Task {
                        let name = lockbox.name
                        
                        guard let symmetricKeyData = await lockerRoomManager.decryptKey(forLockbox: lockbox) else {
                            print("[Error] LockerRoom failed to decrypt lockbox symmetric key for encrypted lockbox \(name)")
                            showView = false
                            return
                        }
                        
                        viewStyle = .decrypting
                        
                        guard lockerRoomManager.decrypt(lockbox: lockbox, symmetricKeyData: symmetricKeyData) else {
                            print("[Error] LockerRoom is failed to decrypt an encrypted lockbox \(name)")
                            showView = false
                            return
                        }
                        
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
    @Binding var lockbox: LockerRoomLockbox?
    
    var body: some View {
        if let lockbox {
            Text("Insert YubiKit to Decrypt \(lockbox.name)")
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
    @Binding var lockbox: LockerRoomLockbox?
    
    var body: some View {
        if let lockbox {
            Text("Decrypting \(lockbox.name)")
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
