//
//  LockerRoomUnencryptedLockboxCreateOptionsView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/26/24.
//

import SwiftUI

import os.log

struct LockerRoomUnencryptedLockboxCreateOptionsView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    @Binding var showUnencryptedLockboxCreateView: Bool
    @Binding var showUnencryptedLockboxView: Bool
    
    @Binding var lockbox: LockerRoomLockbox?
    
    @Binding var showErrorView: Bool
    @Binding var error: LockerRoomError?
    
    var body: some View {
        VStack(alignment: .leading, spacing: -20) {
            Button(action: {
                showView = false
                showUnencryptedLockboxCreateView = true
            }) {
                HStack {
                    Image(systemName: "plus.square")
                    Text("Create new...")
                }
            }
            .buttonStyle(.plain)
            .padding()
            
            let eligibleExternalDisks = Array(lockerRoomManager.eligibleExternalDisksByID.values)
            
            if !eligibleExternalDisks.isEmpty {
                Divider()
                    .foregroundColor(.black)
                    .padding()
            }
            
            ForEach(eligibleExternalDisks) { externalDisk in
                let id = externalDisk.id
                let name = externalDisk.name
                let size = externalDisk.sizeInMegabytes
                
                Button(action: {
                    Task {
                        guard let newUnencryptedLockbox = await lockerRoomManager.addUnencryptedLockbox(id: id, name: name, size: size, isExternal: true) else {
                            Logger.lockerRoomUI.error("LockerRoom failed to create an external unencrypted lockbox \(name) with id \(id) of size \(size)MB")
                            error = .failedToCreateExternalLockbox
                            showView = false
                            showErrorView = true
                            return
                        }
                        Logger.lockerRoomUI.log("LockerRoom created an external unencrypted lockbox \(name) with \(id) of size \(size)MB")
                        
                        lockbox = newUnencryptedLockbox.metadata.lockerRoomLockbox
                        showView = false
                        showUnencryptedLockboxView = true
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.square.on.square")
                        Text("Create from \(externalDisk.name)")
                    }
                }
                .buttonStyle(.plain)
                .padding()
            }
        }
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
        .shadow(radius: 10)
    }
}
