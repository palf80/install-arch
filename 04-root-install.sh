#!/bin/bash

TZ="Europe/Vienna"
BOOTLOADER_ID=ARCH
BOOT_TARGET="/dev/sda"

#arch-chroot /mnt

if [ -d /mnt/proc/1 ]; then
	echo "Das Script läuft nicht in einer chroot-umgebung!"
	exit
fi

# Setting up timezone.
ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime

# Setting up clock.
hwclock --systohc

# Generating locales.
echo "Generating locales."
locale-gen

# Generating a new initramfs.
echo "Creating a new initramfs."
chmod 600 /boot/initramfs-linux*
mkinitcpio -P

# Snapper configuration
echo "Do snapper configuration"
umount /.snapshots
rm -r /.snapshots
snapper --no-dbus -c root create-config /
snapper --no-dbus -c home create-config /home
btrfs subvolume delete /.snapshots
mkdir /.snapshots
mount -a
chmod 750 /.snapshots

if [ -z "$BOOT_TARGET" ]; then
    read -r -p "Please choose target: " BOOT_TARGET
fi

# Installing GRUB.
echo "Installing GRUB on /boot."

GRUB_MODULES="normal test efi_gop efi_uga search echo linux loadenv configfile gzio part_gpt btrfs"

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id="$BOOTLOADER_ID" --modules="$GRUB_MODULES" --disable-shim-lock "$BOOT_TARGET"

# Creating grub config file.
echo "Creating GRUB config file."
grub-mkconfig -o /boot/grub/grub.cfg

# Setting root password.
echo "Setting root password"
passwd

sed -i '/Color/s/^#//' /etc/pacman.conf
