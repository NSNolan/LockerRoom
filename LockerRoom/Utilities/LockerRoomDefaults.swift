//
//  LockerRoomDefaults.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/16/24.
//

import Foundation

protocol LockerRoomDefaulting {
    var serviceEnabled: Bool { get set }
}

struct LockerRoomDefaults: LockerRoomDefaulting {
    private static let lockerRoomSerivceEnabledKey = "LockerRoomServiceEnabled"
    
    var serviceEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: LockerRoomDefaults.lockerRoomSerivceEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue ,forKey: LockerRoomDefaults.lockerRoomSerivceEnabledKey)
        }
    }
}
