#LUKS2 fully encrypted Arch-Linux

As the Key-derivation functions for LUKS1 are lacking but GRUB normally only supports LUKS1, additional steps are required to get a working fully encrypted LUKS2 encrypted hard drive.
The basic process is similar to a LUKS1 encrypted hard-drive but afterwards before the reboot into your installed OS additional measures need to be taken.
This works only with UEFI-systems.

In this tutorial we're assuming you want to install everything to /dev/sda and an ext4 FS. BTRFS requires additional steps to my knowledge.

# Boot into ISO, create lvm and mount

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
```
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
echo <hostname> /etc/hostname
nvim /etc/locale-gen
locale-gen
ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclock --systohc
passwd
```

## Edit /edit/mkinitcpio.conf to support encryption
In /etc/mkninitcpio.conf edit the HOOKS:
```
HOOKS=(base __udev__ autodetect modconf kms keyboard keymap consolefont block __encrypt__ __lvm2__ filesystems fsck)
```
and rebuild initramfs:
```sh
mkinitcpio -P
```

## Create new user, download AUR helper and install grub-improved-luks2-git
```
useradd -m -G wheel alex
passwd alex
```
Give him sudo permissions:
in `/etc/sudoers` add:
```
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
```
GRUB_ENABLE_CRYPTODISK=y
```
and
```
GRUB_CMDLINE_LINUX="... cryptdevice=UUID=device-UUID:cryptlvm ..."
```
and recilace "device-UUID" with the uuid we got from the previous ls command. Of course remove all the trailing ls output.

```sh
grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
```

## LUKS2 support
Now create an additional file in `/boot/grub/grub-pre.cfg` with the follwing content:
```
set crypto_uuid=UUID
cryptomount -u $crypto_uuid
set root=lvm/vg-root
set prefix=($root)/boot/grub
insmod normal
normal
```
and replace UUID with the same UUID as before, (again, a `ls -l /dev/disk/by-uuid >> /boot/grub/grub-pre.cfg` can help here)

```
grub-mkimage -p /boot/grub -O x86_64-efi -c /boot/grub/grub-pre.cfg -o /tmp/grubx64.efi lvm luks2 part_gpt cryptodisk gcry_rijndael argon2 gcry_sha256 ext2
install -v /tmp/grubx64.efi /efi/EFI/GRUB/grubx64.efi
```
We should now be done. exit, umount -R /mnt, and reboot into GRUB to see whether everything worked.
This still requires you to enter your passphrase twice but can be alleviated just as with the LUKS1 case: https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#With_a_keyfile_embedded_in_the_initramfs
