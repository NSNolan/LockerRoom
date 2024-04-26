//
//  LockerRoomMainView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import SwiftUI

enum LockerRoomMainViewStyle: String, CaseIterable, Identifiable {
    case lockboxes = "Lockboxes"
    case keys = "Keys"
    
    var id: String { self.rawValue }
}

struct LockerRoomMainView: View {
    @State private var viewStyle: LockerRoomMainViewStyle = .lockboxes
    
    @StateObject var lockerRoomManager = LockerRoomManager.shared

    var body: some View {
        VStack {
            switch viewStyle {
            case .lockboxes:
                LockerRoomLockboxesView(lockerRoomManager: lockerRoomManager)
            case .keys:
                LockerRoomKeysView(lockerRoomManager: lockerRoomManager)
            }
        }
        .toolbar {
            Picker("", selection: $viewStyle) {
                ForEach(LockerRoomMainViewStyle.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
        }
    }
}

private struct LockerRoomLockboxesView: View {
    @ObservedObject var lockerRoomManager: LockerRoomManager
    
    @State private var lockboxes = [LockerRoomLockbox]()
    @State private var selection: LockerRoomLockbox.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\LockerRoomLockbox.name)]
    
    @State private var showUnencryptedLockboxAddView = false
    @State private var showUnencryptedLockboxView = false
    @State private var showEncryptedLockboxView = false
    
    @State private var selectedLockbox: LockerRoomLockbox? = nil
    
    var body: some View {
        VStack {
            Table(lockboxes, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("") { lockbox in
                    if lockbox.isEncrypted {
                        Image(systemName: "lock")
                    } else {
                        Image(systemName: "lock.open")
                    }
                }
                .width(min: 0, ideal: 0, max: 0)
                
                TableColumn("Name") { lockbox in
                    HStack {
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
            lockboxes = lockerRoomManager.lockboxes
            lockboxes.sort(using: sortOrder)
        }
        .onChange(of: lockerRoomManager.lockboxes) {
            lockboxes = lockerRoomManager.lockboxes
            lockboxes.sort(using: sortOrder)
        }
        .onChange(of: sortOrder) {
            lockboxes.sort(using: sortOrder)
        }
        .sheet(isPresented: $showUnencryptedLockboxAddView) {
            LockerRoomUnencryptedLockboxView(showView: $showUnencryptedLockboxAddView, lockbox: $selectedLockbox, viewStyle: .add)
        }
        .sheet(isPresented: $showUnencryptedLockboxView) {
            LockerRoomUnencryptedLockboxView(showView: $showUnencryptedLockboxView, lockbox: $selectedLockbox, viewStyle: .encrypt)
        }
        .sheet(isPresented: $showEncryptedLockboxView) {
            LockerRoomEncryptedLockboxView(showView: $showEncryptedLockboxView, lockbox: $selectedLockbox, viewStyle: .decrypt)
        }
    }
    
    @ViewBuilder
    private func selectedLockboxContextMenu(fromIDs lockboxIDs: Set<LockerRoomLockbox.ID>) -> some View {
        if let lockbox = selectedLockbox(fromIDs: lockboxIDs) {
            if !lockbox.isEncrypted {
                Button("Delete") {
                    let name = lockbox.name
                    _ = LockerRoomDiskImage().detach(name: name)
                    
                    guard lockerRoomManager.removeUnencryptedLockbox(name: name) else {
                        print("[Error] LockerRoom failed to remove unencrypted lockbox \(name)")
                        return
                    }
                }
            } else {
                EmptyView()
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
        guard let lockboxID = lockboxIDs.first, let lockbox = lockboxes.first(where: { $0.id == lockboxID }) else { // TODO: Is this really the best way to get the lockbox I just selected...
            print("[Error] LockerRoom failed to find selected lockbox")
            return nil
        }
        return lockbox
    }
}

private struct LockerRoomKeysView: View {
    @ObservedObject var lockerRoomManager: LockerRoomManager
    
    @State private var enrolledKeys = [LockerRoomEnrolledKey]()
    @State private var selection: LockerRoomEnrolledKey.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\LockerRoomEnrolledKey.name)]
    
    @State private var showLockboKeyAddView = false
    
    @State private var selectedLockboxKey: LockboxKey? = nil
    
    var body: some View {
        VStack {
            Table(enrolledKeys, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name)
                TableColumn("Serial Number") { enrolledKey in
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
            enrolledKeys = lockerRoomManager.enrolledKeys
            enrolledKeys.sort(using: sortOrder)
        }
        .onChange(of: lockerRoomManager.enrolledKeys) {
            enrolledKeys = lockerRoomManager.enrolledKeys
            enrolledKeys.sort(using: sortOrder)
        }
        .onChange(of: sortOrder) {
            enrolledKeys.sort(using: sortOrder)
        }
        .sheet(isPresented: $showLockboKeyAddView) {
            LockerRoomLockboxKeyView(showView: $showLockboKeyAddView, viewStyle: .enroll)
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
