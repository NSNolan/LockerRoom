//
//  LockerRoomDefaults.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/16/24.
//

import Foundation

protocol LockerRoomDefaulting {
    var serviceEnabled: Bool { get set }
    var externalDrivesEnabled: Bool { get set }
}

struct LockerRoomDefaults: LockerRoomDefaulting {
    private static let externalDrivesEnabledKey = "ExternalDrivesEnabled"
    private static let serivceEnabledKey = "ServiceEnabled"
    
    var externalDrivesEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: LockerRoomDefaults.externalDrivesEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue ,forKey: LockerRoomDefaults.externalDrivesEnabledKey)
        }
    }
    
    var serviceEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: LockerRoomDefaults.serivceEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue ,forKey: LockerRoomDefaults.serivceEnabledKey)
        }
    }
}
