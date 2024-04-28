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
    
    @ObservedObject var lockerRoomManager: LockerRoomManager
    
    @State var viewStyle: LockerRoomLockboxKeyViewStyle
    @State var error: LockerRoomError? = nil
    
    var body: some View {
        VStack {
            switch viewStyle {
            case .enroll:
                LockerRoomLockboxKeyEnrollView(showView: $showView, error: $error, viewStyle: $viewStyle, lockerRoomManager: lockerRoomManager)
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
    
    @ObservedObject var lockerRoomManager: LockerRoomManager
    
    @State private var advancedOptions = false
    
    @StateObject var keyConfiguration = LockerRoomLockboxKeyConfiguration()
    
    var body: some View {
        Text("Enroll a New Key")
            .bold()
        
        VStack(alignment: .leading) {
            Text("Name")
            TextField("", text: $keyConfiguration.name)
                .textFieldStyle(.roundedBorder)
            
            Text("Slot")
            Picker("", selection: $keyConfiguration.slot) {
                ForEach(LockboxKey.Slot.allCases) { slot in
                    Text(slot.rawValue).tag(slot)
                    if slot == .attestation {
                        Divider() // Add divider to separate supported slots from experimental slots
                    }
                }
            }
            .pickerStyle(.menu)
        }
        
        if advancedOptions {
            LockerRoomLockboxKeyEnrollAdvancedOptionsView(keyConfiguration: keyConfiguration)
        }
        
        VStack {
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
                .buttonStyle(.borderedProminent)
                .disabled(enrollDisabled)
                .keyboardShortcut(.defaultAction)
                .tint(.blue)
                
                Button("Close") {
                    showView = false
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)
            }
            .padding(.top)
            
            Button(action: {
                withAnimation {
                    advancedOptions.toggle()
                }
            }) {
                if advancedOptions {
                    Image(systemName: "chevron.up")
                    Text("Hide Advanced Options")
                } else {
                    Text("Show Advanced Options")
                    Image(systemName: "chevron.down")
                }
            }
            .buttonStyle(BorderlessButtonStyle())
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

private struct LockerRoomLockboxKeyEnrollAdvancedOptionsView: View {
    @ObservedObject var keyConfiguration = LockerRoomLockboxKeyConfiguration()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Algorithm")
            Picker("", selection: $keyConfiguration.algorithm) {
                ForEach(LockboxKey.Algorithm.allCases) { algorithm in
                    Text(algorithm.rawValue).tag(algorithm)
                }
            }
            .pickerStyle(.segmented)
        
            Text("Pin Policy")
            Picker("", selection: $keyConfiguration.pinPolicy) {
                ForEach(LockboxKey.PinPolicy.allCases) { pinPolicy in
                    Text(pinPolicy.rawValue).tag(pinPolicy)
                }
            }
            .pickerStyle(.segmented)
            
            Text("Touch Policy")
            Picker("", selection: $keyConfiguration.touchPolicy) {
                ForEach(LockboxKey.TouchPolicy.allCases) { touchPolicy in
                    Text(touchPolicy.rawValue).tag(touchPolicy)
                }
            }
            .pickerStyle(.segmented)

            Text("PIV Management Key")
            TextField("", text: $keyConfiguration.managementKeyString)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct LockerRoomLockboxKeyWaitingForKeyView: View {
    @Binding var showView: Bool
    @Binding var viewStyle: LockerRoomLockboxKeyViewStyle
    
    var body: some View {
        Text("Insert YubiKit to Enroll")
            .padding()
        
        Spacer()
        
        ProgressView().progressViewStyle(.circular)
        
        Spacer()
        
        Button("Close") {
            showView = false
        }
        .padding()
    }
}
