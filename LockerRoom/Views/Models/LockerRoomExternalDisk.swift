//
//  LockerRoomExternalDisk.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/21/24.
//

import Foundation

import os.log

struct LockerRoomExternalDisk: Identifiable, Equatable {
    let id: UUID
    let name: String
    let bsdName: String
    let sizeInMegabytes: Int
    let volumes: [String]
}

extension LockerRoomExternalMedia {
    var lockerRoomExternalDisk: LockerRoomExternalDisk? {
        guard let bsdName,
              let name,
              let sizeInMegabytes,
              let uuid else {
            Logger.diskDiscovery.error("Locker room external media cannot convert to external disk with BSD name \(bsdName) name \(name) size \(String(describing: sizeInMegabytes)) id \(String(describing: uuid))")
            return nil
        }
        
        return LockerRoomExternalDisk(
            id: uuid,
            name: name,
            bsdName: bsdName,
            sizeInMegabytes: sizeInMegabytes,
            volumes: volumeNames
        )
    }
}
