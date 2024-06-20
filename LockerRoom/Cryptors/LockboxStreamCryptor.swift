//
//  LockboxStreamCryptor.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 5/28/24.
//

import Foundation

import CryptoKit
import os.log

typealias LockboxCryptorComponents = [[String:Data]]

protocol LockboxStreamCrypting {
    func encrypt(inputStream: InputStream, outputStream: OutputStream, symmetricKeyData: Data) -> Bool
    func decrypt(inputStream: InputStream, outputStream: OutputStream, symmetricKeyData: Data) -> Bool    
    func encryptExtractingComponents(inputStream: InputStream, outputStream: OutputStream, symmetricKeyData: Data) -> LockboxCryptorComponents?
    func decryptWithComponents(inputStream: InputStream, outputStream: OutputStream, symmetricKeyData: Data, components: LockboxCryptorComponents) -> Bool
}

struct LockboxStreamCryptor: LockboxStreamCrypting {
    private static let chunkSize = 256 * 1024 // 256 KB
    private static let chunkSizeBufferSize = 8
    
    private static let authTagKey = "AuthTag"
    private static let nonceDataKey = "NonceData"
    private static let ciphertextSizeDataKey = "CiphertextSizeData"
    
    func encrypt(inputStream: InputStream, outputStream: OutputStream, symmetricKeyData: Data) -> Bool {
        return processLockbox(inputStream: inputStream, outputStream: outputStream, symmetricKeyData: symmetricKeyData, encrypt: true)
    }
    
    func decrypt(inputStream: InputStream, outputStream: OutputStream, symmetricKeyData: Data) -> Bool {
        return processLockbox(inputStream: inputStream, outputStream: outputStream, symmetricKeyData: symmetricKeyData, encrypt: false)
    }
    
    func encryptExtractingComponents(inputStream: InputStream, outputStream: OutputStream, symmetricKeyData: Data) -> LockboxCryptorComponents? {
        defer {
            inputStream.close()
            outputStream.close()
        }
        
        guard openStreams(inputStream: inputStream, outputStream: outputStream) else {
            return nil
        }
        
        var components = LockboxCryptorComponents()
        
        while inputStream.hasBytesAvailable {
            var buffer = [UInt8](repeating: 0, count: Self.chunkSize)
            
            let bytesRead = read(inputStream: inputStream, buffer: &buffer)
            guard bytesRead >= 0 else {
                return nil
            }
            
            guard bytesRead > 0 else {
                break
            }
            
            let plaintextChunk = Data(buffer[..<bytesRead])
            
            guard let encryptionResult = self.encryptExtractingComponents(plaintext: plaintextChunk, symmetricKeyData: symmetricKeyData) else {
                return nil
            }
            
            let authTag = encryptionResult.authTag
            let nonceData = encryptionResult.nonceData
            let ciphertext = encryptionResult.ciphertext
            let ciphertextSize = ciphertext.count
            let ciphertextSizeData = withUnsafeBytes(of: ciphertextSize) { Data($0) }
            let componentsEntry = [
                Self.authTagKey: authTag,
                Self.ciphertextSizeDataKey: ciphertextSizeData,
                Self.nonceDataKey: nonceData
            ]
            components.append(componentsEntry)
            
            guard write(outputStream: outputStream, data: ciphertext) else {
                return nil
            }
        }
        
        return components
    }
    
    func decryptWithComponents(inputStream: InputStream, outputStream: OutputStream, symmetricKeyData: Data, components: LockboxCryptorComponents) -> Bool {
        defer {
            inputStream.close()
            outputStream.close()
        }
        
        guard openStreams(inputStream: inputStream, outputStream: outputStream) else {
            return false
        }
        
        var componentsIndex = 0
        
        while componentsIndex < components.count {
            let componentsEntry = components[componentsIndex]
            
            guard let authTag = componentsEntry[Self.authTagKey],
                  let ciphertextSizeData = componentsEntry[Self.ciphertextSizeDataKey],
                  let nonceData = componentsEntry[Self.nonceDataKey] else {
                Logger.cryptor.error("Lockbox stream cryptor failed to find required data from components \(componentsEntry)")
                return false
            }
            
            let bufferSize = ciphertextSizeData.withUnsafeBytes { $0.load(as: Int.self) }
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            let bytesRead = read(inputStream: inputStream, buffer: &buffer)
            
            guard bytesRead >= 0 else {
                return false
            }
            
            guard bytesRead > 0 else {
                break
            }
            
            let ciphertextChunk = Data(buffer[..<bytesRead])
            
            guard let plaintext = self.decryptWithComponents(authTag: authTag, ciphertext: ciphertextChunk, nonceData: nonceData, symmetricKeyData: symmetricKeyData) else {
                return false
            }
            
            guard write(outputStream: outputStream, data: plaintext) else {
                return false
            }
            
            componentsIndex += 1
        }
        
        return true
    }
    
