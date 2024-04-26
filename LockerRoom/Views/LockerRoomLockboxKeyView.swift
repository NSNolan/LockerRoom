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
    case error
}

private class LockerRoomLockboxKeyConfiguration: ObservableObject {
    @Published var name = ""
    @Published var slot = LockboxKey.Slot.pivAuthentication
    @Published var algorithm = LockboxKey.Algorithm.RSA2048
    @Published var pinPolicy = LockboxKey.PinPolicy.never
    @Published var touchPolicy = LockboxKey.TouchPolicy.never
    @Published var managementKeyString = "010203040506070801020304050607080102030405060708" // Default management key
}

struct LockerRoomLockboxKeyView: View {
    @Binding var showView: Bool
    
    @State var viewStyle: LockerRoomLockboxKeyViewStyle
    @State var error: LockerRoomError? = nil
    
    var body: some View {
        VStack {
            switch viewStyle {
            case .enroll:
                LockerRoomLockboxKeyEnrollView(showView: $showView, error: $error, viewStyle: $viewStyle)
            case .waitingForKey:
                LockerRoomLockboxKeyWaitingForKeyView(showView: $showView, viewStyle: $viewStyle)
            case .error:
                LockerRoomErrorView(showView: $showView, error: $error)
            }
        }
        .frame(width: 300)
        .padding()
    }
}

private struct LockerRoomLockboxKeyEnrollView: View {
    @Binding var showView: Bool
    @Binding var error: LockerRoomError?
    @Binding var viewStyle: LockerRoomLockboxKeyViewStyle
    
    @StateObject var keyConfiguration = LockerRoomLockboxKeyConfiguration()
    
    let lockerRoomManager = LockerRoomManager.shared
    
    var body: some View {
        Text("Enroll a New Key")
            .bold()
        
        VStack {
            HStack {
                Text("Name")
                Spacer()
            }
            TextField("", text: $keyConfiguration.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        VStack {
            HStack {
                Text("Slot")
                Spacer()
            }
            Picker("", selection: $keyConfiguration.slot) {
                ForEach(LockboxKey.Slot.allCases) { option in
                    Text(option.rawValue).tag(option)
                    if option == .attestation {
                        Divider() // Add divider to separate supported slots from experimental slots
                    }
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
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        
        HStack {
            Spacer()
            
            let enrollDisabled = (keyConfiguration.name.isEmpty || keyConfiguration.managementKeyString.isEmpty)
            
            Button("Enroll") {
                viewStyle = .waitingForKey
                Task {
                    guard await enroll() else {
                        error = .failedToCreateLockboxKey
                        viewStyle = .error
                        return
                    }
                    showView = false
                }
            }
            .disabled(enrollDisabled)
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .tint(.blue)
            
            Button("Close") {
                showView = false
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape)
        }
    }
    
    private func enroll() async -> Bool {
        let name = keyConfiguration.name
        let slot = keyConfiguration.slot
        let algorithm = keyConfiguration.algorithm
        let pinPolicy = keyConfiguration.pinPolicy
        let touchPolicy = keyConfiguration.touchPolicy
        let managementKeyString = keyConfiguration.managementKeyString
        
        guard await lockerRoomManager.addLockboxKey(
            name: name,
            slot: slot,
            algorithm: algorithm,
            pinPolicy: pinPolicy,
            touchPolicy: touchPolicy,
            managementKeyString: managementKeyString
        ) != nil else {
            print("[Error] LockerRoom failed to create a new lockbox key \(name) slot \(slot) algorithm \(algorithm) pin policy \(pinPolicy) touch policy \(touchPolicy) management key string \(managementKeyString)")
            return false
        }
        
        print("[Default] LockerRoom added a lockbox key \(name)")
        return true
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
