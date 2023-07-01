# LUKS2 fully encrypted Arch-Linux

As the Key-derivation functions for LUKS1 are lacking but GRUB normally only supports LUKS1, additional steps are required to get a working fully encrypted LUKS2 encrypted hard drive.
The basic process is similar to a LUKS1 encrypted hard-drive but afterwards before the reboot into your installed OS additional measures need to be taken.
This works only with UEFI-systems.

In this tutorial we're assuming you want to install everything to /dev/sda and an ext4 FS.
BTRFS requires additional steps to my knowledge.

# Boot into ISO, create LVM and mount

We want three partitions: sda1: 1M, sda2: 500M (your EFI), and the rest for your encrypted hard-drive.
Create partition table via `cfdisk` or similar tools.

## Create LVM
```sh
cryptsetup luksFormat /dev/sda3
cryptsetup open /dev/sda3 cryptlvm
pvcreate /dev/mapper/cryptlvm
vgcreate vg /dev/mapper/crypylvm
```

Create your wanted partitions. Ergo something similar to:
```sh
lvcreate -L 8G vg -n swap
lvcreate -L 32G vg -n root
lvcreate -l 100%FREE vg -n home
```
and mkfs them:
```sh
mkfs.ext4 /dev/vg/root
mkfs.ext4 /dev/vg/home
mkswap /dev/vg/swap
```
and finally mount them. EFI should be mounted to `/mnt/efi`


```sh
mount /dev/vg/root /mnt
mount --mkdir /dev/vg/home /mnt/home
swapon /dev/vg/swap

mount --mkdir /dev/sda2 /mnt/efi
```

## Continue with your normal Arch install:
Note the lack of grub in the pacstrap, we will build this later
```sh
pacstrap -K /mnt base base-devel linux linux-firmware lvm2 efibootmgr networkmanager neovim ...
genfstab -U >> /mnt/etc/fstab
arch-chroot /mnt
echo YourHostName > /etc/hostname
nvim /etc/locale.conf
locale-gen
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclock --systohc
passwd
```

## Edit /etc/mkinitcpio.conf to support encryption
In `/etc/mkinitcpio.conf` edit the HOOKS to include these highlighted ones as well:
```/etc/mkinitcpio.conf
HOOKS=(base __udev__ autodetect modconf kms keyboard keymap consolefont block __encrypt__ __lvm2__ filesystems fsck)
```
and rebuild initramfs:
```sh
mkinitcpio -P
```

## Create new user, download AUR helper, and install grub-improved-luks2-git
```sh
useradd -m -G wheel alex
passwd alex
```
Give him sudo permissions:
in `/etc/sudoers` add:
```/etc/sudoers
%wheel ALL=(ALL) ALL
```
Now install paru or equivalent AUR helper:
```sh
su - alex
git clone https://aur.archlinux.org/paru
cd paru
makepkg -si
paru -S grub-improved-luks2-git
```

We now have a patched GRUB installed and can continue as if we would encrypt using LUKS1 for now:

## Edit /etc/default/grub and grub-install
Get encrypted partition UUID into the /etc/default/grub via
```sh
ls -l /dev/disk/by-uuid >> /etc/default/grub
```
and adjust two things in the file:
```/etc/default/grub
GRUB_ENABLE_CRYPTODISK=y
```
and add to `GRUB_CMDLINE_LINUX`: (can have multiple, space-separated arguments so don't delete anything if it's there, just add.)
```/etc/default/grub
GRUB_CMDLINE_LINUX="cryptdevice=UUID=device-UUID:cryptlvm"
```
and replace "device-UUID" with the uuid we got for `/dev/sda3` from the previous `ls` command. Of course remove all the trailing `ls` output.

```sh
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
```

## LUKS2 support
Now create an additional file in `/boot/grub/grub-pre.cfg` with the follwing content:

```/boot/grub/grub-pre.cfg
set crypto_uuid=device-UUID
cryptomount -u $crypto_uuid
set root=lvm/vg-root
set prefix=($root)/boot/grub
insmod normal
normal
```
and replace device-UUID with the same device-UUID as before, (again, a `ls -l /dev/disk/by-uuid >> /boot/grub/grub-pre.cfg` can help here to get the UUID for `/dev/sda3`)

Now we can overwrite our previously generated grubx64.efi with a luks2 compatible one:
```sh
grub-mkimage -p /boot/grub -O x86_64-efi -c /boot/grub/grub-pre.cfg -o /tmp/grubx64.efi lvm luks2 part_gpt cryptodisk gcry_rijndael argon2 gcry_sha256 ext2
install -v /tmp/grubx64.efi /efi/EFI/GRUB/grubx64.efi
```
We should now be done. `exit`, `umount -R /mnt`, and `reboot` into GRUB to see whether everything worked.
This still requires you to enter your passphrase twice but can be alleviated just as with the LUKS1 case:

