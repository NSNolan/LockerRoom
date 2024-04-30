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
    case error
}

struct LockerRoomUnencryptedLockboxView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?

    @State var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    @State var error: LockerRoomError? = nil
    
    var body: some View {
        VStack {
            switch viewStyle {
            case .add:
                LockerRoomUnencryptedLockboxAddView(lockerRoomManager: lockerRoomManager, showView: $showView, lockbox: $lockbox, error: $error, viewStyle: $viewStyle)
            case .encrypt:
                LockerRoomUnencryptedLockboxEncryptView(lockerRoomManager: lockerRoomManager, showView: $showView, lockbox: $lockbox, error: $error, viewStyle: $viewStyle)
            case .encrypting:
                LockerRoomUnencryptedLockboxEncryptingView(showView: $showView, lockbox: $lockbox)
            case .error:
                LockerRoomErrorView(showView: $showView, error: $error)
            }
        }
        .frame(width: 300)
        .padding()
    }
}

private struct LockerRoomUnencryptedLockboxAddView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?
    @Binding var error: LockerRoomError?
    @Binding var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    @State var unencryptedLockboxConfiguration = LockerRoomUnencryptedLockboxConfiguration()
    
    var body: some View {
        Text("Create a New Lockbox")
            .bold()
            .padding()
        
        VStack(alignment: .leading) {
            Text("Name")
            TextField("", text: $unencryptedLockboxConfiguration.name.deduplicatedBinding)
                .padding(.bottom)
                .textFieldStyle(.roundedBorder)
            
            Text("Size")
            HStack {
                TextField("", text: $unencryptedLockboxConfiguration.sizeString.deduplicatedBinding)
                    .onChange(of: unencryptedLockboxConfiguration.sizeString) { _, newSizeString in
                        let value = Int(newSizeString) ?? 0
                        unencryptedLockboxConfiguration.size = LockerRoomUnencryptedLockboxConfiguration.LockboxSize(unit: unencryptedLockboxConfiguration.unit, value: value)
                    }
                    .textFieldStyle(.roundedBorder)
                Picker("", selection: $unencryptedLockboxConfiguration.unit) {
                    ForEach(LockerRoomUnencryptedLockboxConfiguration.LockboxUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .onChange(of: unencryptedLockboxConfiguration.unit) { _, newUnit in
                    let value = Int(unencryptedLockboxConfiguration.sizeString) ?? 0
                    unencryptedLockboxConfiguration.size = LockerRoomUnencryptedLockboxConfiguration.LockboxSize(unit: newUnit, value: value)
                }
                .pickerStyle(.menu)
            }
        }
        
        HStack {
            Spacer()
            
            let name = unencryptedLockboxConfiguration.name
            let sizeInMegabytes = unencryptedLockboxConfiguration.size.megabytes
            let createDisabled = (name.isEmpty || sizeInMegabytes <= 0)
            
            Button("Create") {
                
                guard let newUnencryptedLockbox = lockerRoomManager.addUnencryptedLockbox(name: name, size: sizeInMegabytes) else {
                    print("[Error] LockerRoom failed to create a new unencrypted lockbox \(name) of size \(sizeInMegabytes)MB")
                    error = .failedToCreateLockbox
                    viewStyle = .error
                    return
                }
                print("[Default] LockerRoom created a new unencrypted lockbox \(name) of size \(sizeInMegabytes)MB")
                
                self.lockbox = newUnencryptedLockbox.metadata.lockerRoomLockbox
                viewStyle = .encrypt
            }
            .disabled(createDisabled)
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .tint(.blue)
                        
            Button("Close") {
                showView = false
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape)
        }
        .padding([.top, .bottom])
    }
}

private struct LockerRoomUnencryptedLockboxEncryptView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?
    @Binding var error: LockerRoomError?
    @Binding var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: -12) {
                Image(systemName: "lock.open")
                
                if let lockbox {
                    Text("Secure Lockbox \(lockbox.name)")
                        .bold()
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
                        error = .missingLockbox
                        viewStyle = .error
                        return
                    }
                    
                    guard lockerRoomManager.encrypt(lockbox: lockbox) else {
                        print("[Error] LockerRoom is failed to encrypt an unencrypted lockbox \(lockbox.name)")
                        error = .failedToEncryptLockbox
                        viewStyle = .error
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
            guard let lockbox else {
                print("[Error] LockerRoom is missing an unencrypted lockbox to attach as disk image")
                error = .missingLockbox
                viewStyle = .error
                return
            }
            
            let name = lockbox.name
            guard lockerRoomManager.attachToDiskImage(name: name) else {
                print("[Error] LockerRoom failed to attach lockbox \(name) as disk image")
                error = .failedToAttachLockbox
                viewStyle = .error
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
        
        ProgressView().progressViewStyle(.circular)
        
        Spacer()
        
        Button("Close") {
            showView = false
        }
        .padding()
    }
}
