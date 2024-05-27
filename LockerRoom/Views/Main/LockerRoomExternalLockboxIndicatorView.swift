//
//  LockerRoomExternalLockboxIndicatorView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/26/24.
//

import SwiftUI

struct LockerRoomExternalLockboxIndicatorView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @State private var trackIsPresent = false
    
    let lockbox: LockerRoomLockbox
    
    var isPresent: Bool {
        return (lockerRoomManager.presentExternalLockboxDisksByID[lockbox.id] != nil)
    }
    
    var body: some View {
        Image(systemName: "externaldrive")
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(
                HStack {
                    Capsule()
                        .fill(isPresent ? .green : .red)
                }
            )
            .foregroundColor(.white)
            .symbolEffect(.pulse, options: .repeat(3), value: lockerRoomManager.presentExternalLockboxDisksByID[lockbox.id])
            .symbolVariant(.fill)
            .onChange(of: lockerRoomManager.presentExternalLockboxDisksByID) {
                trackIsPresent = isPresent // `trackIsPresent` will trigger a symbol effect when it changes.
            }
    }
}
