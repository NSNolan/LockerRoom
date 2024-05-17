//
//  LockerRoomAppLifecycle.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/17/24.
//

import AppKit

import os.log

class LockerRoomAppLifecycle: NSObject, NSApplicationDelegate {
    static var service: LockerRoomService? = nil
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        guard let service = LockerRoomAppLifecycle.service, service.activate() else {
            Logger.lockerRoomUI.error("Locker room app lifecycle failed to activate service")
            return
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        guard let service = LockerRoomAppLifecycle.service, service.invalidate() else {
            Logger.lockerRoomUI.error("Locker room app lifecycle failed to invalidate service")
            return
        }
    }
}
