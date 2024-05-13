//
//  LockerRoomEncryptLockboxView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/24/24.
//

import SwiftUI

import os.log

enum LockerRoomEncryptedLockboxViewStyle {
    case decrypt
    case waitingForKey
    case decrypting
    case error
}

struct LockerRoomEncryptedLockboxView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?
    
    @State var viewStyle: LockerRoomEncryptedLockboxViewStyle
    @State var error: LockerRoomError? = nil
            
    var body: some View {
        VStack {
            switch viewStyle {
            case .decrypt:
                LockerRoomEncryptedLockboxDecryptView(lockerRoomManager: lockerRoomManager, showView: $showView, lockbox: $lockbox, error: $error, viewStyle: $viewStyle)
            case .waitingForKey:
                LockerRoomEncryptedLockboxWaitingForKeyView(showView: $showView, lockbox: $lockbox)
            case .decrypting:
                LockerRoomEncryptedLockboxDecryptingView(showView: $showView, lockbox: $lockbox)
            case .error:
                LockerRoomErrorView(showView: $showView, error: $error)
            }
        }
        .frame(width: 300)
        .padding()
    }
}

private struct LockerRoomEncryptedLockboxDecryptView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?
    @Binding var error: LockerRoomError?
    @Binding var viewStyle: LockerRoomEncryptedLockboxViewStyle
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: -12) {
                Image(systemName: "lock")
                
                if let lockbox {
                    Text("Open Lockbox '\(lockbox.name)'")
                        .bold()
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
                        Logger.lockerRoomUI.error("LockerRoom is missing an encrypted lockbox to decrypt")
                        error = .missingLockbox
                        viewStyle = .error
                        return
                    }
                    
                    Task {
                        let name = lockbox.name
                        
                        guard let symmetricKeyData = await lockerRoomManager.decryptKey(forLockbox: lockbox) else {
                            Logger.lockerRoomUI.error("LockerRoom failed to decrypt lockbox symmetric key for encrypted lockbox \(name)")
                            error = .failedToDecryptLockboxSymmetricKey
                            viewStyle = .error
                            return
                        }
                        
                        viewStyle = .decrypting
                        
                        guard await lockerRoomManager.decrypt(lockbox: lockbox, symmetricKeyData: symmetricKeyData) else {
                            Logger.lockerRoomUI.error("LockerRoom failed to decrypt an encrypted lockbox \(name)")
                            error = .failedToDecryptLockbox
                            viewStyle = .error
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
            Text("Insert Key to Decrypt '\(lockbox.name)'")
                .padding()
        } else {
            Text("Missing Lockbox to Decrypt")
                .padding()
        }
        
        Spacer()
        
        ProgressView().progressViewStyle(.circular)
        
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
            Text("Decrypting '\(lockbox.name)'")
                .padding()
        } else {
            Text("Missing Lockbox to Decrypt")
        }
        
        Spacer()
        
        ProgressView().progressViewStyle(.circular)
        
        Spacer()
        
        Button("Close") {
            showView = false
        }
        .padding()
    }
}
