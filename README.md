# Locker Room

### Abstract

Locker Room is a macOS application to create, encrypt and decrypt personal lockboxes using a cryptographic key pair generated on an external hardware device. Locker Room is used to secure digital assets with physical hardware. YubiKey is currently the only supported external hardware device.

### How To Use

There are two top-level views in Locker Room: **Lockboxes** and **Keys**. These views can be toggled using the menu bar item in the top-right corner of the application. The **Lockboxes** view shows the list of created lockboxes:
![](Images/Locker-Room-Lockboxes.png)

And the **Keys** view shows the list of enrolled keys:
![](Images/Locker-Room-Keys.png)

While the **Lockboxes** view is selected, the plus button in the bottom-right corner will prompt the user to create a new lockbox:
![](Images/Locker-Room-Add-Lockbox.png)

And while the **Keys** view is selected, the same plus button will instead prompt the user to enroll a new key using an external hardware device:
![](Images/Locker-Room-Add-Key.png)

When a new lockbox is created it starts off unencrypted and a user can add files to it. The lock icon to the left of the lockbox name indicates whether or not it has been encrypted. A lockbox cannot be encrypted until at least one key has been enrolled using an external hardware device. Once a key is enrolled, the external hardware device's corresponding public key is stored on disk. The stored public key can then be used to encrypt lockboxes without the external hardware device present. By default, all enrolled key will be used when a lockbox is encrypted. Alternatively, a user can select specific enrolled keys to be used for encryption. Each encrypted lockbox in the **Lockboxes** view indicates which keys have been used for its encryption.

To enroll a key the user must first switch to the **Keys** view and then click the plus button. A key name and PIV slot must be provided when generating the public-private key pair on the external hardware device. Selecting "Show Advanced Options" will allow the user to specify the key algorithm, PIN policy, touch policy and PIV management key:
![](Images/Locker-Room-Add-Key-Advanced.png)

 After the key specifications are configured, Locker Room will wait for the external hardware device to become present. Once present the key enrollment process will complete. The resulting public key is stored on disk for future encryption and the private key always remains on the external hardware device for future decryption. Newly enrolled keys will not be used to retroactively encrypt previously encrypted lockboxes and therefore the corresponding external hardware device cannot be used to decrypt previously encrypted lockboxes.

A user can choose to encrypt a lockbox directly after it is created or they can choose to encrypt it later. Double-clicking an unencrypted lockbox from the list of lockboxes will prompt the user to encrypt it:
![](Images/Locker-Room-Encrypt-Lockbox.png)

Selecting "Show Key Selection" will allow the user to specify which keys to use instead of using all enrolled keys for encryption:
![](Images/Locker-Room-Encrypt-Lockbox-Key-Selection.png)

And double-clicking an encrypted lockbox will prompt the user to decrypt it:
![](Images/Locker-Room-Decrypt-Lockbox.png) 

Encryption does not require an external hardware device to be present because only previously enrolled keys are used. Decryption always requires an external hardware device to be present because the private key stored on the external hardware device is needed for decryption. After an encrypted lockbox is selected for decryption, Locker Room will wait for an external hardware device to become present. If the lockbox was encrypted using an enrolled key corresponding to the presented external hardware device then the decryption process will complete.

### Experimental Details

#### Cryptor Chunk Size

The lockbox encryption and decryption routines read data into memory in chunks. The default chunk size is 256 KB. Locker Room can be configured to use a chunk size up to 1 GB with the following command: 
```
defaults write ~/Library/Preferences/com.nsnolan.LockerRoom CryptorChunkSizeInBytes -int 1048576 // Sets chunk size to 1 MB.
```

#### Out-of-Process Disk Operations

Creating, attaching, detaching, mounting and unmounting a disk image using `hdiutil` from an app's main process is prevented when running in an [App Sandbox](https://developer.apple.com/documentation/security/app_sandbox). Locker Room can be configured to perform disk images operations outside of the app's main process with the following command:
```
$ defaults write ~/Library/Preferences/com.nsnolan.LockerRoom RemoteServiceEnabled -bool true
```

