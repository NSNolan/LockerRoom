//
//  LockerRoomEncryptionKeyIndicatorView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/26/24.
//

import SwiftUI

struct LockerRoomEncryptionKeyIndicatorView: View {
    let name: String
    
    var body: some View {
        Text(name)
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background(
                HStack {
                    Capsule()
                        .fill(.gray)
                }
            )
            .foregroundColor(.white)
    }
}
