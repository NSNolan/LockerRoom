//
//  LockerRoomErrorView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 4/25/24.
//

import SwiftUI

struct LockerRoomErrorView: View {
    @Binding var showView: Bool
    @Binding var error: LockerRoomError?
    
    var body: some View {
        VStack(spacing: -12) {
            Image(systemName: "exclamationmark.triangle")
            
            Text("Locker Room Error")
                .bold()
                .padding()
            
            if let error {
                Text("\(error.nonLocalizedDescription)")
                    //.padding(.horizontal)
            }
        }
        
        Button("Close") {
            showView = false
        }
    }
}
