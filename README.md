# Locker Room

### Abstract

Locker Room is a macOS application to create, encrypt and decrypt local disk images using a public-private key pair generated on an external hardware device. Locker Room is used to secure digital assets with physical hardware. YubiKey is currently the only supported external hardware device.

### How To Use

There are two top-level views in Locker Room: **Lockboxes** and **Keys**. These views can be toggled using the menu bar item in the top-right corner of the application. The **Lockboxes** view shows a list of created lockboxes.
![](Images/Locker-Room-Lockboxes.png)

And the **Keys** view shows a list of enroll keys.
![](Images/Locker-Room-Keys.png)

When the **Lockboxes** view is selected, the plus button in the bottom-right corner will prompt the user to add a new lockbox.
![](Images/Locker-Room-Add-Lockbox.png)

And when on the **Keys** view is selected, the same plus button will instead prompt the user to enroll a new key using an external hardware device.
![](Images/Locker-Room-Add-Key.png)

When a new lockbox is created it starts off unencrypted and a user can add files to it. There is a lock icon to the left of lockbox name indicating whether or not it has been encrypted. A lockbox cannot be encrypted until at least one key has been enrolled using an external hardware device. Once a key is enrolled the hardware device's corresponding public key is stored. The stored public key can then be used to encrypt lockboxes without the external hardware device present. Every currently enrolled key will be used when a lockbox is encrypted. Keys enrolled after a lockbox has been encrypted will not be used to retroactively encrypt previously encrypted lockboxes and therefore the corresponding external hardware device cannot be used to decrypt previously encrypted lockboxes.

To enroll a key the user must first switch to the **Keys** view and then click on the plus button. A key name, PIV slot, algorithm, PIN policy, touch policy and the PIV management key must be provided when generating the public-private key pair on the external hardware device. After the key details are configured, Locker Room will wait for the external hardware device to become present. Once present the key enrollment process will complete. The public key is stored within the application for future encryption and the private key always remains on the external hardware device for future decryption.

A user can choose to encrypt a lockbox directly after it is created or they can choose to encrypt it later. Double-clicking on an unencrypted lockbox will prompt the user to encrypt it. And double-clicking on an encrypted lockbox will prompt the user to decrypt it. Encryption does not require an external hardware device to be present because only previously enrolled keys are used. Decryption does require an external hardware device to be present because the private key stored on the external hardware device is used for decryption. After the encrypted lockbox is selected, Locker Room will wait for an external hardware device to become present. If the lockbox was encrypted using an enrolled key corresponding to the external hardware device then the decryption process will complete.

### Technical Details

A lockbox is logically a disk image. While a lockbox is unencrypted the disk image can be attached and a volume can be mounted as a filesystem. While a lockbox is encrypted, the disk image cannot be used.

An enrolled key is logically a public key and serial number that maps to an external hardware device containing the corresponding private key. The type of public-private key pair is dictated by the configuration details used when the key is enrolled.

When a lockbox is encrypted, a 256-bit symmetric key is generated. This symmetric key is used to encrypt the lockbox. The symmetric key is also encrypted by all of the enrolled keys and stored on disk along with the encrypted lockbox. If multiple keys are enrolled then multiple copies of the symmetric key are encrypted and stored on disk. But there is only ever one copy of the encrypted lockbox.

When a lockbox is decrypted, the serial number of the external hardware device is used to map back to an encrypted symmetric key stored on disk. The private key stored on the external hardware device is then used to decrypt the encrypted symmetric key. Finally the now decrypted symmetric key is used to decrypt the lockbox. The symmetric key is thrown away and never used for future encryption.

### Known Issues

- When a lockbox is encrypted Locker Room first tries to unmount and detach the corresponding disk image. This will cause any newly added files to be lost unless the disk image is manually unmounted and detached prior to encryption.
- Enrolling a key will overwrite an existing private key in the specified slot on the external hardware device.
- There is no way to enter a pin if the pin policy of the enrolled key is set to anything besides `Never`.
- When a lockbox is encrypted, the unencrypted content is deleted before the encrypted content is saved. This may lead to data loss. The same is also true of the decryption process.
- When a lockbox is encrypted, the entire contents are read into memory. This is not a feasible implementation for large lockboxes. The same is also true of the decryption process.

### Future Enhancements

- Add unit tests.
- Delete lockboxes within Locker Room. They can only be removed using the filesystem.
- Delete keys within Locker Room. They can be removed using the filesystem and there is no way to remove the corresponding private key on the external hardware device. [Yubico changelogs](https://github.com/Yubico/yubico-piv-tool/blob/master/debian/changelog) suggest that YubiKey firmware 5.7.0 will add support for deleting keys.
- Add UI error messages for failures.
- Write application log messages to the Unified Logging System.
- Indicate which enrolled keys were used to encrypt a lockbox.
- Select which enrolled keys are used to encrypt a lockbox instead of using all of them.
- Encrypt and decrypt an external volume.
- Write private keys to unregistered PIV slots on the external hardware device.
- Generate keys using elliptic curve cryptography. This is blocked by YubiKey's current support for only RSA cipher text decryption.

### Contact

NSNolan - latesonarinn@gmail.com
