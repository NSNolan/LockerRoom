//
//  LockerRoomLockboxKeyView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import SwiftUI

enum LockerRoomLockboxKeyViewStyle {
    case enroll
    case waitingForKey
}

private class LockerRoomLockboxKeyConfiguration: ObservableObject {
    @Published var name = ""
    @Published var slot = LockboxKey.Slot.cardAuthentication
    @Published var algorithm = LockboxKey.Algorithm.RSA2048
    @Published var pinPolicy = LockboxKey.PinPolicy.never
    @Published var touchPolicy = LockboxKey.TouchPolicy.never
    @Published var managementKeyString = "c4b4b9040f8e950063b8cbd21a972827d6f520b76d665ff2dad1e2703c7d63a8" // TODO: Update to default management key 010203040506070801020304050607080102030405060708
}

struct LockerRoomLockboxKeyView: View {
    @Binding var showView: Bool
    
    @State var viewStyle: LockerRoomLockboxKeyViewStyle
    
    var body: some View {
        VStack {
            switch viewStyle {
            case .enroll:
                LockerRoomLockboxKeyEnrollView(showView: $showView, viewStyle: $viewStyle)
            case .waitingForKey:
                LockerRoomLockboxKeyWaitingForKeyView(showView: $showView, viewStyle: $viewStyle)
            }
        }
        .frame(width: 300)
        .padding()
    }
}

private struct LockerRoomLockboxKeyEnrollView: View {
    @Binding var showView: Bool
    @Binding var viewStyle: LockerRoomLockboxKeyViewStyle
    
    @StateObject var keyConfiguration = LockerRoomLockboxKeyConfiguration()
    
    let lockerRoomManager = LockerRoomManager.shared
    
    var body: some View {
        Text("Enroll a New Key")
        
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
                ForEach(LockboxKey.Slot.allCases) { option in
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
                ForEach(LockboxKey.Algorithm.allCases) { option in
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
                ForEach(LockboxKey.PinPolicy.allCases) { option in
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
                ForEach(LockboxKey.TouchPolicy.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        
        VStack {
            HStack {
                Text("PIV Management Key")
                Spacer()
            }
            TextField("", text: $keyConfiguration.managementKeyString)
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
    }
    
    private func enroll() async {
        let name = keyConfiguration.name
        let slot = keyConfiguration.slot
        let algorithm = keyConfiguration.algorithm
        let pinPolicy = keyConfiguration.pinPolicy
        let touchPolicy = keyConfiguration.touchPolicy
        let managementKeyString = keyConfiguration.managementKeyString
        
        guard let result = await LockboxKeyGenerator.generatePublicKeyDataFromDevice(
            slot: slot,
            algorithm: algorithm,
            pinPolicy: pinPolicy,
            touchPolicy: touchPolicy,
            managementKeyString: managementKeyString
        ) else {
            print("[Error] LockerRoom failed to generate public key from data with configuration: \(keyConfiguration)")
            return
        }
        
        let publicKey = result.publicKey
        let serialNumber = result.serialNumber
        
        guard lockerRoomManager.addLockboxKey(
            name: name,
            serialNumber: serialNumber,
            slot: slot,
            algorithm: algorithm,
            pinPolicy: pinPolicy,
            touchPolicy: touchPolicy,
            managementKeyString: managementKeyString,
            publicKey: publicKey
        ) != nil else {
            print("[Error] LockerRoom failed to create a new lockbox key \(name) serial number \(serialNumber) slot \(slot) algorithm \(algorithm) pin policy \(pinPolicy) touch policy \(touchPolicy) management key string \(managementKeyString) public key \(publicKey)")
            return
        }
        
        print("[Default] LockerRoom added a lockbox key \(name)")
    }
}

private struct LockerRoomLockboxKeyWaitingForKeyView: View {
    @Binding var showView: Bool
    @Binding var viewStyle: LockerRoomLockboxKeyViewStyle
    
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
