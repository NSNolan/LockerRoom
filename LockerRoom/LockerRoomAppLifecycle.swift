//
//  LockerRoomAppLifecycle.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/17/24.
//

import AppKit

import os.log

class LockerRoomAppLifecycle: NSObject, NSApplicationDelegate {
    static var externalDiskDiscovery: LockerRoomExternalDiskDiscovering? = nil
    static var remoteService: LockerRoomRemoteService? = nil
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        guard let externalDiskDiscovery = LockerRoomAppLifecycle.externalDiskDiscovery, externalDiskDiscovery.activate() else {
            Logger.lockerRoomUI.error("Locker room app lifecycle failed to activate external disk discovery")
            return
        }
        
        guard let remoteService = LockerRoomAppLifecycle.remoteService, remoteService.activate() else {
            Logger.lockerRoomUI.error("Locker room app lifecycle failed to activate remote service")
            return
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        guard let externalDiskDiscovery = LockerRoomAppLifecycle.externalDiskDiscovery, externalDiskDiscovery.invalidate() else {
            Logger.lockerRoomUI.error("Locker room app lifecycle failed to invalidate external disk discovery")
            return
        }
        
        guard let remoteService = LockerRoomAppLifecycle.remoteService, remoteService.invalidate() else {
            Logger.lockerRoomUI.error("Locker room app lifecycle failed to invalidate remote service")
            return
        }
    }
}
