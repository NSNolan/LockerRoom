//
//  LockRoomListView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import SwiftUI

struct LockerRoomListView: View {
    @ObservedObject var lockboxManager = LockboxManager.shared
    
    @State private var lockboxMetadatas = [LockerRoomLockboxMetadata]()
    
    @State private var showUnencryptedLockboxAddView = false
    @State private var showUnencryptedLockboxView = false
    @State private var showEncryptedLockboxView = false
    
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
                // TODO: Is this really the best way to get the thing I just selected...
                if let metadataID = metadataIDs.first, let metadata = lockboxMetadatas.first(where: { $0.id == metadataID }) {
                    let lockboxStore = lockboxManager.lockboxStore
                    if metadata.isEncrypted {
                        selectedEncryptedLockbox = EncryptedLockbox(name: metadata.name, lockboxStore: lockboxStore)
                        showEncryptedLockboxView = true
                    } else {
                        selectedUnencryptedLockbox = UnencryptedLockbox(name: metadata.name, exists: true, lockboxStore: lockboxStore)
                        showUnencryptedLockboxView = true
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("New Lockbox...") {
                    showUnencryptedLockboxAddView = true
                }
                .padding()
            }
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
    }
}

#Preview {
    LockerRoomListView()
}
