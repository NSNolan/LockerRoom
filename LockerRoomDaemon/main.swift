//
//  main.swift
//  LockerRoomDaemon
//
//  Created by Nolan Astrein on 5/14/24.
//

import Foundation

import os.log

let daemon = LockerRoomDaemon()
daemon.run()
dispatchMain()

class LockerRoomDaemon: NSObject {
    private let listener = NSXPCListener(machServiceName: LockerRoomRemoteService.daemonServiceName)
    
    func run() {
        listener.delegate = self
        listener.resume()
    }
}

extension LockerRoomDaemon: NSXPCListenerDelegate {
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        guard let serviceName = newConnection.serviceName else {
            Logger.service.error("Locker room daemon received connection with missing service name")
            return false
        }
        
        Logger.service.log("Locker room daemon received connection for service name \(serviceName) from process \(newConnection.processIdentifier)")
        
        newConnection.exportedInterface = NSXPCInterface(with: LockerRoomDaemonInterface.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }
}

extension LockerRoomDaemon: LockerRoomDaemonInterface {
    func createDiskImage(name: String, size: Int,  rootURL: URL, _ replyHandler: @escaping (Bool) -> Void) {
        let lockerRoomURLProvider = LockerRoomURLProvider(rootURL: rootURL)
        let lockerRoomDiskController = LockerRoomDiskController(lockerRoomURLProvider: lockerRoomURLProvider)
        guard lockerRoomDiskController.create(name: name, size: size) else {
            replyHandler(false)
            return
        }
        
        guard let peerInfo = peerInfoForCurrentXPCConnection else {
            replyHandler(false)
            return
        }
        
        let uid = peerInfo.uid
        let gid = peerInfo.gid
        
        let lockboxesURL = lockerRoomURLProvider.urlForLockboxes
        let lockboxesPath = lockboxesURL.path(percentEncoded: false)
        guard changeOwner(path: lockboxesPath, uid: uid, gid: gid, recursive: false) else {
            replyHandler(false)
            return
        }
        
        let lockboxURL = lockerRoomURLProvider.urlForLockbox(name: name)
        let lockboxPath = lockboxURL.path(percentEncoded: false)
        guard changeOwner(path: lockboxPath, uid: uid, gid: gid, recursive: true) else {
            replyHandler(false)
            return
        }
        
        replyHandler(true)
    }
    
    func attachToDiskImage(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void) {
        let lockerRoomURLProvider = LockerRoomURLProvider(rootURL: rootURL)
        let lockerRoomDiskController = LockerRoomDiskController(lockerRoomURLProvider: lockerRoomURLProvider)
        guard lockerRoomDiskController.attach(name: name) else {
            replyHandler(false)
            return
        }
        
        replyHandler(true)
    }
    
    func detachFromDiskImage(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void) {
        let lockerRoomURLProvider = LockerRoomURLProvider(rootURL: rootURL)
        let lockerRoomDiskController = LockerRoomDiskController(lockerRoomURLProvider: lockerRoomURLProvider)
        guard lockerRoomDiskController.detach(name: name) else {
            replyHandler(false)
            return
        }
        
        replyHandler(true)
    }
    
    func mountVolume(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void) {
        let lockerRoomURLProvider = LockerRoomURLProvider(rootURL: rootURL)
        let lockerRoomDiskController = LockerRoomDiskController(lockerRoomURLProvider: lockerRoomURLProvider)
        guard lockerRoomDiskController.mount(name: name) else {
            replyHandler(false)
            return
        }
        
        replyHandler(true)
    }
    
    func unmountVolume(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void) {
        let lockerRoomURLProvider = LockerRoomURLProvider(rootURL: rootURL)
        let lockerRoomDiskController = LockerRoomDiskController(lockerRoomURLProvider: lockerRoomURLProvider)
        guard lockerRoomDiskController.unmount(name: name) else {
            replyHandler(false)
            return
        }
        
        replyHandler(true)
    }
    
    private var peerInfoForCurrentXPCConnection: (uid: uid_t, gid: gid_t)? {
        guard let currentConnection = NSXPCConnection.current() else {
            Logger.service.error("Locker room daemon failed to get current XPC connection")
            return nil
        }
        
        // TODO: Find a better way to extract the uid and gid of the remote XPC process.
        guard let connection = currentConnection.value(forKey: "_xpcConnection") else {
            Logger.service.error("Locker room daemon failed to get underlying XPC connection")
            return nil
        }
        
        guard let xpc_connection = connection as? xpc_connection_t else {
            Logger.service.error("Locker room daemon failed to cast XPC connection")
            return nil
        }
        
        let uid = xpc_connection_get_euid(xpc_connection)
        let gid = xpc_connection_get_egid(xpc_connection)
        
        return (uid, gid)
    }
    
    private func changeOwner(path: String, uid: uid_t, gid: gid_t, recursive: Bool) -> Bool {
        let fileManager = FileManager.default
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            Logger.service.error("Locker room daemon failed to change ownership at non-existing \(path) to uid \(uid) gid \(gid)")
            return false
        }
            
        guard chown(path, uid, gid) == 0 else {
            Logger.service.error("Locker room daemon failed to change ownership of \(path) to uid \(uid) gid \(gid)")
            return false
        }
        
        Logger.service.log("Locker room daemon changed ownership of \(path) to uid \(uid) gid \(gid)")
        
        guard recursive && isDirectory.boolValue else {
            return true
        }
        
        do {
            let subPaths = try fileManager.contentsOfDirectory(atPath: path)
            for subPath in subPaths {
                let fullPath = (path as NSString).appendingPathComponent(subPath)
                if !changeOwner(path: fullPath, uid: uid, gid: gid, recursive: recursive) {
                    return false
                }
            }
            return true
            
        } catch {
            Logger.service.error("Locker room daemon failed to get contents of directory at path \(path) with error \(error)")
            return false
        }
    }
}
