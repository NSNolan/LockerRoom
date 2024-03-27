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
    case waitingForKey
}

class LockerRoomUnencryptedLockboxConfiguration: ObservableObject {
    @Published var name = ""
    @Published var size = 0
}

struct LockerRoomUnencryptedLockboxView: View {
    @Binding var showView: Bool
    @Binding var unencryptedLockbox: UnencryptedLockbox?

    @State var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    var body: some View {
        VStack {
            if viewStyle == .add {
                LockerRoomUnencryptedLockboxAddView(showView: $showView, unencryptedLockbox: $unencryptedLockbox, viewStyle: $viewStyle)
            } else if viewStyle == .encrypt {
                LockerRoomUnencryptedLockboxEncryptView(showView: $showView, unencryptedLockbox: $unencryptedLockbox, viewStyle: $viewStyle)
            } else if viewStyle == .waitingForKey {
                LockerRoomUnencryptedLockboxWaitingForKeyView(showView: $showView, unencryptedLockbox: $unencryptedLockbox, viewStyle: $viewStyle)
            } else if viewStyle == .encrypting {
                LockerRoomUnencryptedLockboxEncryptingView(showView: $showView, unencryptedLockbox: $unencryptedLockbox)
            }
        }
        .frame(width: 300)
        .padding()
    }
}

struct LockerRoomUnencryptedLockboxAddView: View {
    @Binding var showView: Bool
    @Binding var unencryptedLockbox: UnencryptedLockbox?
    @Binding var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    @ObservedObject var unencryptedLockboxConfiguration: LockerRoomUnencryptedLockboxConfiguration = LockerRoomUnencryptedLockboxConfiguration()
    
    let lockboxManager = LockboxManager.shared
    
    var body: some View {
        Text("Create a new Lockbox")
            .padding()
        
        VStack {
            HStack {
                Text("Name")
                Spacer()
            }
            TextField("Name", text: $unencryptedLockboxConfiguration.name)
        }
        .padding()
        
        VStack {
            HStack {
                Text("Size (MB)")
                Spacer()
            }
            TextField("Size (MB)", value: $unencryptedLockboxConfiguration.size, format: .number)
        }
        .padding()
        
        HStack {
            Spacer()
            
            Button("Add") {
                let name = unencryptedLockboxConfiguration.name
                guard !name.isEmpty else {
                    print("[Error] LockerRoom cannot add a new decrypted lockbox \(name)")
                    showView = false
                    return
                }
                
                let size = unencryptedLockboxConfiguration.size
                guard size > 0 else {
                    print("[Error] LockerRoom cannot add a new decrypted lockbox \(name) of size \(size)MB")
                    showView = false
                    return
                }
                
                guard let unencryptedLockbox = lockboxManager.addUnencryptedLockbox(name: name, size: size) else { // TODO: Maybe revert to assignment
                    print("[Error] LockerRoom failed to create a new unencrypted lockbox \(name) of size \(size)MB")
                    showView = false
                    return
                }
                print("[Default] LockerRoom created a new unencrypted lockbox \(name) of size \(size)MB")
                self.unencryptedLockbox = unencryptedLockbox
                viewStyle = .encrypt
            }
            .buttonStyle(.borderedProminent) // Customizable style
            .tint(.blue)
                        
            Button("Close") {
                showView = false
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding()
    }
}

struct LockerRoomUnencryptedLockboxEncryptView: View {
    @Binding var showView: Bool
    @Binding var unencryptedLockbox: UnencryptedLockbox?
    @Binding var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    let lockboxManager = LockboxManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: -12) {
                Image(systemName: "lock.open")
                
                if let unencryptedLockbox {
                    Text("Secure Lockbox \(unencryptedLockbox.name)")
                        .padding()
                } else {
                    Text("Missing Lockbox to Secure")
                        .padding()
                }
            }
        
            HStack {
                Button("Encrypt") {
                    viewStyle = .waitingForKey
                    Task {
                        await encrypt()
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
        .onAppear() {
            if let unencryptedLockbox {
                _ = unencryptedLockbox.attachDiskImage()
            }
        }
    }
    
    private func encrypt() async {
        guard let unencryptedLockbox else {
            print("[Error] LockerRoom is missing an unencrypted lockbox to encrypt")
            return
        }
        
        let name = unencryptedLockbox.name
        let symmetricKeyData = LockboxCryptor.generateSymmetricKeyData()
        
        guard let encryptedSymmetricKeyData = await LockboxKeyCryptor.encrypt(symmetricKey: symmetricKeyData) else {
            print("[Error] LockerRoom failed to encrypt an unencrypted symmetric key")
            return
        }
        print("[Default] LockerRoom encrypted an unencrypted symmetric key")
        
        DispatchQueue.main.async {
            viewStyle = .encrypting
            
            guard let encryptedContent = LockboxCryptor.encrypt(lockbox: unencryptedLockbox, symmetricKeyData: symmetricKeyData) else {
                print("[Error] LockerRoom failed to encrypt an unencrypted lockbox \(name)")
                return
            }
            print("[Default] LockerRoom encrypted an unencrypted lockbox \(name)")
            
            // TODO: Unencrypted lockbox is removed before encrypted lockbox is added. Could lead to data loss.
            guard lockboxManager.removeUnencryptedLockbox(name: name) else {
                print("[Error] LockerRoom failed to removed an unencrypted lockbox \(name)")
                return
            }
            print("[Default] LockerRoom removed an unencrypted lockbox \(name)")
            
            guard lockboxManager.addEncryptedLockbox(name: name, encryptedContent: encryptedContent, encryptedSymmetricKey: encryptedSymmetricKeyData) != nil else {
                print("[Error] LockerRoom failed to add an encrypted lockbox \(name)")
                return
            }
            print("[Default] LockerRoom added an encrypted lockbox \(name)")
        }
    }
}

struct LockerRoomUnencryptedLockboxWaitingForKeyView: View {
    @Binding var showView: Bool
    @Binding var unencryptedLockbox: UnencryptedLockbox?
    @Binding var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    var body: some View {
        if let unencryptedLockbox {
            Text("Insert YubiKit to Encrypt \(unencryptedLockbox.name)")
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

struct LockerRoomUnencryptedLockboxEncryptingView: View {
    @Binding var showView: Bool
    @Binding var unencryptedLockbox: UnencryptedLockbox?
    
    var body: some View {
        if let unencryptedLockbox {
            Text("Encrypting \(unencryptedLockbox.name)")
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
