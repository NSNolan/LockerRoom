//
//  LockerRoomLockboxKeyView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import SwiftUI

import os.log

enum LockerRoomLockboxKeyViewStyle {
    case enroll
    case waitingForKey
    case error
}

struct LockerRoomLockboxKeyView: View {
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    
    @State var viewStyle: LockerRoomLockboxKeyViewStyle
    @State var error: LockerRoomError? = nil
    
    var body: some View {
        VStack {
            switch viewStyle {
            case .enroll:
                LockerRoomLockboxKeyEnrollView(lockerRoomManager: lockerRoomManager, showView: $showView, error: $error, viewStyle: $viewStyle)
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
    @Bindable var lockerRoomManager: LockerRoomManager
    
    @Binding var showView: Bool
    @Binding var error: LockerRoomError?
    @Binding var viewStyle: LockerRoomLockboxKeyViewStyle
    
    @State var advancedOptions = false
    @State var keyConfiguration = LockerRoomLockboxKeyConfiguration()
    
    var body: some View {
        Text("Enroll a New Key")
            .bold()
        
        VStack(alignment: .leading) {
            Text("Name")
            TextField("", text: $keyConfiguration.name.deduplicatedBinding)
                .padding(.leading, 8)
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
            .padding([.bottom, .top], 5)
            
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
            Logger.lockerRoomUI.error("LockerRoom failed to enroll lockbox key \(name) slot \(slot.rawValue) algorithm \(algorithm.rawValue) pin policy \(pinPolicy.rawValue) touch policy \(touchPolicy.rawValue)")
            return false
        }
        
        Logger.lockerRoomUI.log("LockerRoom added a lockbox key \(name)")
        return true
    }
}

private struct LockerRoomLockboxKeyEnrollAdvancedOptionsView: View {
    @Bindable var keyConfiguration: LockerRoomLockboxKeyConfiguration
    
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
            TextField("", text: $keyConfiguration.managementKeyString.deduplicatedBinding)
                .padding(.leading, 8)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct LockerRoomLockboxKeyWaitingForKeyView: View {
    @Binding var showView: Bool
    @Binding var viewStyle: LockerRoomLockboxKeyViewStyle
    
    var body: some View {
        Text("Insert Key to Enroll")
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
