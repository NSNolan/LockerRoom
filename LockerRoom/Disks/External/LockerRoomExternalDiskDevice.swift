//
//  LockerRoomExternalDiskDevice.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 7/1/24.
//

import Foundation

// When an external disk device, containing a single mountable APFS volume, is connected to a Mac the following 4 disks partitions are detected by the host system:
//
// /dev/diskX (external, physical):
//   #:                       TYPE NAME                    SIZE       IDENTIFIER
//   0:      GUID_partition_scheme                        *1.0 GB     diskX
//   1:                 Apple_APFS Container diskY         1.0 GB     diskXs1
//
// /dev/diskY (synthesized):
//   #:                       TYPE NAME                    SIZE       IDENTIFIER
//   0:      APFS Container Scheme -                      +1.0 GB     diskY
//                                 Physical Store diskXs1
//   1:                APFS Volume Name                    1.0 MB     diskYs1
//
// diskX and diskXs1 are file handles to the physical device, where diskX points to the GUID partition table and diskXs1 points to the APFS Physical Store.
// diskY and diskYs1 are file handles to the synthesized APFS device, where diskY points to the APFS Container and diskYs1 points to the AFPS Volume partition.
// If multiple APFS volumes are contained within the APFS Container than an additional number of corresponding synthesized disk will be created for each of
// those volumes (i.e. diskYs2, diskYs3, etc).
//
// For the purposes of disk encryption, an external disk device's APFS Physical Store should be completely encrypted but the GUID partition table should be kept
// in plaintext. This way any data within the AFPS Container will be encrypted but the physical disk can still be recognized by the host system.
//
// The following code identifies the APFS Phyiscal Store by finding the first non-media whole, non-volume mountable disk partition.

struct LockerRoomExternalDiskDevice {
    var diskPartitionsByID = [UUID:LockerRoomExternalDiskPartition]()
    
    private var apfsPhysicalStorePartition: LockerRoomExternalDiskPartition? {
        return diskPartitionsByID.values.first { !$0.mediaWhole && !$0.volumeMountable }
    }
    
    var bsdName: String? {
        return apfsPhysicalStorePartition?.bsdName
    }
    
    var name: String? {
        let volumes = volumeNames
        switch volumes.count {
        case 0:
            // Volume names on encrypted external disks will not be available; fallback to the physical storage name
            return apfsPhysicalStorePartition?.mediaName
        case 1:
            return volumes[0]
        case 2:
            return "\(volumes[0]) and \(volumes[1])"
        default:
            let allExceptLastVolume = volumes.dropLast().joined(separator: ", ")
            guard let lastVolume = volumes.last else {
                return allExceptLastVolume
            }
            return "\(allExceptLastVolume) and \(lastVolume)"
        }
    }
    
    var sizeInMegabytes: Int? {
        return apfsPhysicalStorePartition?.sizeInMegabytes
    }
    
    var uuid: UUID? {
        return apfsPhysicalStorePartition?.mediaUUID
    }
    
    var volumeNames: [String] {
        return diskPartitionsByID.values.compactMap {
            if let volumeName = $0.volumeName, $0.volumeMountable {
                return volumeName
            } else {
                return nil
            }
        }.sorted()
    }
}
