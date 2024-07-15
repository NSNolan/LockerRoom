//
//  LockerRoomExternalDiskDiscovery.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/19/24.
//

import Foundation

import os.log

protocol LockerRoomExternalDiskDiscovering {
    var externalMediasByDeviceUnit: [Int:LockerRoomExternalMedia] { get }
    
    func activate() -> Bool
    func invalidate() -> Bool
}

@Observable class LockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering {
    private let session: DASession?
    private let sessionQueue: DispatchQueue
    private let lockerRoomDefaults: LockerRoomDefaulting
    
    private var isSessionActive = false
    
    var externalMediasByDeviceUnit = [Int:LockerRoomExternalMedia]()
    
    init(lockerRoomDefaults: LockerRoomDefaulting) {
        self.lockerRoomDefaults = lockerRoomDefaults
        
        self.session = DASessionCreate(kCFAllocatorDefault)
        self.sessionQueue = DispatchQueue(label: "com.nsnolan.LockerRoom.LockerRoomExternalDiskDiscovery", qos: .utility)
        self.sessionQueue.suspend()
        
        guard let session else {
            Logger.diskDiscovery.error("Locker room external disk discovery failed to create disk arbitration session")
            return
        }
        
        let appearedCallback: DADiskAppearedCallback = { disk, context in
            guard let context else {
                Logger.diskDiscovery.error("Locker room external disk discovery failed to receive context")
                return
            }
            
            guard let diskPartition = disk.lockerRoomExternalDiskPartition else {
                return
            }
            
            let capturedSelf = Unmanaged<LockerRoomExternalDiskDiscovery>.fromOpaque(context).takeUnretainedValue()
            
            DispatchQueue.main.async {
                var externalMediasByDeviceUnit = capturedSelf.externalMediasByDeviceUnit
                let deviceUnit = diskPartition.deviceUnit
                let mediaUUID = diskPartition.mediaUUID
                
                if var externalMedia = externalMediasByDeviceUnit[deviceUnit] {
                    externalMedia.diskPartitionsByID[mediaUUID] = diskPartition
                    externalMediasByDeviceUnit[deviceUnit] = externalMedia
                } else {
                    var externalMedia = LockerRoomExternalMedia()
                    externalMedia.diskPartitionsByID[mediaUUID] = diskPartition
                    externalMediasByDeviceUnit[deviceUnit] = externalMedia
                }
                
                capturedSelf.externalMediasByDeviceUnit = externalMediasByDeviceUnit
                
                Logger.diskDiscovery.log("Locker room external disk discovery found external disk partition \(diskPartition.mediaName) with BSD name \(diskPartition.bsdName) device unit \(deviceUnit) id \(mediaUUID)")
            }
        }
        
        let disappearedCallback: DADiskDisappearedCallback = { disk, context in
            guard let context else {
                Logger.diskDiscovery.error("Locker room external disk discovery failed to receive context")
                return
            }
            
            guard let diskPartition = disk.lockerRoomExternalDiskPartition else {
                return
            }
            
            let capturedSelf = Unmanaged<LockerRoomExternalDiskDiscovery>.fromOpaque(context).takeUnretainedValue()
            
            DispatchQueue.main.async {
                var externalMediasByDeviceUnit = capturedSelf.externalMediasByDeviceUnit
                let deviceUnit = diskPartition.deviceUnit
                let mediaUUID = diskPartition.mediaUUID
                
                if var externalMedia = externalMediasByDeviceUnit[deviceUnit] {
                    externalMedia.diskPartitionsByID[mediaUUID] = nil
                    externalMediasByDeviceUnit[deviceUnit] = externalMedia
                    capturedSelf.externalMediasByDeviceUnit = externalMediasByDeviceUnit
                    
                    Logger.diskDiscovery.log("Locker room external disk discovery lost external disk partition \(diskPartition.mediaName) with BSD name \(diskPartition.bsdName) device unit \(deviceUnit) id \(mediaUUID)")
                }
            }
        }
        
        let matching  = [ kDADiskDescriptionDeviceInternalKey: false ] as CFDictionary
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        DARegisterDiskAppearedCallback(session, matching, appearedCallback, context)
        DARegisterDiskDisappearedCallback(session, matching, disappearedCallback, context)
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
        externalMediasByDeviceUnit.removeAll()
        Logger.service.log("Locker room external disk discovery invalidated")
        
        return true
    }
}
