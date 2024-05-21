//
//  LockerRoomDefaults.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/16/24.
//

import Foundation

protocol LockerRoomDefaulting {
    var experimentalPIVSlotsEnabled: Bool { get set }
    var externalDrivesEnabled: Bool { get set }
    var serviceEnabled: Bool { get set }
}

struct LockerRoomDefaults: LockerRoomDefaulting {
    private static let experimentalPIVSlotsEnabledKey = "ExperimentalPIVSlotsEnabled"
    private static let externalDrivesEnabledKey = "ExternalDrivesEnabled"
    private static let serivceEnabledKey = "ServiceEnabled"
    
    var experimentalPIVSlotsEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: LockerRoomDefaults.experimentalPIVSlotsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue ,forKey: LockerRoomDefaults.experimentalPIVSlotsEnabledKey)
        }
    }
    
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
