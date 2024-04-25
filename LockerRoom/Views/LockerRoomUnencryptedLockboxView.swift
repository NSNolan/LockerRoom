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
    @Binding var lockbox: LockerRoomLockbox?

    @State var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    var body: some View {
        VStack {
            switch viewStyle {
            case .add:
                LockerRoomUnencryptedLockboxAddView(showView: $showView, lockbox: $lockbox, viewStyle: $viewStyle)
            case .encrypt:
                LockerRoomUnencryptedLockboxEncryptView(showView: $showView, lockbox: $lockbox, viewStyle: $viewStyle)
            case .encrypting:
                LockerRoomUnencryptedLockboxEncryptingView(showView: $showView, lockbox: $lockbox)
            }
        }
        .frame(width: 300)
        .padding()
    }
}

private struct LockerRoomUnencryptedLockboxAddView: View {
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?
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
                
                guard let newUnencryptedLockbox = lockerRoomManager.addUnencryptedLockbox(name: name, size: size) else {
                    print("[Error] LockerRoom failed to create a new unencrypted lockbox \(name) of size \(size)MB")
                    showView = false
                    return
                }
                print("[Default] LockerRoom created a new unencrypted lockbox \(name) of size \(size)MB")
                
                self.lockbox = newUnencryptedLockbox.metadata.lockerRoomLockbox
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
    @Binding var lockbox: LockerRoomLockbox?
    @Binding var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    let lockerRoomManager = LockerRoomManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: -12) {
                Image(systemName: "lock.open")
                
                if let lockbox {
                    Text("Secure Lockbox \(lockbox.name)")
                        .padding()
                } else {
                    Text("Missing Lockbox to Secure")
                        .padding()
                }
            }
        
            HStack {
                Button("Encrypt") {
                    viewStyle = .encrypting
                    
                    guard let lockbox else {
                        print("[Error] LockerRoom is missing an unencrypted lockbox to encrypt")
                        showView = false
                        return
                    }
                    
                    guard lockerRoomManager.encrypt(lockbox: lockbox) else {
                        print("[Error] LockerRoom is failed to encrypt an unencrypted lockbox")
                        showView = false
                        return
                    }
                    
                    showView = false
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
        .onAppear {
            guard let name = lockbox?.name else {
                print("[Error] LockerRoom is missing an lockbox to attach as disk image")
                return
            }
            
            guard LockerRoomDiskImage().attach(name: name) else {
                print("[Error] LockerRoom failed to attach lockbox \(name) as disk image")
                return
            }
        }
    }
}

private struct LockerRoomUnencryptedLockboxEncryptingView: View {
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?
    
    var body: some View {
        if let lockbox {
            Text("Encrypting \(lockbox.name)")
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