This command will instruct Locker Room to register a launch daemon to spawn on-demand when disk operations are requested. The launch daemon will only be registered while Locker Room is running. The launch daemon's registration state can be observed with the following command:
 ```
 $ launchctl print system/com.nsnolan.LockerRoomDaemon
 ```

However, macOS also prevents a launch daemon with an ad-hoc code signature from running when System Integrity Protection is enabled. Until the lauch daemon is signed with a developer certificate and provision profile, System Integrity Protection must be disabled from the RecoveryOS parition with the following command:
```
$ csrutil disable
```

Out-of-process disk operations are an incremental step towards running Locker Room inside of an App Sandbox. Locker Room will not enable App Sandboxing until the launch daemon is codesigned with a developer identity, provisioning profile and can be run without disabling System Integrity Protection. 

Logs that are emitted from the launch daemon will redact all dynamic variables. To install a profile that enables private logging run the following commands:
```
$ curl -L https://raw.githubusercontent.com/NSNolan/LockerRoom/main/Debug/EnablePrivateLogging.mobileconfig -o ~/Downloads/EnablePrivateLogging.mobileconfig
$ open ~/Downloads/EnablePrivateLogging.mobileconfig
```
*Be sure to complete the profile installation in System Settings > Privacy & Security > Profiles.*

#### Retired PIV Slots

The YubiKey SDK allows for using the following PIV slots: PIV Authentication (9a), Digital Signature (9c), Key Management (9d), Card Authentication (9e) and Attestation (f9). These slots have canonical usages and do not typically store a raw RSA or ECC private key for encryption and decryption. Even though there is no direct support via the YubiKey SDK, there does exists 20 retired key management slots (82-95) capable of storing a raw private key. So that a user does not have to reserve or misuse one of the supported PIV slots for a raw private key, Locker Room can be configured to allow a user to enroll a key using one of these unsupported PIV slots with the following command:
```
$ defaults write ~/Library/Preferences/com.nsnolan.LockerRoom ExperimentalPIVSlotsEnabled -bool true
```

