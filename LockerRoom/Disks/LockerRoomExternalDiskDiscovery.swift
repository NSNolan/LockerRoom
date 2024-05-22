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
    private let lockerRoomURLProvider: LockerRoomURLProviding
    
    private var isSessionActive = false
    
    init(lockerRoomDefaults: LockerRoomDefaulting, lockerRoomURLProvider: LockerRoomURLProviding) {
        self.session = DASessionCreate(kCFAllocatorDefault)
        self.sessionQueue = DispatchQueue(label: "com.nsnolan.LockerRoom.LockerRoomExternalDiskFinder", qos: .utility)
        self.sessionQueue.suspend()
        self.lockerRoomDefaults = lockerRoomDefaults
        self.lockerRoomURLProvider = lockerRoomURLProvider
        
        guard let session else {
            Logger.externalDrive.error("Locker room external disk discovery failed to create disk arbitration session")
            return
        }
        
        let appearedCallback: DADiskAppearedCallback = { (disk, context) in
            guard let context else {
                Logger.externalDrive.error("Locker room external disk discovery failed to receive context")
                return
            }
            
            let capturedSelf = Unmanaged<LockerRoomExternalDiskDiscovery>.fromOpaque(context).takeUnretainedValue()
            
            guard let externalDisk = disk.lockerRoomExternalDisk(lockerRoomURLProvider: capturedSelf.lockerRoomURLProvider) else {
                return
            }
            
            DispatchQueue.main.async {
                capturedSelf.disks.append(externalDisk)
                Logger.externalDrive.log("Locker room external disk discovery found external disk \(externalDisk.name) with uuid \(externalDisk.uuidString) at path \(externalDisk.devicePath)")
            }
        }
        
        let disappearedCallback: DADiskDisappearedCallback = { (disk, context) in
            guard let context else {
                Logger.externalDrive.error("Locker room external disk discovery failed to receive context")
                return
            }
            
            let capturedSelf = Unmanaged<LockerRoomExternalDiskDiscovery>.fromOpaque(context).takeUnretainedValue()
            
            guard let externalDisk = disk.lockerRoomExternalDisk(lockerRoomURLProvider: capturedSelf.lockerRoomURLProvider) else {
                return
            }
            
            DispatchQueue.main.async {
                capturedSelf.disks.removeAll { $0.uuidString == externalDisk.uuidString }
                Logger.externalDrive.log("Locker room external disk discovery lost external disk \(externalDisk.name) with uuid \(externalDisk.uuidString) at path \(externalDisk.devicePath)")
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
        disks.removeAll()
        Logger.service.log("Locker room external disk discovery invalidated")
        
        return true
    }
}

extension DADisk {
    func lockerRoomExternalDisk(lockerRoomURLProvider: LockerRoomURLProviding) -> LockerRoomExternalDisk? {
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
        
        guard let bsdName = description[kDADiskDescriptionMediaBSDNameKey] as? String else {
            Logger.externalDrive.error("Locker room external disk discovery found disk description without BSD name \(description)")
            return nil
        }
        
        let deviceURL = lockerRoomURLProvider.urlForAttachedDevice(name: bsdName)
        let devicePath = deviceURL.path(percentEncoded: false)
        
        return LockerRoomExternalDisk(name: name, uuidString: uuidString, devicePath: devicePath)
    }
}
