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
    static let diskController = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "diskContoller")
    static let externalDrive = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "externalDrive")
    static let lockerRoomUI = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "lockerRoomUI")
    static let manager = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "manager")
    static let persistence = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "persistence")
    static let service = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "service")
    static let utilities = Logger(subsystem: OSLog.lockerRoomSubsystem, category: "utilities")
}
