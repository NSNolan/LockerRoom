//
//  LockerRoomDefaults.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/16/24.
//

import Foundation

protocol LockerRoomDefaulting {
    var experimentalPIVSlotsEnabled: Bool { get set }
    var externalDisksEnabled: Bool { get set }
    var remoteServiceEnabled: Bool { get set }
}

struct LockerRoomDefaults: LockerRoomDefaulting {
    private static let experimentalPIVSlotsEnabledKey = "ExperimentalPIVSlotsEnabled"
    private static let externalDisksEnabledKey = "ExternalDisksEnabled"
    private static let remoteServiceEnabledKey = "RemoteServiceEnabled"
    
    var experimentalPIVSlotsEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: LockerRoomDefaults.experimentalPIVSlotsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue ,forKey: LockerRoomDefaults.experimentalPIVSlotsEnabledKey)
        }
    }
    
    var externalDisksEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: LockerRoomDefaults.externalDisksEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue ,forKey: LockerRoomDefaults.externalDisksEnabledKey)
        }
    }
    
    var remoteServiceEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: LockerRoomDefaults.remoteServiceEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue ,forKey: LockerRoomDefaults.remoteServiceEnabledKey)
        }
    }
}
