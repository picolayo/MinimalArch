#!/bin/bash
set -e
parted -s /dev/sda mklabel gpt
parted -s /dev/sda mkpart "EFI" fat32 1MiB 512MiB
parted -s /dev/sda set 1 boot on
parted -s /dev/sda mkpart "root" ext4 512MiB 100%
mkfs.fat -F32 /dev/sda1
mkfs.ext4 -F /dev/sda2
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot
pacstrap /mnt base linux linux-firmware nano networkmanager grub efibootmgr
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt <<EOF
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "archlinux" > /etc/hostname
systemctl enable NetworkManager
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
echo "root:root" | chpasswd
EOF
umount -R /mnt
reboot
