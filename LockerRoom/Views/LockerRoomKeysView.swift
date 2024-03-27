//
//  LockerRoomKeysView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import SwiftUI

enum LockerRoomKeysViewStyle {
    case main
    case enroll
    case waitingForKey
}

class LockerRoomKeyConfiguration: ObservableObject {
    @Published var name = ""
    @Published var slot = LockerRoom.LockerRoomKeyMetadata.Slot.cardAuthentication
    @Published var algorithm = LockerRoom.LockerRoomKeyMetadata.Algorithm.RSA2048
    @Published var pinPolicy = LockerRoom.LockerRoomKeyMetadata.PinPolicy.never
    @Published var touchPolicy = LockerRoom.LockerRoomKeyMetadata.TouchPolicy.never
}

struct LockerRoomKeysView: View {
    @Binding var showView: Bool
    
    @State var viewStyle: LockerRoomKeysViewStyle
    
    var body: some View {
        VStack {
            switch viewStyle {
            case .main:
                LockerRoomMainKeyView(showView: $showView, viewStyle: $viewStyle)
            case .enroll:
                LockerRoomEnrollKeyView(showView: $showView, viewStyle: $viewStyle)
            case .waitingForKey:
                LockerRoomWaitingForKeyView(showView: $showView, viewStyle: $viewStyle)
            }
        }
        .frame(width: 300)
        .padding()
    }
}

struct LockerRoomMainKeyView: View {
    @Binding var showView: Bool
    @Binding var viewStyle: LockerRoomKeysViewStyle
    
    var body: some View {
        VStack {
            Button("Enroll Key") {
                viewStyle = .enroll
            }
        }
    }
}

struct LockerRoomEnrollKeyView: View {
    @Binding var showView: Bool
    @Binding var viewStyle: LockerRoomKeysViewStyle
    
    @ObservedObject var keyConfiguration = LockerRoomKeyConfiguration()
    
    var body: some View {
        Text("Enroll a New Key")
            .padding()
        
        VStack {
            HStack {
                Text("Name")
                Spacer()
            }
            TextField("", text: $keyConfiguration.name)
        }
        
        VStack {
            HStack {
                Text("Slot")
                Spacer()
            }
            Picker("", selection: $keyConfiguration.slot) {
                ForEach(LockerRoom.LockerRoomKeyMetadata.Slot.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(alignment: .leading)
        }
        
        VStack {
            HStack {
                Text("Algorithm")
                Spacer()
            }
            Picker("", selection: $keyConfiguration.algorithm) {
                ForEach(LockerRoom.LockerRoomKeyMetadata.Algorithm.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        
        VStack {
            HStack {
                Text("Pin Policy")
                Spacer()
            }
            Picker("", selection: $keyConfiguration.pinPolicy) {
                ForEach(LockerRoom.LockerRoomKeyMetadata.PinPolicy.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        
        VStack {
            HStack {
                Text("Touch Policy")
                Spacer()
            }
            Picker("", selection: $keyConfiguration.touchPolicy) {
                ForEach(LockerRoom.LockerRoomKeyMetadata.TouchPolicy.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        
        HStack {
            Spacer()
            
            Button("Enroll") {
                viewStyle = .waitingForKey
                Task {
                    await enroll()
                    showView = false
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            
            Button("Close") {
                showView = false
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .padding()
    }
    
    private func enroll() async {
        guard let result = await LockboxKeyGenerator.generatePublicKeyDataFromDevice(
            slot:keyConfiguration.slot,
            algorithm: keyConfiguration.algorithm,
            pinPolicy: keyConfiguration.pinPolicy,
            touchPolicy: keyConfiguration.touchPolicy
        ) else {
            print("[Error] LockerRoom failed to generate public key from data with configuration: \(keyConfiguration)")
            return
        }
    }
}

struct LockerRoomWaitingForKeyView: View {
    @Binding var showView: Bool
    @Binding var viewStyle: LockerRoomKeysViewStyle
    
    var body: some View {
        Text("Insert YubiKit to Enroll")
            .padding()
        
        Spacer()
        
        ProgressView().progressViewStyle(CircularProgressViewStyle())
        
        Spacer()
        
        Button("Close") {
            showView = false
        }
        .padding()
    }
}
