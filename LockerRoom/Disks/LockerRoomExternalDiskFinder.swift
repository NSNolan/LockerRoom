//
//  LockerRoomExternalDiskFinder.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/19/24.
//

import Foundation

import DiskArbitration
import os.log

protocol LockerRoomExternalDiskFinding {
    var disks: [LockerRoomExternalDisk] { get }
    
    func activate() -> Bool
    func invalidate() -> Bool
}

class LockerRoomExternalDiskFinder: LockerRoomExternalDiskFinding {
    @Published var disks: [LockerRoomExternalDisk] = [LockerRoomExternalDisk]()
    
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
            Logger.externalDrive.error("Locker room external disk finder failed to create disk arbitration session")
            return
        }
        
        let appearedCallback: DADiskAppearedCallback = { (disk, context) in
            guard let externalDisk = disk.lockerRoomExternalDisk else {
                return
            }
            
            guard let context else {
                Logger.externalDrive.error("Locker room external disk finder failed to receive context")
                return
            }
            
            DispatchQueue.main.async {
                let capturedSelf = Unmanaged<LockerRoomExternalDiskFinder>.fromOpaque(context).takeUnretainedValue()
                capturedSelf.disks.append(externalDisk)
                Logger.externalDrive.log("Locker room external disk finder added external disk \(externalDisk.name) with uuid \(externalDisk.uuidString)")
            }
        }
        
        let disappearedCallback: DADiskDisappearedCallback = { (disk, context) in
            guard let externalDisk = disk.lockerRoomExternalDisk else {
                return
            }
            
            guard let context else {
                Logger.externalDrive.error("Locker room external disk finder failed to receive context")
                return
            }
            
            DispatchQueue.main.async {
                let capturedSelf = Unmanaged<LockerRoomExternalDiskFinder>.fromOpaque(context).takeUnretainedValue()
                capturedSelf.disks.removeAll { $0.uuidString == externalDisk.uuidString }
                Logger.externalDrive.log("Locker room external disk finder removed external disk \(externalDisk.name) with uuid \(externalDisk.uuidString)")
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
        return lockerRoomDefaults.externalDrivesEnabled
    }
    
    func activate() -> Bool {
        guard shouldEnable && !isSessionActive else {
            return true
        }
        
        sessionQueue.resume()
        isSessionActive = true
        Logger.service.log("Locker room external disk finder activated")
        
        return true
    }
    
    func invalidate() -> Bool {
        guard isSessionActive else {
            return true
        }
        
        sessionQueue.suspend()
        isSessionActive = false
        Logger.service.log("Locker room external disk finder invalidated")
        
        return true
    }
}

extension DADisk {
    var lockerRoomExternalDisk: LockerRoomExternalDisk? {
        guard let description = DADiskCopyDescription(self) as NSDictionary? else {
            Logger.externalDrive.error("Locker room external disk finder found disk with without description")
            return nil
        }
        
        guard let name = description[kDADiskDescriptionVolumeNameKey] as? String else {
            return nil
        }
        
        guard let uuidObject = description[kDADiskDescriptionMediaUUIDKey] else {
            return nil
        }
        
        // TODO: A conditional cast (as?) produces error that a downcast to CFUUID will always succeed
        //       An unconditional cast (as) produces error that Any? is not convertible to CFUUID
        //       Why am I required to use a force cast (as!) here?
        let uuid = uuidObject as! CFUUID
        
        guard let uuidString = CFUUIDCreateString(kCFAllocatorDefault, uuid) as String? else {
            return nil
        }
        
        return LockerRoomExternalDisk(name: name, uuidString: uuidString)
    }
}