    private func openStreams(inputStream: InputStream, outputStream: OutputStream) -> Bool {
        inputStream.open()
        if inputStream.streamStatus != .open {
            Logger.cryptor.error("Lockbox stream cryptor failed to open input stream with error \(inputStream.streamError)")
            return false
        }
        
        outputStream.open()
        if outputStream.streamStatus != .open {
            Logger.cryptor.error("Lockbox stream cryptor failed to open output stream with error \(outputStream.streamError)")
            return false
        }
        
        return true
    }
    
    private func read(inputStream: InputStream, buffer: inout [UInt8]) -> Int {
        let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
        guard bytesRead > 0 else {
            if bytesRead == 0 {
                if inputStream.streamStatus != .atEnd {
                    Logger.cryptor.error("Lockbox stream cryptor read zero bytes without reaching EOF with stream status \(inputStream.streamStatus.rawValue) with error \(inputStream.streamError)")
                    return -1
                }
                Logger.cryptor.debug("Lockbox stream cryptor input stream ended")
                return 0
            } else {
                Logger.cryptor.error("Lockbox stream cryptor failed to read with error \(inputStream.streamError)")
                return -1
            }
        }
        return bytesRead
    }
    
    private func write(outputStream: OutputStream, data: Data) -> Bool {
        var success = true
        data.withUnsafeBytes { rawBufferPointer in
            guard let baseAddress = rawBufferPointer.baseAddress else {
                Logger.cryptor.error("Lockbox stream cryptor failed to get base address of the raw buffer")
                success = false
                return
            }
            
            var totalBytesWritten = 0
            let totalBytesToWrite = data.count
            while totalBytesWritten < totalBytesToWrite {
                let remainingBytes = baseAddress.assumingMemoryBound(to: UInt8.self).advanced(by: totalBytesWritten)
                let bytesWritten = outputStream.write(remainingBytes, maxLength: totalBytesToWrite - totalBytesWritten)
                guard bytesWritten > 0 else {
                    Logger.cryptor.error("Lockbox stream cryptor failed to write with error \(outputStream.streamError)")
                    success = false
                    return
                }
                totalBytesWritten += bytesWritten
            }
        }
        return success
    }
    
    private func processLockbox(inputStream: InputStream, outputStream: OutputStream, symmetricKeyData: Data, encrypt: Bool) -> Bool {
        defer {
            inputStream.close()
            outputStream.close()
        }
        
        guard openStreams(inputStream: inputStream, outputStream: outputStream) else {
            return false
        }
        
        while inputStream.hasBytesAvailable {
            let bufferSize: Int
            if encrypt {
                bufferSize = Self.chunkSize
            } else {
                var chunkSizeBuffer = [UInt8](repeating: 0, count: Self.chunkSizeBufferSize)
                let chunkSizeBytesRead = read(inputStream: inputStream, buffer: &chunkSizeBuffer)
                
                guard chunkSizeBytesRead >= 0 else {
                    return false
                }
                
                guard chunkSizeBytesRead > 0 else {
                    break
                }
                
                guard chunkSizeBytesRead == Self.chunkSizeBufferSize else {
                    let missingBytes = Self.chunkSizeBufferSize - chunkSizeBytesRead
                    Logger.cryptor.error("Lockbox stream cryptor failed to read entire chunk size missing \(missingBytes) bytes")
                    return false
                }
                
                bufferSize = chunkSizeBuffer.withUnsafeBytes { $0.load(as: Int.self) }
            }
            
            var buffer = [UInt8](repeating: 0, count: bufferSize)
            let bytesRead = read(inputStream: inputStream, buffer: &buffer)
            
            guard bytesRead >= 0 else {
                return false
            }
            
            guard bytesRead > 0 else {
                break
            }
            
            let chunk = Data(buffer[..<bytesRead])
            
            let processedData: Data
            if encrypt {
                guard let encryptedContent = self.encrypt(plaintext: chunk, symmetricKeyData: symmetricKeyData) else {
                    return false
                }
                
                let encryptedContentSize = Int64(encryptedContent.count)
                let encryptedContentSizeData = withUnsafeBytes(of: encryptedContentSize) { Data($0) }
                
                processedData = encryptedContentSizeData + encryptedContent
            } else {
                guard let decryptedContent = self.decrypt(combinedCipherOutput: chunk, symmetricKeyData: symmetricKeyData) else {
                    return false
                }
                
                processedData = decryptedContent
            }
            
            guard write(outputStream: outputStream, data: processedData) else {
                return false
            }
        }
        
        return true
    }
    
