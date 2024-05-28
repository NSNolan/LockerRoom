//
//  LockboxCryptor.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 3/23/24.
//

import Foundation

import CryptoKit
import os.log

protocol LockboxCrypting {
    func encrypt(lockbox: UnencryptedLockbox, symmetricKeyData: Data) -> Bool
    func decrypt(lockbox: EncryptedLockbox, symmetricKeyData: Data) -> Bool
}

struct LockboxCryptor: LockboxCrypting {
    private static let chunkSize = 256 * 1024 // 256 KB
    
    func encrypt(lockbox: UnencryptedLockbox, symmetricKeyData: Data) -> Bool {
            return processLockbox(inputStream: lockbox.inputStream, outputStream: lockbox.outputStream, symmetricKeyData: symmetricKeyData, encrypt: true)
    }
    
    func decrypt(lockbox: EncryptedLockbox, symmetricKeyData: Data) -> Bool {
            return processLockbox(inputStream: lockbox.inputStream, outputStream: lockbox.outputStream, symmetricKeyData: symmetricKeyData, encrypt: false)
    }
    
    private func processLockbox(inputStream: InputStream, outputStream: OutputStream, symmetricKeyData: Data, encrypt: Bool) -> Bool {
        defer {
            inputStream.close()
            outputStream.close()
        }
        
        inputStream.open()
        guard inputStream.streamStatus == .open else {
            Logger.cryptor.error("Lockbox cryptor failed to open input stream with error \(inputStream.streamError)")
            return false
        }
        
        outputStream.open()
        guard outputStream.streamStatus == .open else {
            Logger.cryptor.error("Lockbox cryptor failed to open output stream with error \(outputStream.streamError)")
            return false
        }
        
        while inputStream.hasBytesAvailable {
            let bufferSize: Int
            if encrypt {
                bufferSize = Self.chunkSize
            } else {
                var chunkSizeBuffer = [UInt8](repeating: 0, count: 8)
                let chunkSizeBytesRead = inputStream.read(&chunkSizeBuffer, maxLength: 8)
                guard chunkSizeBytesRead > 0 else {
                    if chunkSizeBytesRead == 0 {
                        guard inputStream.streamStatus == .atEnd else {
                            Logger.cryptor.error("Lockbox cryptor read zero bytes without reaching EOF with stream status \(inputStream.streamStatus.rawValue) with error \(inputStream.streamError)")
                            return false
                        }
                        break
                    } else {
                        Logger.cryptor.error("Lockbox cryptor failed to read chunk size with error \(inputStream.streamError)")
                        return false
                    }
                }
                
                bufferSize = chunkSizeBuffer.withUnsafeBytes { $0.load(as: Int.self) }
            }
            
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
            guard bytesRead > 0 else {
                if bytesRead == 0 {
                    guard inputStream.streamStatus == .atEnd else {
                        Logger.cryptor.error("Lockbox cryptor read zero bytes without reaching EOF with stream status \(inputStream.streamStatus.rawValue) with error \(inputStream.streamError)")
                        return false
                    }
                    break
                } else {
                    Logger.cryptor.error("Lockbox cryptor failed to read with error \(inputStream.streamError)")
                    return false
                }
            }
            
            let chunk = Data(buffer[..<bytesRead])
            
            let processedData: Data
            if encrypt {
                guard let encryptedContent = self.encrypt(unencryptedContent: chunk, symmetricKeyData: symmetricKeyData) else {
                    Logger.cryptor.error("Lockbox cryptor failed to process unencrypted lockbox content")
                    return false
                }
                
                let length = Int64(encryptedContent.count)
                let lengthData = withUnsafeBytes(of: length) { Data($0) }
                
                processedData = lengthData + encryptedContent
            } else {
                guard let decryptedContent = self.decrypt(encryptedContent: chunk, symmetricKeyData: symmetricKeyData) else {
                    Logger.cryptor.error("Lockbox cryptor failed to process encrypted lockbox content")
                    return false
                }
                
                processedData = decryptedContent
            }
            
            var unsafeBytesWriteFailure = false
            processedData.withUnsafeBytes { rawBufferPointer in
                guard let baseAddress = rawBufferPointer.baseAddress else {
                    Logger.cryptor.error("Lockbox cryptor failed to get base address of the raw buffer")
                    unsafeBytesWriteFailure = true
                    return
                }
                
                var totalBytesWritten = 0
                let totalBytesToWrite = processedData.count
                while totalBytesWritten < totalBytesToWrite {
                    let remainingBytes = baseAddress.assumingMemoryBound(to: UInt8.self).advanced(by: totalBytesWritten)
                    let bytesWritten = outputStream.write(remainingBytes, maxLength: totalBytesToWrite - totalBytesWritten)
                    guard bytesWritten > 0 else {
                        Logger.cryptor.error("Lockbox cryptor failed to write with error \(outputStream.streamError)")
                        unsafeBytesWriteFailure = true
                        return
                    }
                    totalBytesWritten += bytesWritten
                }
            }
            
            if unsafeBytesWriteFailure {
                return false
            }
        }
        
        return true
    }
    
    private func encrypt(unencryptedContent: Data, symmetricKeyData: Data) -> Data? {
        let symmetricKey = SymmetricKey(data: symmetricKeyData)
        guard !unencryptedContent.isEmpty else {
            Logger.cryptor.error("Lockbox cryptor failed to read unencrypted lockbox content")
            return nil
        }
        
        do {
            guard let encryptedContent = try AES.GCM.seal(unencryptedContent, using: symmetricKey).combined else {
                Logger.cryptor.error("Lockbox cryptor failed to combine encrypted lockbox cipher text")
                return nil
                
            }
            Logger.cryptor.debug("Lockbox cryptor encrypted content \(encryptedContent)")
            return encryptedContent
        } catch {
            Logger.cryptor.error("Lockbox cryptor failed to encrypt lockbox content with error \(error)")
            return nil
        }
    }
    
    private func decrypt(encryptedContent: Data, symmetricKeyData: Data) -> Data? {
        let symmetricKey = SymmetricKey(data: symmetricKeyData)
        guard !encryptedContent.isEmpty else {
            Logger.cryptor.error("Lockbox cryptor failed to read encrypted lockbox content")
            return nil
        }
        
        do {
            let encryptedContentBox = try AES.GCM.SealedBox(combined: encryptedContent)
            do {
                let unencryptedContent = try AES.GCM.open(encryptedContentBox, using: symmetricKey)
                Logger.cryptor.debug("Lockbox cryptor decrypted content \(unencryptedContent)")
                return unencryptedContent
            } catch {
                Logger.cryptor.error("Lockbox cryptor failed to decrypt lockbox content with error \(error)")
                return nil
            }
        } catch {
            Logger.cryptor.error("Lockbox cryptor failed to seal encrypted lockbox content with error \(error)")
            return nil
        }
    }
}
