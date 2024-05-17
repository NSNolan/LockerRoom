//
//  LockerRoomApp.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/21/24.
//

import SwiftUI

@main
struct LockerRoomApp: App {
    @NSApplicationDelegateAdaptor(LockerRoomAppLifecycle.self) private var lockerRoomAppLifecycle
    
    var body: some Scene {
        WindowGroup {
            LockerRoomMainView()
        }
    }
}
