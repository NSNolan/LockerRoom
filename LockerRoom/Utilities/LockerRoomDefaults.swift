//
//  LockerRoomDefaults.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/16/24.
//

import Foundation

protocol LockerRoomDefaulting {
    var cryptorChunkSizeInBytes: Int { get set }
    var diskVerificationEnabled: Bool { get set }
    var experimentalPIVSlotsEnabled: Bool { get set }
    var externalDisksEnabled: Bool { get set }
    var remoteServiceEnabled: Bool { get set }
}

struct LockerRoomDefaults: LockerRoomDefaulting {
    private static let cryptorChunkSizeInBytesKey = "CryptorChunkSizeInBytes"
    private static let diskVerificationEnabledKey = "DiskVerificationEnabledKey"
    private static let experimentalPIVSlotsEnabledKey = "ExperimentalPIVSlotsEnabled"
    private static let externalDisksEnabledKey = "ExternalDisksEnabled"
    private static let remoteServiceEnabledKey = "RemoteServiceEnabled"
    
    private static let cryptorChunkSizeDefault = 256 * 1024 // 256 KB
    private static let cryptorChunkSizeMax = 1 * 1024 * 1024 * 1024 // 1 GB
    
    let defaults = UserDefaults.standard
    
    var cryptorChunkSizeInBytes: Int {
        get {
            let chunkSize = defaults.integer(forKey: LockerRoomDefaults.cryptorChunkSizeInBytesKey)
            guard chunkSize > 0 && chunkSize <= LockerRoomDefaults.cryptorChunkSizeMax else {
                return LockerRoomDefaults.cryptorChunkSizeDefault
            }
            return chunkSize
        }
        set {
            defaults.set(newValue, forKey: LockerRoomDefaults.cryptorChunkSizeInBytesKey)
        }
    }
    
    var diskVerificationEnabled: Bool {
        get {
            return defaults.object(forKey: LockerRoomDefaults.diskVerificationEnabledKey) as? Bool ?? true
        }
        set {
            defaults.setValue(newValue, forKey: LockerRoomDefaults.diskVerificationEnabledKey)
        }
    }
    
    var experimentalPIVSlotsEnabled: Bool {
        get {
            return defaults.bool(forKey: LockerRoomDefaults.experimentalPIVSlotsEnabledKey)
        }
        set {
            defaults.set(newValue ,forKey: LockerRoomDefaults.experimentalPIVSlotsEnabledKey)
        }
    }
    
    var externalDisksEnabled: Bool {
        get {
            return defaults.bool(forKey: LockerRoomDefaults.externalDisksEnabledKey)
        }
        set {
            defaults.set(newValue ,forKey: LockerRoomDefaults.externalDisksEnabledKey)
        }
    }
    
    var remoteServiceEnabled: Bool {
        get {
            return defaults.bool(forKey: LockerRoomDefaults.remoteServiceEnabledKey)
        }
        set {
            defaults.set(newValue ,forKey: LockerRoomDefaults.remoteServiceEnabledKey)
        }
    }
}
