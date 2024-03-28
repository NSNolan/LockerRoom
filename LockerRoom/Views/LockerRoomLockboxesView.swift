//
//  LockerRoomLockboxesView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import SwiftUI

enum LockerRoomLockboxesViewStyle: String, CaseIterable {
    case lockboxes = "Lockboxes"
    case keys = "Keys"
}

struct LockerRoomLockboxesView: View {
    @ObservedObject var lockboxManager = LockboxManager.shared
    
    @State private var lockboxMetadatas = [LockerRoomLockboxMetadata]()
    
    @State private var viewStyle: LockerRoomLockboxesViewStyle = .lockboxes
    
    @State private var showUnencryptedLockboxAddView = false
    @State private var showUnencryptedLockboxView = false
    @State private var showEncryptedLockboxView = false
    @State private var showKeysView = false
    
    @State private var selection: LockerRoomLockboxMetadata.ID? = nil
    @State private var sortOrder = [KeyPathComparator(\LockerRoomLockboxMetadata.name)]
    
    @State private var selectedUnencryptedLockbox: UnencryptedLockbox? = nil
    @State private var selectedEncryptedLockbox: EncryptedLockbox? = nil
    
    var body: some View {
        VStack {
            Table(lockboxMetadatas, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("") { metadata in
                    if metadata.isEncrypted {
                        Image(systemName: "lock")
                    } else {
                        Image(systemName: "lock.open")
                    }
                }
                .width(min: 0, ideal: 0, max: 0)
                
                TableColumn("Name", value: \.name)
                TableColumn("Path") { metadata in
                    Text(metadata.url.path())
                }
            }
            .contextMenu(forSelectionType: LockerRoomLockboxMetadata.ID.self) { metadataIDs in
                // None
            } primaryAction: { metadataIDs in
                selectLockbox(fromMetadataIDs: metadataIDs)
            }
            
            HStack {
                Spacer()
                
                Button("Keys...") {
                    showKeysView = true
                }
                
                Button(action: {
                    showUnencryptedLockboxAddView = true
                }) {
                    Image(systemName: "plus")
                }
            }
            .padding()
        }
        .onAppear() {
            lockboxMetadatas = lockboxManager.lockboxMetadatas
            lockboxMetadatas.sort(using: sortOrder)
        }
        .onChange(of: lockboxManager.lockboxMetadatas) {
            lockboxMetadatas = lockboxManager.lockboxMetadatas
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
        .sheet(isPresented: $showKeysView) {
            LockerRoomKeysView(showView: $showKeysView, viewStyle: .main)
        }
//        .toolbar {
//            Picker("", selection: $viewStyle) {
//                ForEach(LockerRoomKeysViewStyle.allCases) { option in
//                    Text(option.rawValue).tag(option)
//                }
//            }
//        }
    }
    
    private func selectLockbox(fromMetadataIDs metadataIDs: Set<LockerRoomLockboxMetadata.ID>) {
        if let metadataID = metadataIDs.first, let metadata = lockboxMetadatas.first(where: { $0.id == metadataID }) { // TODO: Is this really the best way to get the row I just selected in this callback...
            let lockboxStore = lockboxManager.lockboxStore
            if metadata.isEncrypted {
                selectedEncryptedLockbox = EncryptedLockbox(name: metadata.name, lockboxStore: lockboxStore)
                showEncryptedLockboxView = true
            } else {
                selectedUnencryptedLockbox = UnencryptedLockbox(name: metadata.name, lockboxStore: lockboxStore) // TODO: Consider how to indicate this unecrypted lockbox already exists
                showUnencryptedLockboxView = true
            }
        }
    }
}

#Preview {
    LockerRoomLockboxesView()
}
