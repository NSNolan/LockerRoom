//
//  LockerRoomExternalDiskPartition.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 7/1/24.
//

import Foundation

import os.log

struct LockerRoomExternalDiskPartition {
    enum VolumeType: String {
        case apfs = "APFS"
        case none = "None"
        case unknown = "Unknown"
    }
    
    let bsdName: String
    let deviceUnit: Int
    let mediaName: String
    let mediaUUID: UUID
    let mediaWhole: Bool
    let sizeInMegabytes: Int
    let volumeMountable: Bool
    let volumeName: String?
    let volumeType: VolumeType
}

extension DADisk {
    var lockerRoomExternalDiskPartition: LockerRoomExternalDiskPartition? {
        guard let description = DADiskCopyDescription(self) as NSDictionary? else {
            Logger.diskDiscovery.error("Disk arbitration disk cannot convert to disk partition without description")
            return nil
        }
        
        guard let bsdName = description[kDADiskDescriptionMediaBSDNameKey] as? String else {
            Logger.diskDiscovery.error("Disk arbitration disk cannot convert to disk partition without BSD name \(description)")
            return nil
        }
        
        guard let deviceUnit = description[kDADiskDescriptionDeviceUnitKey] as? Int else {
            Logger.diskDiscovery.error("Disk arbitration disk cannot convert to disk partition without device unit \(description)")
            return nil
        }
        
        guard let mediaName = description[kDADiskDescriptionMediaNameKey] as? String else {
            Logger.diskDiscovery.error("Disk arbitration disk cannot convert to disk partition without media name \(description)")
            return nil
        }
        
        guard let mediaUUIDObject = description[kDADiskDescriptionMediaUUIDKey] else {
            Logger.diskDiscovery.error("Disk arbitration disk cannot convert to disk partition without media uuid \(description)")
            return nil
        }
        
        // TODO: A conditional cast (as?) produces error that a downcast to CFUUID will always succeed
        //       An unconditional cast (as) produces error that Any? is not convertible to CFUUID
        //       Why am I required to use a force cast (as!) here?
        let mediaCFUUID = mediaUUIDObject as! CFUUID
        
        guard let mediaUUIDString = CFUUIDCreateString(kCFAllocatorDefault, mediaCFUUID) as String? else {
            Logger.diskDiscovery.error("Disk arbitration disk failed to convert cfuuid \(String(describing: mediaCFUUID)) to string")
            return nil
        }
        
        guard let mediaUUID = UUID(uuidString: mediaUUIDString) else {
            Logger.diskDiscovery.error("Disk arbitration disk failed to convert uuid string \(mediaUUIDString) to uuid")
            return nil
        }
        
        guard let mediaWhole = description[kDADiskDescriptionMediaWholeKey] as? Int else {
            Logger.diskDiscovery.error("Disk arbitration disk cannot convert to disk partition without media whole \(description)")
            return nil
        }
        
        guard let sizeInBytes = description[kDADiskDescriptionMediaSizeKey] as? Int else {
            Logger.diskDiscovery.error("Disk arbitration disk cannot convert to disk partition without media size \(description)")
            return nil
        }
        
        guard let volumeMountable = description[kDADiskDescriptionVolumeMountableKey] as? Int else {
            Logger.diskDiscovery.error("Disk arbitration disk cannot convert to disk partition without volume mountable \(description)")
            return nil
        }
        
        let volumeName = description[kDADiskDescriptionVolumeNameKey] as? String
        
        let volumeType: LockerRoomExternalDiskPartition.VolumeType
        let volumeTypeString = description[kDADiskDescriptionVolumeTypeKey] as? String
        if let volumeTypeString {
            if volumeTypeString == LockerRoomExternalDiskPartition.VolumeType.apfs.rawValue {
                volumeType = .apfs
            } else {
                volumeType = .unknown
            }
        } else {
            volumeType = .none
        }
        
        return LockerRoomExternalDiskPartition(
            bsdName: bsdName,
            deviceUnit: deviceUnit,
            mediaName: mediaName,
            mediaUUID: mediaUUID,
            mediaWhole: (mediaWhole != 0),
            sizeInMegabytes: (sizeInBytes / (1024 * 1024)),
            volumeMountable: (volumeMountable != 0),
            volumeName: volumeName,
            volumeType: volumeType
        )
    }
}
