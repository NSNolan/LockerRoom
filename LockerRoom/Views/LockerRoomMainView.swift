//
//  LockerRoomMainView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import SwiftUI

import os.log

enum LockerRoomMainViewStyle: String, CaseIterable, Identifiable {
    case lockboxes = "Lockboxes"
    case keys = "Keys"
    
    var id: String { self.rawValue }
}

struct LockerRoomMainView: View {
    @State var lockerRoomManager = LockerRoomManager.shared
    
    @State private var viewStyle: LockerRoomMainViewStyle = .lockboxes
    @State private var showErrorView = false
    @State var error: LockerRoomError? = nil

    var body: some View {
        VStack {
            switch viewStyle {
            case .lockboxes:
                LockerRoomLockboxesView(lockerRoomManager: lockerRoomManager, showErrorView: $showErrorView, error: $error)
            case .keys:
                LockerRoomKeysView(lockerRoomManager: lockerRoomManager)
            }
        }
        .toolbar {
            Picker("", selection: $viewStyle) {
                ForEach(LockerRoomMainViewStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
        }
        .sheet(isPresented: $showErrorView) {
            LockerRoomErrorView(showView: $showErrorView, error: $error)
        }
    }
}

private struct LockerRoomLockboxesView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showErrorView: Bool
    @Binding var error: LockerRoomError?
    
    @State private var lockboxesByUUID = [UUID:LockerRoomLockbox]()
    @State private var selection: LockerRoomLockbox.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\LockerRoomLockbox.name)]
    
    @State private var showUnencryptedLockboxAddView = false
    @State private var showUnencryptedLockboxView = false
    @State private var showEncryptedLockboxView = false
    
    @State private var selectedLockbox: LockerRoomLockbox? = nil
    
    var lockboxes: [LockerRoomLockbox] {
        return Array(lockboxesByUUID.values).sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack {
            Table(lockboxes, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name) { lockbox in
                    HStack {
                        if lockbox.isEncrypted {
                            Image(systemName: "lock")
                        } else {
                            Image(systemName: "lock.open")
                        }
                        
                        Text(lockbox.name)
                        
                        ForEach(lockbox.encryptionKeyNames, id: \.self) { keyName in
                            EncryptionKeyView(name: keyName)
                        }
                        
                        Spacer()
                    }
                }
            }
            .contextMenu(forSelectionType: LockerRoomLockbox.ID.self) { lockboxIDs in
                selectedLockboxContextMenu(fromIDs: lockboxIDs)
            } primaryAction: { lockboxIDs in
                openLockbox(fromIDs: lockboxIDs)
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    showUnencryptedLockboxAddView = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .padding()
        }
        .onAppear() {
            lockboxesByUUID = lockerRoomManager.lockboxesByID
        }
        .onChange(of: lockerRoomManager.lockboxesByID) {
            lockboxesByUUID = lockerRoomManager.lockboxesByID
        }
        .sheet(isPresented: $showUnencryptedLockboxAddView) {
            LockerRoomUnencryptedLockboxView(lockerRoomManager: lockerRoomManager, showView: $showUnencryptedLockboxAddView, lockbox: $selectedLockbox, viewStyle: .create)
        }
        .sheet(isPresented: $showUnencryptedLockboxView) {
            LockerRoomUnencryptedLockboxView(lockerRoomManager: lockerRoomManager, showView: $showUnencryptedLockboxView, lockbox: $selectedLockbox, viewStyle: .encrypt)
        }
        .sheet(isPresented: $showEncryptedLockboxView) {
            LockerRoomEncryptedLockboxView(lockerRoomManager: lockerRoomManager, showView: $showEncryptedLockboxView, lockbox: $selectedLockbox, viewStyle: .decrypt)
        }
    }
    
    @ViewBuilder
    private func selectedLockboxContextMenu(fromIDs lockboxIDs: Set<LockerRoomLockbox.ID>) -> some View {
        if let lockbox = selectedLockbox(fromIDs: lockboxIDs) {
            if !lockbox.isEncrypted {
                Button("Delete") {
                    let name = lockbox.name
                    _ = lockerRoomManager.detachFromDiskImage(name: name)
                    
                    guard lockerRoomManager.removeUnencryptedLockbox(name: name) else {
                        Logger.lockerRoomUI.error("LockerRoom failed to remove unencrypted lockbox \(name)")
                        error = .failedToRemoveLockbox
                        showErrorView = true
                        return
                    }
                }
            }
        }
    }
    
    private func openLockbox(fromIDs lockboxIDs: Set<LockerRoomLockbox.ID>) {
        if let lockbox = selectedLockbox(fromIDs: lockboxIDs) {
            selectedLockbox = lockbox
            
            if lockbox.isEncrypted {
                showEncryptedLockboxView = true
            } else {
                showUnencryptedLockboxView = true
            }
        }
    }
        
    private func selectedLockbox(fromIDs lockboxIDs: Set<LockerRoomLockbox.ID>) -> LockerRoomLockbox? {
        guard let lockboxID = lockboxIDs.first, let lockbox = lockerRoomManager.lockboxesByID[lockboxID] else {
            Logger.lockerRoomUI.error("LockerRoom failed to find selected lockbox")
            error = .failedToFindSelectedLockbox
            showErrorView = true
            return nil
        }
        return lockbox
    }
}

private struct LockerRoomKeysView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @State private var enrolledKeysByID = [UUID:LockerRoomEnrolledKey]()
    @State private var selection: LockerRoomEnrolledKey.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\LockerRoomEnrolledKey.name)]
    
    @State private var showLockboKeyAddView = false
    
    @State private var selectedLockboxKey: LockboxKey? = nil
    
    var enrolledKeys: [LockerRoomEnrolledKey] {
        return Array(enrolledKeysByID.values).sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack {
            Table(enrolledKeys, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name)
                TableColumn("Serial Number", value: \.serialNumber) { enrolledKey in
                    Text("\(String(enrolledKey.serialNumber))")
                }
                TableColumn("Slot", value: \.slot.rawValue)
                TableColumn("Algorithm", value: \.algorithm.rawValue)
                TableColumn("Pin Policy", value: \.pinPolicy.rawValue)
                TableColumn("Touch Policy", value: \.touchPolicy.rawValue)
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    showLockboKeyAddView = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .padding()
        }
        .onAppear() {
            enrolledKeysByID = lockerRoomManager.enrolledKeysByID
        }
        .onChange(of: lockerRoomManager.enrolledKeysByID) {
            enrolledKeysByID = lockerRoomManager.enrolledKeysByID
        }
        .sheet(isPresented: $showLockboKeyAddView) {
            LockerRoomLockboxKeyView(lockerRoomManager: lockerRoomManager, showView: $showLockboKeyAddView, viewStyle: .enroll)
        }
    }
}

private struct EncryptionKeyView: View {
    let name: String
    
    var body: some View {
        Text(name)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(
                HStack {
                    Capsule()
                        .fill(Color.gray)
                }
            )
            .foregroundColor(.white)
    }
}

#Preview {
    LockerRoomMainView()
}
