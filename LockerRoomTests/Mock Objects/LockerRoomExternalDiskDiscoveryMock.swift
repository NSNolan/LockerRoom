//
//  LockerRoomExternalDiskDiscoveryMock.swift
//  LockerRoomTests
//
//  Created by Nolan Astrein on 5/27/24.
//

import Foundation

struct LockerRoomExternalDiskDiscoveryMock: LockerRoomExternalDiskDiscovering {
    var externalMediasByDeviceUnit = [Int:LockerRoomExternalMedia]()
    
    var failToActivate = false
    var failToInvalidate = false
    
    func activate() -> Bool {
        return !failToActivate
    }
    
    func invalidate() -> Bool {
        return !failToInvalidate
    }
}
