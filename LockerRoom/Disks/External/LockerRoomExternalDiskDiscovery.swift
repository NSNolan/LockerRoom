//
//  LockerRoomExternalDiskDiscovery.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/19/24.
//

import Foundation

import os.log

protocol LockerRoomExternalDiskDiscovering {
    var externalDiskDevicesByDeviceUnit: [Int:LockerRoomExternalDiskDevice] { get }
    
    func activate() -> Bool
    func invalidate() -> Bool
}

@Observable class LockerRoomExternalDiskDiscovery: LockerRoomExternalDiskDiscovering {
    private let session: DASession?
    private let sessionQueue: DispatchQueue
    private let lockerRoomDefaults: LockerRoomDefaulting
    
    private var isSessionActive = false
    
    var externalDiskDevicesByDeviceUnit = [Int:LockerRoomExternalDiskDevice]()
    
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
                var externalDiskDevicesByDeviceUnit = capturedSelf.externalDiskDevicesByDeviceUnit
                let deviceUnit = diskPartition.deviceUnit
                let mediaUUID = diskPartition.mediaUUID
                
                if var externalDiskDevice = externalDiskDevicesByDeviceUnit[deviceUnit] {
                    externalDiskDevice.diskPartitionsByID[mediaUUID] = diskPartition
                    externalDiskDevicesByDeviceUnit[deviceUnit] = externalDiskDevice
                } else {
                    var externalDiskDevice = LockerRoomExternalDiskDevice()
                    externalDiskDevice.diskPartitionsByID[mediaUUID] = diskPartition
                    externalDiskDevicesByDeviceUnit[deviceUnit] = externalDiskDevice
                }
                
                capturedSelf.externalDiskDevicesByDeviceUnit = externalDiskDevicesByDeviceUnit
                
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
                var externalDiskDevicesByDeviceUnit = capturedSelf.externalDiskDevicesByDeviceUnit
                let deviceUnit = diskPartition.deviceUnit
                let mediaUUID = diskPartition.mediaUUID
                
                if var externalDiskDevice = externalDiskDevicesByDeviceUnit[deviceUnit] {
                    externalDiskDevice.diskPartitionsByID[mediaUUID] = nil
                    externalDiskDevicesByDeviceUnit[deviceUnit] = externalDiskDevice
                    capturedSelf.externalDiskDevicesByDeviceUnit = externalDiskDevicesByDeviceUnit
                    
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
        externalDiskDevicesByDeviceUnit.removeAll()
        Logger.service.log("Locker room external disk discovery invalidated")
        
        return true
    }
}