    private func encrypt(plaintext: Data, symmetricKeyData: Data) -> Data? {
        guard !plaintext.isEmpty else {
            Logger.cryptor.error("Lockbox stream cryptor failed to read plaintext")
            return nil
        }
        
        do {
            let symmetricKey = SymmetricKey(data: symmetricKeyData)
            guard let combinedCipherComponents = try AES.GCM.seal(plaintext, using: symmetricKey).combined else {
                Logger.cryptor.error("Lockbox stream cryptor failed to combine cipher components")
                return nil
                
            }
            Logger.cryptor.debug("Lockbox stream cryptor encrypted plaintext \(plaintext) to combined cipher components \(combinedCipherComponents)")
            return combinedCipherComponents
        } catch {
            Logger.cryptor.error("Lockbox stream cryptor failed to encrypt plaintext \(plaintext) with error \(error)")
            return nil
        }
    }
    
    private func decrypt(combinedCipherOutput: Data, symmetricKeyData: Data) -> Data? {
        guard !combinedCipherOutput.isEmpty else {
            Logger.cryptor.error("Lockbox stream cryptor failed to read combined cipher output")
            return nil
        }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: combinedCipherOutput)
            do {
                let symmetricKey = SymmetricKey(data: symmetricKeyData)
                let plaintext = try AES.GCM.open(sealedBox, using: symmetricKey)
                Logger.cryptor.debug("Lockbox stream cryptor decrypted combined cipher output \(combinedCipherOutput) to plaintext \(plaintext)")
                return plaintext
            } catch {
                Logger.cryptor.error("Lockbox stream cryptor failed to open sealed box with error \(error)")
                return nil
            }
        } catch {
            Logger.cryptor.error("Lockbox stream cryptor failed to create sealed box from combined cipher output \(combinedCipherOutput) with \(error)")
            return nil
        }
    }
    
    private func encryptExtractingComponents(plaintext: Data, symmetricKeyData: Data) -> (authTag: Data, ciphertext: Data, nonceData: Data)? {
        guard !plaintext.isEmpty else {
            Logger.cryptor.error("Lockbox stream cryptor failed to read plaintext")
            return nil
        }
        
        do {
            let symmetricKey = SymmetricKey(data: symmetricKeyData)
            let sealedBox = try AES.GCM.seal(plaintext, using: symmetricKey)

            let authTag = sealedBox.tag
            let ciphertext = sealedBox.ciphertext
            let nonceData = sealedBox.nonce.withUnsafeBytes { Data($0) }
            
            Logger.cryptor.debug("Lockbox stream cryptor encrypted plaintext \(plaintext) to ciphertext \(ciphertext) with auth tag \(authTag) nonce data \(nonceData)")
            return (authTag, ciphertext, nonceData)
        } catch {
            Logger.cryptor.error("Lockbox stream cryptor failed to seal plaintext \(plaintext) with error \(error)")
            return nil
        }
    }
    
    private func decryptWithComponents(authTag: Data, ciphertext: Data, nonceData: Data, symmetricKeyData: Data) -> Data? {
        guard !authTag.isEmpty else {
            Logger.cryptor.error("Lockbox stream cryptor failed to read auth tag")
            return nil
        }
        
        guard !ciphertext.isEmpty else {
            Logger.cryptor.error("Lockbox stream cryptor failed to read ciphertext")
            return nil
        }
        
        guard !nonceData.isEmpty else {
            Logger.cryptor.error("Lockbox stream cryptor failed to read nonce data")
            return nil
        }
        
        do {
            let nonce = try AES.GCM.Nonce(data: nonceData)
            do {
                let symmetricKey = SymmetricKey(data: symmetricKeyData)
                let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: authTag)
                do {
                    let plaintext = try AES.GCM.open(sealedBox, using: symmetricKey)
                    Logger.cryptor.debug("Lockbox stream cryptor decrypted ciphertext \(ciphertext) to plaintext \(plaintext) with auth tag \(authTag) nonce data \(nonceData)")
                    return plaintext
                } catch {
                    Logger.cryptor.error("Lockbox stream cryptor failed to open sealed box with auth tag \(authTag) nonce data \(nonceData) error \(error)")
                    return nil
                }
            } catch {
                Logger.cryptor.error("Lockbox stream cryptor failed to create sealed box from ciphertext \(ciphertext) with auth tag \(authTag) nonce data \(nonceData) with error \(error)")
                return nil
            }
        } catch {
            Logger.cryptor.error("Lockbox stream cryptor failed to create nonce from data \(nonceData) with error \(error)")
            return nil
        }
    }
}
