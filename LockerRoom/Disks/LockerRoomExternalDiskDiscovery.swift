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
    var disks: [LockerRoomExternalDisk] { get }
    
    func activate() -> Bool
    func invalidate() -> Bool
}

@Observable class LockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering {
    var disks: [LockerRoomExternalDisk] = [LockerRoomExternalDisk]()
    
    private let session: DASession?
    private let sessionQueue: DispatchQueue
    private let lockerRoomDefaults: LockerRoomDefaulting
    
    private var isSessionActive = false
    
    init(lockerRoomDefaults: LockerRoomDefaulting) {
        self.session = DASessionCreate(kCFAllocatorDefault)
        self.sessionQueue = DispatchQueue(label: "com.nsnolan.LockerRoom.LockerRoomExternalDiskFinder", qos: .utility)
        self.sessionQueue.suspend()
        self.lockerRoomDefaults = lockerRoomDefaults
        
        guard let session else {
            Logger.externalDrive.error("Locker room external disk discovery failed to create disk arbitration session")
            return
        }
        
        let appearedCallback: DADiskAppearedCallback = { (disk, context) in
            guard let externalDisk = disk.lockerRoomExternalDisk else {
                return
            }
            
            guard let context else {
                Logger.externalDrive.error("Locker room external disk discovery failed to receive context")
                return
            }
            
            DispatchQueue.main.async {
                let capturedSelf = Unmanaged<LockerRoomExternalDiskDiscovery>.fromOpaque(context).takeUnretainedValue()
                capturedSelf.disks.append(externalDisk)
                Logger.externalDrive.log("Locker room external disk discovery found external disk \(externalDisk.name) with uuid \(externalDisk.uuidString)")
            }
        }
        
        let disappearedCallback: DADiskDisappearedCallback = { (disk, context) in
            guard let externalDisk = disk.lockerRoomExternalDisk else {
                return
            }
            
            guard let context else {
                Logger.externalDrive.error("Locker room external disk discovery failed to receive context")
                return
            }
            
            DispatchQueue.main.async {
                let capturedSelf = Unmanaged<LockerRoomExternalDiskDiscovery>.fromOpaque(context).takeUnretainedValue()
                capturedSelf.disks.removeAll { $0.uuidString == externalDisk.uuidString }
                Logger.externalDrive.log("Locker room external disk discovery lost external disk \(externalDisk.name) with uuid \(externalDisk.uuidString)")
            }
        }
        
        let matching: [NSString:Any]  = [
            kDADiskDescriptionDeviceInternalKey: false
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
        Logger.service.log("Locker room external disk discovery invalidated")
        
        return true
    }
}

extension DADisk {
    var lockerRoomExternalDisk: LockerRoomExternalDisk? {
        guard let description = DADiskCopyDescription(self) as NSDictionary? else {
            Logger.externalDrive.error("Locker room external disk discovery found disk with without description")
            return nil
        }
                
        guard let name = description[kDADiskDescriptionMediaNameKey] as? String else {
            Logger.externalDrive.error("Locker room external disk discovery found disk description with without name \(description)")
            return nil
        }
        
        guard let uuidObject = description[kDADiskDescriptionMediaUUIDKey] else {
            Logger.externalDrive.error("Locker room external disk discovery found disk description with without uuid \(description)")
            return nil
        }
        
        // TODO: A conditional cast (as?) produces error that a downcast to CFUUID will always succeed
        //       An unconditional cast (as) produces error that Any? is not convertible to CFUUID
        //       Why am I required to use a force cast (as!) here?
        let uuid = uuidObject as! CFUUID
        
        guard let uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid) as String? else {
            Logger.externalDrive.error("Locker room external disk discovery failed to convert uuid \(String(describing: uuid)) to string")
            return nil
        }
        
        return LockerRoomExternalDisk(name: name, uuidString: uuidString)
    }
}
