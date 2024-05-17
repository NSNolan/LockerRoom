//
//  LockerRoomXPCConnection.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/15/24.
//

import Foundation

import os.log

protocol LockerRoomXPCConnecting: NSXPCProxyCreating {
    var serviceName: String? { get }
    
    var exportedObject: Any? { get set }
    var exportedInterface: NSXPCInterface? { get set }
    var remoteObjectInterface: NSXPCInterface? { get set }
    
    func resume()
    func invalidate()
    
    func remoteObjectProxy() -> Any
    func remoteObjectProxyWithErrorHandler(_ handler: @escaping (Error) -> Void) -> Any
    func synchronousRemoteObjectProxyWithErrorHandler(_ handler: @escaping (Error) -> Void) -> Any
}

extension LockerRoomXPCConnecting {
    func remoteObjectProxy(retryCount: UInt, proxyHandler: @escaping (Result<Any, Error>) -> Void) {
        let proxy = remoteObjectProxyWithErrorHandler { error in
            Logger.utilities.error("Locker Room XPC connection failed for service \(String(describing: self.serviceName)) attempts remaining \(retryCount) with error \(error)")
            if retryCount > 0 {
                switch error {
                case CocoaError.xpcConnectionInterrupted: // Only interrupted errors should be retried.
                    self.remoteObjectProxy(retryCount: (retryCount - 1), proxyHandler: proxyHandler)
                default:
                    proxyHandler(.failure(error))
                }
            } else {
                proxyHandler(.failure(error))
            }
        }
        proxyHandler(.success(proxy))
    }
    
    func synchronousRemoteObjectProxy(retryCount: UInt, proxyHandler: @escaping (Result<Any, Error>) -> Void) {
        let proxy = synchronousRemoteObjectProxyWithErrorHandler { error in
            Logger.utilities.error("Locker Room XPC synchronous connection failed for service \(String(describing: self.serviceName)) attempts remaining \(retryCount) with error \(error)")
            if retryCount > 0 {
                switch error {
                case CocoaError.xpcConnectionInterrupted: // Only interrupted errors should be retried.
                    self.synchronousRemoteObjectProxy(retryCount: (retryCount - 1), proxyHandler: proxyHandler)
                default:
                    proxyHandler(.failure(error))
                }
            } else {
                proxyHandler(.failure(error))
            }
        }
        proxyHandler(.success(proxy))
    }
}

class LockerRoomXPCConnection: LockerRoomXPCConnecting {
    let connection: NSXPCConnection
    
    init(machServiceName: String, options: NSXPCConnection.Options = []) {
        connection = NSXPCConnection(machServiceName: machServiceName, options: options)
    }
    
    init(listenerEndpoint: NSXPCListenerEndpoint) {
        connection = NSXPCConnection(listenerEndpoint: listenerEndpoint)
    }
    
    var serviceName: String? {
        return connection.serviceName
    }
    
    var exportedObject: Any? {
        get {
            return connection.exportedObject
        }
        set {
            connection.exportedObject = newValue
        }
    }
    
    var exportedInterface: NSXPCInterface? {
        get {
            return connection.exportedInterface
        }
        set {
            connection.exportedInterface = newValue
        }
    }

    var remoteObjectInterface: NSXPCInterface? {
        get {
            return connection.remoteObjectInterface
        }
        set {
            connection.remoteObjectInterface = newValue
        }
    }

    func resume() {
        connection.resume()
    }
    
    func invalidate() {
        connection.invalidate()
    }
    
    func remoteObjectProxy() -> Any {
        connection.remoteObjectProxy
    }

    func remoteObjectProxyWithErrorHandler(_ handler: @escaping (Error) -> Void) -> Any {
        connection.remoteObjectProxyWithErrorHandler(handler)
    }
    
    func synchronousRemoteObjectProxyWithErrorHandler(_ handler: @escaping (Error) -> Void) -> Any {
        connection.synchronousRemoteObjectProxyWithErrorHandler(handler)
    }
}
