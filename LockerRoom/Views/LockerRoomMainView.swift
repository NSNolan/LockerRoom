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

    var body: some View {
        VStack {
            switch viewStyle {
            case .lockboxes:
                LockerRoomLockboxesView()
            case .keys:
                LockerRoomKeysView()
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
    @ObservedObject var lockerRoomManager = LockerRoomManager.shared
    
    @State private var lockboxMetadatas = [LockerRoomLockboxMetadata]()
    @State private var selection: LockerRoomLockboxMetadata.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\LockerRoomLockboxMetadata.name)]
    
    @State private var showUnencryptedLockboxAddView = false
    @State private var showUnencryptedLockboxView = false
    @State private var showEncryptedLockboxView = false
    
    @State private var selectedUnencryptedLockbox: UnencryptedLockbox? = nil
    @State private var selectedEncryptedLockbox: EncryptedLockbox? = nil
    
    var body: some View {
        VStack {
            Table(lockboxMetadatas, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("") { lockboxMetadata in
                    if lockboxMetadata.isEncrypted {
                        Image(systemName: "lock")
                    } else {
                        Image(systemName: "lock.open")
                    }
                }
                .width(min: 0, ideal: 0, max: 0)
                
                TableColumn("Name", value: \.name)
                TableColumn("Path") { lockboxMetadata in
                    Text(lockboxMetadata.url.path())
                }
            }
            .contextMenu(forSelectionType: LockerRoomLockboxMetadata.ID.self) { metadataIDs in
                // None
            } primaryAction: { metadataIDs in
                selectLockbox(fromMetadataIDs: metadataIDs)
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
            lockboxMetadatas = lockerRoomManager.lockboxMetadatas
            lockboxMetadatas.sort(using: sortOrder)
        }
        .onChange(of: lockerRoomManager.lockboxMetadatas) {
            lockboxMetadatas = lockerRoomManager.lockboxMetadatas
            lockboxMetadatas.sort(using: sortOrder)
        }
        .onChange(of: sortOrder) {
            lockboxMetadatas.sort(using: sortOrder)
        }
        .sheet(isPresented: $showUnencryptedLockboxAddView) {
            LockerRoomUnencryptedLockboxView(showView: $showUnencryptedLockboxAddView, unencryptedLockbox: $selectedUnencryptedLockbox, viewStyle: .add)
        }
        .sheet(isPresented: $showUnencryptedLockboxView) {
            LockerRoomUnencryptedLockboxView(showView: $showUnencryptedLockboxView, unencryptedLockbox: $selectedUnencryptedLockbox, viewStyle: .encrypt)
        }
        .sheet(isPresented: $showEncryptedLockboxView) {
            LockerRoomEncryptedLockboxView(showView: $showEncryptedLockboxView, encryptedLockbox: $selectedEncryptedLockbox, viewStyle: .decrypt)
        }
    }
    
    private func selectLockbox(fromMetadataIDs metadataIDs: Set<LockerRoomLockboxMetadata.ID>) {
        if let metadataID = metadataIDs.first, let metadata = lockboxMetadatas.first(where: { $0.id == metadataID }) { // TODO: Is this really the best way to get the row I just selected...
            let lockerRoomStore = lockerRoomManager.lockerRoomStore
            if metadata.isEncrypted {
                selectedEncryptedLockbox = EncryptedLockbox.create(from: metadata, lockerRoomStore: lockerRoomStore)
                showEncryptedLockboxView = true
            } else {
                selectedUnencryptedLockbox = UnencryptedLockbox.create(from: metadata, lockerRoomStore: lockerRoomStore)
                showUnencryptedLockboxView = true
            }
        }
    }
}

private struct LockerRoomKeysView: View {
    @ObservedObject var lockerRoomManager = LockerRoomManager.shared
    
    @State private var lockboxKeyMetadatas = [LockerRoomLockboxKeyMetadata]()
    @State private var selection: LockerRoomLockboxKeyMetadata.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\LockerRoomLockboxKeyMetadata.name)]
    
    @State private var showLockboKeyAddView = false
    
    @State private var selectedLockboxKey: LockboxKey? = nil
    
    var body: some View {
        VStack {
            Table(lockboxKeyMetadatas, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name)
                TableColumn("Serial Number") { lockboxKeyMetadata in
                    Text("\(String(lockboxKeyMetadata.serialNumber))")
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
            lockboxKeyMetadatas = lockerRoomManager.lockboxKeyMetadatas
            lockboxKeyMetadatas.sort(using: sortOrder)
        }
        .onChange(of: lockerRoomManager.lockboxKeyMetadatas) {
            lockboxKeyMetadatas = lockerRoomManager.lockboxKeyMetadatas
            lockboxKeyMetadatas.sort(using: sortOrder)
        }
        .onChange(of: sortOrder) {
            lockboxKeyMetadatas.sort(using: sortOrder)
        }
        .sheet(isPresented: $showLockboKeyAddView) {
            LockerRoomLockboxKeyView(showView: $showLockboKeyAddView, viewStyle: .enroll)
        }
    }
}

#Preview {
    LockerRoomMainView()
}
