//
//  LockboxMetadata.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/30/24.
//

import Foundation

protocol LockboxMetadata: Codable, CustomStringConvertible {
    var id: UUID { get }
    var name: String { get }
    var size: Int { get }
    var isEncrypted: Bool { get }
    var isExternal: Bool { get }
}
