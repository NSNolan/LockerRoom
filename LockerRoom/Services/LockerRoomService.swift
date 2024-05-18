//
//  LockerRoomService.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/14/24.
//

import Foundation

import os.log
import ServiceManagement

@objc
protocol LockerRoomDaemonInterface {
    func createDiskImage(name: String, size: Int, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void)
    func attachToDiskImage(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void)
    func detachFromDiskImage(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void)
}

struct LockerRoomService {
    static let daemonServiceName = "com.nsnolan.LockerRoomDaemon"
    static let daemonOptions = NSXPCConnection.Options.privileged
    
    private let service: SMAppService
    private let lockerRoomDefaults: LockerRoomDefaulting
    
    init(lockerRoomDefaults: LockerRoomDefaulting) {
        let plistName = LockerRoomService.daemonServiceName + ".plist"
        let daemon = SMAppService.daemon(plistName: plistName)
        service = daemon
        
        self.lockerRoomDefaults = lockerRoomDefaults
    }
    
    private var isEnabled: Bool {
        var enabled = false
        
        switch service.status {
        case .notRegistered:
            Logger.service.error("Locker room service is not registered")
        case .enabled:
            Logger.service.log("Locker room service is enabled")
            enabled = true
        case .requiresApproval:
            Logger.service.error("Locker room service requires approval")
        case .notFound:
            Logger.service.error("Locker room service is not found")
        @unknown default:
            Logger.service.error("Locker room service has unknown status")
        }
        
        return enabled
    }
    
    private var shouldEnable: Bool {
        return lockerRoomDefaults.serviceEnabled
    }
    
    private var daemonConnection: LockerRoomXPCConnecting {
        let connection = underlyingConnection(LockerRoomService.daemonServiceName, LockerRoomService.daemonOptions)
        connection.exportedObject = nil
        connection.exportedInterface = nil
        connection.remoteObjectInterface = NSXPCInterface(with: LockerRoomDaemonInterface.self)
        connection.resume()
        return connection
    }
    
    internal var underlyingConnection: (String, NSXPCConnection.Options) -> LockerRoomXPCConnecting = { (serviceName, options) in
        return LockerRoomXPCConnection(machServiceName: serviceName, options: options)
    }
    
    func activate() -> Bool {
        guard !isEnabled && shouldEnable else {
            return true
        }
        
        var activated = false
        do {
            try service.register()
            activated = true
            Logger.service.log("Locker room service activated")
        } catch let error as NSError {
            Logger.service.error("Locker room service failed to activate with error \(error)")
        } catch {
            Logger.service.error("Locker room service failed to activate with unknown error \(error)")
        }
        
        return activated
    }
    
    func invalidate() -> Bool {
        guard isEnabled else {
            return true
        }
        
        var invalidated = false
        do {
            try service.unregister()
            invalidated = true
            Logger.service.log("Locker room service invalidated")
        } catch let error as NSError {
            Logger.service.error("Locker room service failed to invalidate with error \(error)")
        } catch {
            Logger.service.error("Locker room service failed to invalidate with unknown error \(error)")
        }
        
        return invalidated
    }
}

extension LockerRoomService {
    func createDiskImage(name: String, size: Int, rootURL: URL) -> Bool {
        guard isEnabled else {
            return false
        }
        
        Logger.service.log("Locker room service creating disk image \(name) size \(size)MB rootURL \(rootURL)")
        
        var success = false
        daemonConnection.synchronousRemoteObjectProxy(retryCount: 3) { proxyResult in
            switch proxyResult {
            case .success(let proxy):
                guard let daemon = proxy as? LockerRoomDaemonInterface else {
                    Logger.service.fault("Locker room service failed to cast proxy object")
                    return
                }
                daemon.createDiskImage(name: name, size: size, rootURL: rootURL) { createResult in
                    success = createResult
                }
                
            case .failure(let error):
                Logger.service.error("Locker room service failed to create disk image \(name) with error \(error)")
            }
        }
        return success
    }
    
    func attachToDiskImage(name: String, rootURL: URL) -> Bool {
        guard isEnabled else {
            return false
        }
        
        Logger.service.log("Locker room service attaching to disk image \(name) rootURL \(rootURL)")
        
        var success = false
        daemonConnection.synchronousRemoteObjectProxy(retryCount: 3) { proxyResult in
            switch proxyResult {
            case .success(let proxy):
                guard let daemon = proxy as? LockerRoomDaemonInterface else {
                    Logger.service.fault("Locker room service failed to cast proxy object")
                    return
                }
                daemon.attachToDiskImage(name: name, rootURL: rootURL) { attachResult in
                    success = attachResult
                }
                
            case .failure(let error):
                Logger.service.error("Locker room service failed to attach to disk image \(name) with error \(error)")
            }
        }
        return success
    }
    
    func detachFromDiskImage(name: String, rootURL: URL) -> Bool {
        guard isEnabled else {
            return false
        }
        
        Logger.service.log("Locker room service detaching from disk image \(name) rootURL \(rootURL)")
        
        var success = false
        daemonConnection.synchronousRemoteObjectProxy(retryCount: 3) { proxyResult in
            switch proxyResult {
            case .success(let proxy):
                guard let daemon = proxy as? LockerRoomDaemonInterface else {
                    Logger.service.fault("Locker room service failed to cast proxy object")
                    return
                }
                daemon.detachFromDiskImage(name: name, rootURL: rootURL) { detachResult in
                    success = detachResult
                }
                
            case .failure(let error):
                Logger.service.error("Locker room service failed to detach from disk image \(name) with error \(error)")
            }
        }
        return success
    }
}
