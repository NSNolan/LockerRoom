//
//  LockerRoomLogger.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/12/24.
//

import Foundation

import os.log

extension OSLog {
    static let lockerRoomSubsystem = "com.nsnolan.LockerRoom"
}

extension Logger {
    static let cryptor = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "cryptor")
    static let localDisk = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "localDisk")
    static let lockerRoomUI = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "lockerRoomUI")
    static let manager = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "manager")
    static let persistence = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "persistence")
    static let utilities = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "utilities")
}
