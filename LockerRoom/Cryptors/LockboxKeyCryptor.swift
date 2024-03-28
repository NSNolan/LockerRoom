//
//  LockboxKeyCryptor.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/21/24.
//

import Foundation

import YubiKit

struct LockboxKeyCryptor {
    static func encrypt(symmetricKey: Data) async -> Data? {
        do {
            let connection = try await ConnectionHelper.anyWiredConnection()
            defer { Task { await connection.close(error: nil) } }
            
            do {
                let session = try await PIVSession.session(withConnection: connection)
                do {
                    let certificate = try await session.getCertificateInSlot(.cardAuth) // TODO: Only using cardAuth slot to encrypt
                    guard let publicKey = SecCertificateCopyKey(certificate) else {
                        print("[Error] Lockbox key cryptor failed to copy public key from certificate \(certificate)")
                        return nil
                    }
                    
                    var error: Unmanaged<CFError>?
                    if let encryptedSymmetricKey = SecKeyCreateEncryptedData(publicKey, .rsaEncryptionOAEPSHA256, symmetricKey as CFData, &error) {
                        print("[Default] Lockbox key cryptor encrypted symmetric key \(encryptedSymmetricKey)")
                        return encryptedSymmetricKey as Data
                    } else if let error {
                        print("[Error] Lockbox key cryptor failed to encrypt symmetric key with error \(error)")
                        return nil
                    } else {
                        print("[Error] Lockbox key cryptor failed to encrypt symmetric key")
                        return nil
                    }
                } catch {
                    print("[Error] Lockbox key cryptor failed to get certificate from slot \(PIVSlot.keyManagement) with error \(error)")
                    return nil
                }
            } catch {
                print("[Error] Lockbox key cryptor failed to create PIV session from connection \(connection) with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Lockbox key cryptor failed to find a wired connection with error \(error)")
            return nil
        }
    }
    
    static func decrypt(encryptedSymmetricKey: Data) async -> Data? {
        do {
            let connection = try await ConnectionHelper.anyWiredConnection()
            defer { Task { await closeConnection(connection: connection) } }
            do {
                let session = try await PIVSession.session(withConnection: connection)
                do {
                    let decryptedSymmetricKey = try await session.decryptWithKeyInSlot(slot: .cardAuth, algorithm: .rsaEncryptionOAEPSHA256, encrypted: encryptedSymmetricKey) // TODO: Only using cardAuth slot to decrypt
                    print("[Default] Lockbox key cryptor decrypted symmetric key \(decryptedSymmetricKey)")
                    return decryptedSymmetricKey
                } catch {
                    print("[Error] Lockbox key cryptor failed to decrypt using slot \(PIVSlot.cardAuth) with error \(error)") // TODO: Update this log line from cardAuth being hardcoded
                    return nil
                }
                
            } catch {
                print("[Error] Lockbox key cryptor failed to create PIV session from connection \(connection) with error \(error)")
                return nil
            }
        } catch {
            print("[Error] Lockbox key cryptor failed to find a wired connection with error \(error)")
            return nil
        }
    }
    
    static private func closeConnection(connection: Connection) async -> Bool {
        if let error = await connection.connectionDidClose() {
            print("[Error] Lockbox key cryptor failed to close connection with error \(error)")
            return false
        }
        return true
    }
}
