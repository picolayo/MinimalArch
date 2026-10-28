#!/usr/bin/env bash
set -e

# 1. Konfigurasi Partisi Disk (/dev/sda)
echo "==> Mempartisi disk /dev/sda..."
parted --script /dev/sda \
    mklabel gpt \
    mkpart "EFI" fat32 1MiB 512MiB \
    set 1 esp on \
    mkpart "root" ext4 512MiB 100%

# 2. Format Partisi
echo "==> Memformat partisi..."
mkfs.fat -F32 /dev/sda1
mkfs.ext4 -F /dev/sda2

# 3. Mounting Partisi
echo "==> Mounting partisi ke /mnt..."
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

# 4. Instalasi Sistem Dasar (Base, Runit, Kernel, Intel Microcode)
echo "==> Menginstal paket dasar Artix Linux..."
basestrap /mnt base base-runit systemd-sysusers runit eudev linux linux-firmware intel-ucode nano

# 5. Generate fstab
echo "==> Membuat fstab..."
fstabgen -U /mnt >> /mnt/etc/fstab

# 6. Masuk ke Chroot dan Konfigurasi Lanjutan
echo "==> Masuk ke chroot untuk konfigurasi..."
arch-chroot /mnt /bin/bash <<EOF

# Set Timezone (contoh: Jakarta)
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
hwclock --systohc

# Set Locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set Hostname
echo "artix-intel" > /etc/hostname

# Set Password Root
echo "==> Silakan atur password root:"
passwd

# Konfigurasi Bootloader (GRUB untuk UEFI)
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=Artix
grub-mkconfig -o /boot/grub/grub.cfg

# Mengaktifkan layanan dasar runit
ln -s /etc/runit/sv/udevd /etc/runit/runsvdir/default/
ln -s /etc/runit/sv/agetty-tty1 /etc/runit/runsvdir/default/

exit
EOF

echo "==> Instalasi Selesai! Silakan reboot sistem Anda."