Enrolling a key with an unsupported PIV slot is achieved by sending [ADPU commands](https://docs.yubico.com/yesdk/users-manual/yubikey-reference/apdu.html) directly to the external hardware device. This bypasses the limitations of the YubiKey SDK and encodes the unsupported slot into the command's raw data.

#### External Disk Discovery

An external disk device with a single APFS Container, containing one or more APFS Volumes, can be used as a lockbox. Locker Room can be configured to discover, encrypt and decrypt external disks with the followng command:
```
$ defaults write ~/Library/Preferences/com.nsnolan.LockerRoom ExternalDisksEnabled -bool true
```

While the **Lockboxes** view is selected and an external disk is connected, the plus button in the bottom-right corner will allow the user to create a new lockbox or a lockbox from a connected external disk.
![](Images/Locker-Room-Add-External-Lockbox.png)

A lockbox created from an external disk will indicate whether or not the corresponding external disk is currently present. When the corresponding external disk is present the icon is tinted green:
![](Images/Locker-Room-External-Lockbox-Present.png)

And when not present the icon is tinted red:
![](Images/Locker-Room-External-Lockbox-Missing.png)

A lockbox created from an external disk can only be encrypted and decrypted while it is present.

Out-of-Process disk operations must also be enabled using the User Defaults `RemoteServiceEnabled` to encrypt and decrypt an external disk. Accessing the external disk's APFS Container physical store for whole disk encryption requires root privileges.

### Technical Details

A lockbox is logically a disk image. While a lockbox is unencrypted the disk image can be attached and the contained volume can be mounted. While a lockbox is encrypted, the disk image cannot be accessed.

An enrolled key is logically a public key and serial number that maps to an external hardware device containing the corresponding private key. The type of public-private key pair is determined by the configuration details used when the key is enrolled.

An external lockbox is logically a connected disk device with one or more mountable APFS Volumes. While an external lockbox is unencrypted and present the associated disk device's volumes can be mounted. While the external lockbox is encrypted, the associated disk device's volumes cannot be accessed. External lockboxes only supports a disk device with a single APFS Container containing one or more mountable APFS Volumes. Locker Room accesses the external disk's APFS Container physical store via the filehandle that is exposed at `/dev/` while the disk device is connected.

#### Encryption

When a lockbox is encrypted, a 256-bit symmetric cryptographic key is generated. This symmetric key is used to encrypt the lockbox with the AES GCM algorithm. The lockbox content is streamed into memory in 256KB chunks and each chunk is independently encrypted with a nonce and authentication tag. The subsequent cipher text, nonce, authentication tag and total length of the prior three components are encoded into the output stream of the encrypted lockbox. 

The symmetric cryptographic key used to encrypt the lockbox is also encrypted by all of the enrolled keys using the algorithm specified during key enrollment. These encrpyted symmetrics keys are stored on disk along side the encrypted lockbox. If multiple keys are enrolled then multiple copies of the symmetric key are encrypted and stored on disk. But there is only ever one copy of the encrypted lockbox.

When a lockbox is created from an external disk, the symmetric key generation and encryption remains the same. But instead of the data encryption routine reading from a local file containing a disk image, it reads directly from the external disk and encrypts each chunk of data in-place. The GUID Partition Table for the device is kept in plaintext so that Locker Room can recognize the disk and associate it with the lockbox representation within the app. Since the entire external disk device is encrypted (aside from the GUID Partition Table) there is no free space to store a nonce, authentication tag and total length values for each encrypted chunk on the external disk itself. The encryption components are extracted by the encryption routine and serialized to the Locker Room app's storage for future decryption.

#### Decryption

When a lockbox is decrypted, the serial number of the presented external hardware device is used to map back to the corresponding encrypted symmetric key stored on disk. The private key stored on the external hardware device is then used to decrypt the matching encrypted symmetric key using the algorithm specified during key enrollment.

The now decrypted symmetric key is used to decrypt the encrypted lockbox with the AES GCM algorithm. The encrypted lockbox content is streamed into memory in chuncks, where the chunck size is read directly from the input stream and each chunk is independently decrypted with a nonce and authentication tag. After decryption, all symmetric cryptographic keys are thrown away and never used for future encryption.

When a lockbox is created from an external disk, the symmetric key decryption remains the same. But instead of the data decryption routine reading from a local file containing an encrypted disk image, it reads directly from the external disk and decrypts each chunk of data in-place. Since the GUID Partition Table is kept in plaintext, the encrypted disk is recognized by Locker Room and associated with the lockbox representation within the app. The decryption routine for external lockboxes requires the stored nonce, authentication tag and total length values for each encrypted chunk to be provide from the Locker Room app's storage.

### Known Issues

- Enrolling a key will overwrite an existing private key in the specified slot on the external hardware device.
- There is no way to enter a pin if the pin policy of the enrolled key is set to anything besides `Never`.
- Encryption and decryption of a lockbox created from an external disk are not fault tolerant.
- Locker Room app does not run in a sandbox.
- Locker Room app and launch daemon are not codesigned developer certificate and provisioning profile.
- Locker Room launch daemon has debugging entitlement `com.apple.security.get-task-allow`.
- There is no version check of the YubiKey before the YubiKey SDK is used.
- Encrypted lockboxes cannot be deleted within Locker Room but can be removed from the filesystem.
- Enrolled keys cannot be deleted within Locker Room but can be removed from the filesystem.
- An enrolled key's PIV management key should not be serialized to disk.

### Future Enhancements

- More unit tests coverage.
- Lockbox cryptor components extracted during external disk encryption are large and should not be stored in the lockbox metadata.
- Allow enrolled key deletion within Locker Room but only after there are no more encrypted lockbox it can decrypt. Keys can be removed using the filesystem and there is currently no way to remove the corresponding private key on the external hardware device. Yubico [changelogs](https://github.com/Yubico/yubico-piv-tool/blob/master/debian/changelog) suggests that YubiKey firmware 5.7.0 will add support for deleting keys.
- Add localization strings for the UI.
- Generate public-private key pair using elliptic curve cryptography. This is blocked by YubiKey's current support for RSA cipher text decryption only.

### Contact

NSNolan - latesonarinn@gmail.com
