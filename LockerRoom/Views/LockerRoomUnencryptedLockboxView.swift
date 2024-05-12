//
//  LockerRoomUnencryptedLockboxView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import SwiftUI

enum LockerRoomUnencryptedLockboxViewStyle {
    case create
    case creating
    case encrypt
    case encrypting
    case error
}

struct LockerRoomUnencryptedLockboxView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?

    @State var lockboxToBeNamed: String?
    @State var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    @State var error: LockerRoomError?
    
    var body: some View {
        VStack {
            switch viewStyle {
            case .create:
                LockerRoomUnencryptedLockboxCreateView(lockerRoomManager: lockerRoomManager, showView: $showView, lockboxToBeNamed: $lockboxToBeNamed, lockbox: $lockbox, error: $error, viewStyle: $viewStyle)
            case .creating:
                LockerRoomUnencryptedLockboxCreatingView(showView: $showView, lockboxToBeNamed: lockboxToBeNamed)
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

private struct LockerRoomUnencryptedLockboxCreateView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    @Binding var lockboxToBeNamed: String?
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
                .padding(.leading, 10)
                .textFieldStyle(.roundedBorder)
            
            Text("Size")
            HStack {
                TextField("", text: $unencryptedLockboxConfiguration.sizeString.deduplicatedBinding)
                    .onChange(of: unencryptedLockboxConfiguration.sizeString) { _, newSizeString in
                        let value = Int(newSizeString) ?? 0
                        unencryptedLockboxConfiguration.size = LockerRoomUnencryptedLockboxConfiguration.LockboxSize(unit: unencryptedLockboxConfiguration.unit, value: value)
                    }
                    .padding(.leading, 10)
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
            let createDisabled = (name.isEmpty || sizeInMegabytes <= 0 || sizeInMegabytes > LockerRoomUnencryptedLockboxConfiguration.maxSize)
            
            Button("Create") {
                lockboxToBeNamed = name
                viewStyle = .creating
                
                Task {
                    guard let newUnencryptedLockbox = await lockerRoomManager.addUnencryptedLockbox(name: name, size: sizeInMegabytes) else {
                        print("[Error] LockerRoom failed to create a new unencrypted lockbox \(name) of size \(sizeInMegabytes)MB")
                        error = .failedToCreateLockbox
                        viewStyle = .error
                        return
                    }
                    print("[Default] LockerRoom created a new unencrypted lockbox \(name) of size \(sizeInMegabytes)MB")
                    
                    lockbox = newUnencryptedLockbox.metadata.lockerRoomLockbox
                    viewStyle = .encrypt
                }
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
        .padding(.top)
    }
}

private struct LockerRoomUnencryptedLockboxCreatingView: View {
    @Binding var showView: Bool
    
    let lockboxToBeNamed: String?
    
    var body: some View {
        if let lockboxToBeNamed {
            Text("Creating '\(lockboxToBeNamed)'")
                .padding()
        } else {
            Text("Missing Lockbox Name to Create")
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

private struct LockerRoomUnencryptedLockboxEncryptView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?
    @Binding var error: LockerRoomError?
    @Binding var viewStyle: LockerRoomUnencryptedLockboxViewStyle
    
    @State var keySelection = false
    @State var selectedKeys = [LockerRoomEnrolledKey]()
    
    var body: some View {
        VStack() {
            VStack(spacing: -12) {
                Image(systemName: "lock.open")
                
                if let lockbox {
                    Text("Secure Lockbox '\(lockbox.name)'")
                        .bold()
                        .padding(.bottom, 2)
                        .padding(.top)
                } else {
                    Text("Missing Lockbox to Secure")
                        .padding()
                }
            }
        
            VStack {
                if keySelection {
                    LockerRoomUnencryptedLockboxEncryptKeySelectionView(lockerRoomManager: lockerRoomManager, selectedKeys: $selectedKeys)
                }
                
                if lockerRoomManager.enrolledKeysByID.count > 1 {
                    Button(action: {
                        withAnimation {
                            keySelection.toggle()
                        }
                    }) {
                        if keySelection {
                            Image(systemName: "chevron.up")
                            Text("Hide Key Selection")
                        } else {
                            Text("Show Key Selection")
                            Image(systemName: "chevron.down")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .padding(.bottom, 5)
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
                        
                        Task {
                            guard await lockerRoomManager.encrypt(lockbox: lockbox, usingEnrolledKeys: selectedKeys) else {
                                print("[Error] LockerRoom is failed to encrypt an unencrypted lockbox \(lockbox.name)")
                                error = .failedToEncryptLockbox
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

private struct LockerRoomUnencryptedLockboxEncryptKeySelectionView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    @Binding var selectedKeys: [LockerRoomEnrolledKey]
    
    @State private var selection: Set<LockerRoomEnrolledKey.ID> = Set()
    
    var enrolledKeys: [LockerRoomEnrolledKey] {
        return Array(lockerRoomManager.enrolledKeysByID.values).sorted(using: [KeyPathComparator(\LockerRoomEnrolledKey.name)])
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(enrolledKeys) { key in
                Text(key.name)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .cornerRadius(5)
            }
        }
        .background(Color.white)
        .frame(width: 200, height: 66)
        .onAppear() {
            selection = Set(selectedKeys.map { $0.id })
        }
        .onChange(of: selection) { oldValue, newValue in
            selectedKeys = selection.reduce(into: [LockerRoomEnrolledKey]()) { result, enrolledKeyID in
                if let enrolledKey = lockerRoomManager.enrolledKeysByID[enrolledKeyID] {
                    result.append(enrolledKey)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
    }
}

private struct LockerRoomUnencryptedLockboxEncryptingView: View {
    @Binding var showView: Bool
    @Binding var lockbox: LockerRoomLockbox?
    
    var body: some View {
        if let lockbox {
            Text("Encrypting '\(lockbox.name)'")
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