## Only enter the password once
Create a keyfile:
```sh
dd bs=512 count=4 if=/dev/random of=/crypto_keyfile.bin iflag=fullblock
chmod 600 /crypto_keyfile.bin
cryptsetup luksAddKey /dev/sda3 /crypto_keyfile.bin
```
Add this to the initramfs:
```/etc/mkinitcpio.conf
FILES=("/crypto_keyfile.bin")
```
And rebuld via
```sh
mkinitcpio -P
```

And add this file to the `GRUB_CMDLINE_LINUX` in `/etc/default/grub`:
```/etc/default/grub
GRUB_CMDLINE_LINE="... cryptkey=rootfs:/crypto_keyfile.bin"
```
And again rebuild GRUB
```sh
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
grub-mkimage -p /boot/grub -O x86_64-efi -c /boot/grub/grub-pre.cfg -o /tmp/grubx64.efi lvm luks2 part_gpt cryptodisk gcry_rijndael argon2 gcry_sha256 ext2
install -v /tmp/grubx64.efi /efi/EFI/GRUB/grubx64.efi
```

# Auto-decrypt additional encrypted hard-drives on bootup
You can decrypt additional hard-drives automatically. For this we will use `/etc/crypttab` as well as `/etc/fstab`. This requires systemd to work.

Create your additional encrypted hard-drives if not already existant:
```sh
cryptsetup luksFormat /dev/sdX
cryptsetup open /dev/sdX YourDiskNameHere
mkfs.ext4 /dev/mapper/YourDiskNameHere
```
If you do not wish to have to enter the additional password on boot-up you will have to create a keyfile like we did for our /dev/sda3 above.
Of course this will lessen security as any additional hard-drives can also be decrypted if `/dev/sda3` has been decrypted or cracked.

Systemd can autodetec keys in `/etc/cryptsetup-keys.d` if they have the pattern `YourDiskNameHere.key`. Create this directory if not already present:
```sh
mkdir /etc/cryptsetup-keys.d
```
Add an additional keyfile to your newly created encrypted hard-drive:
```sh
dd bs=512 count=4 if=/dev/random of=/etc/cryptsetup-keys.d/YourDiskNameHere.key iflag=fullblock
chmod 600 /etc/cryptsetup-keys.d/YourDiskNameHere.key
cryptsetup luksAddKey /dev/sdX /etc/cryptsetup-keys.d/YourDiskNameHere.key
```

Get the UUID of your new hard-drive via `ls -l /dev/disk/by-uuid` and edit `/etc/crypttab`:
```/etc/crypttab
YourDiskNameHere	UUID=TheUUIDYouJustGot	/etc/crypsetp-keys.d/YourDiskNameHere.key
```
If you use `/etc/cryptsetup-keys.d` and name your keys `YourDiskNameHere.key` you could leave out the third column as this is automatically tested for.

after a `systemctl daemon-reload` you should now be able to start a service called `systemd-cryptsetup@YourDiskNameHere`.
You can verify this via a `systemctl start systemd-cryptsetup@YourDiskNameHere`.
You should not require to enter a password now.

If everything works we can now modify the `/etc/fstab` for the automatic mounting. This is done like any unencrypted hard-drive by appending:
```/etc/fstab
/dev/mapper/YourDiskNameHere	/YourMountPoint	ext4	defaults	0	2
```
Your encrypted drive should now automount on boot-up without an additional password-prompt.

# NOT TESTED, assumed to be the same as the LUKS1 case
## Use swap for hibernations
Add the `resume` hook in `/etc/mkinitcpio.conf`:
```/etc/mkinitcpio.conf
HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block encrypt lvm2 __resume__ filesystems fsck)
```
and rebuild via `mkinitcpio -P`.

Then: add to the `GRUB_CMDLINE_LINUX` in `/etc/default/grub`:
```/etc/default/grub
GRUB_CMDLINE_LINUX="... resume=/dev/vg/swap"
```
and rebuild GRUB.

```sh
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
grub-mkimage -p /boot/grub -O x86_64-efi -c /boot/grub/grub-pre.cfg -o /tmp/grubx64.efi lvm luks2 part_gpt cryptodisk gcry_rijndael argon2 gcry_sha256 ext2
install -v /tmp/grubx64.efi /efi/EFI/GRUB/grubx64.efi
```
