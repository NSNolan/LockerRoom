//
//  LockerRoomExternalDiskDiscovery.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/19/24.
//

import Foundation

import DiskArbitration
import os.log

protocol LockerRoomExternalDiskDiscovering {
    var disksByID: [UUID:LockerRoomExternalDisk] { get }
    
    func activate() -> Bool
    func invalidate() -> Bool
}

@Observable class LockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering {
    var disksByID: [UUID:LockerRoomExternalDisk] = [UUID:LockerRoomExternalDisk]()
    
    private let session: DASession?
    private let sessionQueue: DispatchQueue
    private let lockerRoomDefaults: LockerRoomDefaulting
    private let lockerRoomURLProvider: LockerRoomURLProviding
    
    private var isSessionActive = false
    
    init(lockerRoomDefaults: LockerRoomDefaulting, lockerRoomURLProvider: LockerRoomURLProviding) {
        self.session = DASessionCreate(kCFAllocatorDefault)
        self.sessionQueue = DispatchQueue(label: "com.nsnolan.LockerRoom.LockerRoomExternalDiskDiscovery", qos: .utility)
        self.sessionQueue.suspend()
        self.lockerRoomDefaults = lockerRoomDefaults
        self.lockerRoomURLProvider = lockerRoomURLProvider
        
        guard let session else {
            Logger.diskDiscovery.error("Locker room external disk discovery failed to create disk arbitration session")
            return
        }
        
        let appearedCallback: DADiskAppearedCallback = { (disk, context) in
            guard let context else {
                Logger.diskDiscovery.error("Locker room external disk discovery failed to receive context")
                return
            }
            
            guard let externalDisk = disk.lockerRoomExternalDisk else {
                return
            }
            
            let capturedSelf = Unmanaged<LockerRoomExternalDiskDiscovery>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async {
                capturedSelf.disksByID[externalDisk.id] = externalDisk
                Logger.diskDiscovery.log("Locker room external disk discovery found external disk \(externalDisk.name) with BSD name \(externalDisk.bsdName) id \(externalDisk.id)")
            }
        }
        
        let disappearedCallback: DADiskDisappearedCallback = { (disk, context) in
            guard let context else {
                Logger.diskDiscovery.error("Locker room external disk discovery failed to receive context")
                return
            }
            
            guard let externalDisk = disk.lockerRoomExternalDisk else {
                return
            }
            
            let capturedSelf = Unmanaged<LockerRoomExternalDiskDiscovery>.fromOpaque(context).takeUnretainedValue()
            DispatchQueue.main.async {
                capturedSelf.disksByID[externalDisk.id] = nil
                Logger.diskDiscovery.log("Locker room external disk discovery lost external disk \(externalDisk.name) with BSD name \(externalDisk.bsdName) id \(externalDisk.id)")
            }
        }
        
        let matching: [NSString:Any]  = [
            kDADiskDescriptionDeviceInternalKey: false,
            kDADiskDescriptionVolumeMountableKey: true
        ]
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        DARegisterDiskAppearedCallback(session, matching as CFDictionary, appearedCallback, context)
        DARegisterDiskDisappearedCallback(session, matching as CFDictionary, disappearedCallback, context)
        
        DASessionSetDispatchQueue(session, sessionQueue)
    }
    
    private var shouldEnable: Bool {
        return lockerRoomDefaults.externalDisksEnabled
    }
    
    func activate() -> Bool {
        guard shouldEnable && !isSessionActive else {
            return true
        }
        
        sessionQueue.resume()
        isSessionActive = true
        Logger.service.log("Locker room external disk discovery activated")
        
        return true
    }
    
    func invalidate() -> Bool {
        guard isSessionActive else {
            return true
        }
        
        sessionQueue.suspend()
        isSessionActive = false
        disksByID.removeAll()
        Logger.service.log("Locker room external disk discovery invalidated")
        
        return true
    }
}

extension DADisk {
    var lockerRoomExternalDisk: LockerRoomExternalDisk? {
        guard let description = DADiskCopyDescription(self) as NSDictionary? else {
            Logger.diskDiscovery.error("Locker room external disk discovery found disk with without description")
            return nil
        }
        
        guard let uuidObject = description[kDADiskDescriptionMediaUUIDKey] else {
            Logger.diskDiscovery.error("Locker room external disk discovery found disk description with without uuid \(description)")
            return nil
        }
        
        // TODO: A conditional cast (as?) produces error that a downcast to CFUUID will always succeed
        //       An unconditional cast (as) produces error that Any? is not convertible to CFUUID
        //       Why am I required to use a force cast (as!) here?
        let uuid = uuidObject as! CFUUID
        
        guard let uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid) as String? else {
            Logger.diskDiscovery.error("Locker room external disk discovery failed to convert uuid \(String(describing: uuid)) to string")
            return nil
        }
        
        guard let id = UUID(uuidString: uuidString) else {
            Logger.diskDiscovery.error("Locker room external disk discovery failed to convert uuid \(String(describing: uuid)) to id")
            return nil
        }
        
        guard let name = description[kDADiskDescriptionMediaNameKey] as? String else {
            Logger.diskDiscovery.error("Locker room external disk discovery found disk description with without name \(description)")
            return nil
        }
        
        guard let bsdName = description[kDADiskDescriptionMediaBSDNameKey] as? String else {
            Logger.diskDiscovery.error("Locker room external disk discovery found disk description without BSD name \(description)")
            return nil
        }
        
        guard let sizeInBytes = description[kDADiskDescriptionMediaSizeKey] as? Int else {
            Logger.diskDiscovery.error("Locker room external disk discovery found disk description without size \(description)")
            return nil
        }
        
        let sizeInMegabytes = sizeInBytes / (1024 * 1024)
        
        return LockerRoomExternalDisk(id: id, name: name, bsdName: bsdName, size: sizeInMegabytes)
    }
}
