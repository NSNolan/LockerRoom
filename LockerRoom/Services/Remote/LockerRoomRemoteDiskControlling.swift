//
//  LockerRoomRemoteDiskControlling.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/25/24.
//

import Foundation

@objc
protocol LockerRoomRemoteDiskControlling {
    func createDiskImage(name: String, size: Int, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void)
    func attachToDiskImage(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void)
    func detachFromDiskImage(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void)
    func openVolume(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void)
    func mountVolume(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void)
    func unmountVolume(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void)
    func verifyVolume(name: String, rootURL: URL, _ replyHandler: @escaping (Bool) -> Void)
}
