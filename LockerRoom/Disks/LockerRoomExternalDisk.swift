//
//  LockerRoomExternalDisk.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/21/24.
//

import Foundation

struct LockerRoomExternalDisk: Identifiable, Equatable {
    let id: UUID
    let name: String
    let bsdName: String
    let size: Int
}
