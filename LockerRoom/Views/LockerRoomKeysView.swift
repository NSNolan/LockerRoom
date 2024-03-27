//
//  LockerRoomKeysView.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/26/24.
//

import SwiftUI

import YubiKit

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
                    await enrollKey(keyConfiguration: keyConfiguration)
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
    
    private func enrollKey(keyConfiguration: LockerRoomKeyConfiguration) async -> (publicKey: SecKey, serialNumber: UInt32)?  {
        do {
            let connection = try await ConnectionHelper.anyWiredConnection()
            defer { Task { await closeConnection(connection: connection) } }
            do {
                let session = try await PIVSession.session(withConnection: connection)
                let defaultManagementKey = Data(hexEncodedString: "c4b4b9040f8e950063b8cbd21a972827d6f520b76d665ff2dad1e2703c7d63a8")!
                do {
                    let managementKeyMetadata = try await session.getManagementKeyMetadata()
                    do {
                        let managementKeyType = managementKeyMetadata.keyType
                        try await session.authenticateWith(managementKey: defaultManagementKey, keyType: managementKeyType)
                        do {
                            let publicKey = try await session.generateKeyInSlot(
                                slot: keyConfiguration.slot.pivSlot,
                                type: keyConfiguration.algorithm.pivKeyType,
                                pinPolicy: keyConfiguration.pinPolicy.pivPinPolicy,
                                touchPolicy: keyConfiguration.touchPolicy.pivTouchPolicy
                            )
                            print("[Default] Generated public key for slot \(keyConfiguration.slot.pivSlot.rawValue) with algorithm \(keyConfiguration.algorithm) pin policy \(keyConfiguration.pinPolicy) touch policy \(keyConfiguration.touchPolicy)")
                            do {
                                let serialNumber = try await session.getSerialNumber()
                                print("[Default] Serial number \(serialNumber) for key to be enrolled for slot \(keyConfiguration.slot.pivSlot.rawValue) with algorithm \(keyConfiguration.algorithm) pin policy \(keyConfiguration.pinPolicy) touch policy \(keyConfiguration.touchPolicy)")
                                return (publicKey, serialNumber)
                            } catch {
                                print("[Error] Failed to get serial number with error \(error) for slot \(keyConfiguration.slot.pivSlot.rawValue) with algorithm \(keyConfiguration.algorithm) pin policy \(keyConfiguration.pinPolicy) touch policy \(keyConfiguration.touchPolicy)")
                                return nil
                            }
                        } catch {
                            print("[Error] Failed to generate public key for slot \(keyConfiguration.slot.pivSlot.rawValue) with algorithm \(keyConfiguration.algorithm) pin policy \(keyConfiguration.pinPolicy) touch policy \(keyConfiguration.touchPolicy)")
                            return nil
                        }
                    } catch {
                        print("[Error] Failed to authenticate management key for slot \(keyConfiguration.slot.pivSlot.rawValue) with algorithm \(keyConfiguration.algorithm) pin policy \(keyConfiguration.pinPolicy) touch policy \(keyConfiguration.touchPolicy)")
                        return nil
                    }
                } catch {
                    print("[Error] Failed to get management key metadata for slot \(keyConfiguration.slot.pivSlot.rawValue) with algorithm \(keyConfiguration.algorithm) pin policy \(keyConfiguration.pinPolicy) touch policy \(keyConfiguration.touchPolicy)")
                    return nil
                }
            } catch {
                print("[Error] Failed to create PIV session from connection \(connection) with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Failed to find a wired connection with error \(error)")
            return nil
        }
    }
    
    private func closeConnection(connection: Connection) async -> Bool {
        if let error = await connection.connectionDidClose() {
            print("[Error] Lockbox key cryptor failed to close connection with error \(error)")
            return false
        } else {
            print("[Default] Lockbox key cryptor did close connection")
        }
        return true
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
