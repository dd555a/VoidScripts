#!/bin/bash
lsblk
echo "Full name of install drive (eg. /dev/sda):"
read device
ls
echo "Full name of install image (eg. foo.tar.xz):"
read tarfile
# Partition devic
(
echo o
echo y

echo n 
echo 1
echo ""
echo +100M
echo ef00

echo n
echo 2
echo ""
echo +3G
echo 8300

echo n
echo 3
echo ""
echo ""
echo 8300

echo w
echo y
) | sudo gdisk $device

#Make file systems and encrypt

sudo mkfs.vfat "${device}1"
sudo mkfs.ext4 -F "${device}2"
sudo cryptsetup luksFormat -c aes-xts-plain64 -s 512 "${device}3" 
sudo cryptsetup luksOpen "${device}3" GCrypt

#BTRFS OPTIONS
sudo mkfs.btrfs /dev/mapper/GCrypt
BTRFS_OPTS="rw,relatime,ssd,space_cache=v2"
sudo mkdir /mnt/VoidR
sudo mount -o $BTRFS_OPTS /dev/mapper/GCrypt /mnt/VoidR
sudo btrfs subvolume create /mnt/VoidR/@root
sudo btrfs subvolume create /mnt/VoidR/@home
sudo btrfs subvolume create /mnt/VoidR/@snapshots

#Mounting
sudo mount -o $BTRFS_OPTS,subvol=@root /dev/mapper/GCrypt /mnt/VoidR/
sudo mkdir /mnt/VoidR/boot
sudo mount "${device}2" /mnt/VoidR/boot
sudo mkdir /mnt/VoidR/boot/efi
sudo mount "${device}1" /mnt/VoidR/boot/efi
sudo mkdir /mnt/VoidR/home
sudo mount -o $BTRFS_OPTS,subvol=@home /dev/mapper/GCrypt /mnt/VoidR/home
sudo mkdir /mnt/VoidR/.snapshots
sudo chown -R arqex /mnt/VoidR/.snapshots
sudo mount -o $BTRFS_OPTS,subvol=@snapshots /dev/mapper/GCrypt /mnt/VoidR/.snapshots



#Extract tarball
sudo tar  --xattrs-include='*.*' --numeric-owner -xpf ./$tarfile -C /mnt/VoidR

#Mount temporary filesystems.
sudo mount --rbind /dev /mnt/VoidR/dev
sudo mount --make-rslave /mnt/VoidR/dev

sudo mount -t proc /proc /mnt/VoidR/proc

sudo mount --rbind /sys /mnt/VoidR/sys
sudo mount --make-rslave /mnt/VoidR/sys

sudo mount --rbind /tmp /mnt/VoidR/tmp
sudo mount --bind /run /mnt/VoidR/run

#Copy network info
sudo cp --dereference /etc/resolv.conf /mnt/VoidR/etc

#Set static IP for the machine:
#echo "Set a static IP for the machine: 192.168.0.xxx"
#read ip


#echo "$ip"> /mnt/voidr/etc/hostname

BootUUID=$(sudo blkid -o value -s UUID "${device}2")
EfiUUID=$(sudo blkid -o value -s UUID "${device}1")
RootUUID=$(sudo blkid -o value -s UUID /dev/mapper/GCrypt)
CryptUUID=$(sudo blkid -o value -s UUID "${device}3")

echo BootUUID=$BootUUID
echo EfiUUID=$EfiUUID
echo RootUUID=$RootUUID
echo CryptUUID=$CryptUUID

#Generate a FSTAB
sudo chown $USER /mnt/VoidR/etc/fstab
sudo echo "UUID="$BootUUID"  /boot ext4 rw,relatime 0 0" >> /mnt/VoidR/etc/fstab
sudo echo "UUID="$EfiUUID"  /boot/efi vfat rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,utf8,errors=remount-ro 0 0" >> /mnt/VoidR/etc/fstab
sudo echo "UUID="$RootUUID"  /   btrfs rw,relatime,ssd,space_cache=v2,subvol=/@root 0 0" >> /mnt/VoidR/etc/fstab
sudo echo "UUID="$RootUUID"  /home   btrfs rw,relatime,ssd,space_cache=v2,subvol=/@home 0 0" >> /mnt/VoidR/etc/fstab
sudo echo "UUID="$RootUUID"  /.snapshots btrfs rw,relatime,ssd,space_cache=v2,subvol=/@snapshots 0 0" >> /mnt/VoidR/etc/fstab
sudo echo "tmpfs   /tmp    tmpfs   defaults,nosuid,nodev 0 0" >> /mnt/VoidR/etc/fstab
sudo chown root /mnt/VoidR/etc/fstab

#Configure Grub
sudo chown arqex /mnt/VoidR/etc/default/grub
sudo sed -i '/GRUB_CMDLINE_LINUX/d' /mnt/VoidR/etc/default/grub
sudo echo "GRUB_ENABLE_CRYPTODISK=y" >> /mnt/VoidR/etc/default/grub
sudo echo 'GRUB_CMDLINE_LINUX_DEFAULT="rd.lvm.vg=voidvm rd.luks.uuid='$CryptUUID' loglevel=4"' >> /mnt/VoidR/etc/default/grub
sudo chown root /mnt/VoidR/etc/default/grub




sudo chroot /mnt/VoidR /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot/efi"
sudo chroot /mnt/VoidR /bin/bash -c "grub-mkconfig -o /boot/grub.cfg"
sudo chroot /mnt/VoidR /bin/bash -c "xbps-reconfigure -fa"

echo "Install complete?"
read install

#Umount filesystems
sudo umount -f /mnt/VoidR/dev
sudo umount -f /mnt/VoidR/sys
sudo umount -f /mnt/VoidR/proc
sudo umount -f /mnt/VoidR/tmp
sudo umount -f /mnt/VoidR/run

sudo umount -R /mnt/VoidR

sudo cryptsetup luksClose /dev/mapper/GCrypt
