echo "Choose device:"
lsblk
read device

echo "Choose image to mount:"
ls


BTRFS_OPTS="rw,relatime,ssd,space_cache=v2"
sudo mkdir /mnt/VoidR

sudo mount -o $BTRFS_OPTS /dev/mapper/GCrypt /mnt/VoidR
sudo mount -o $BTRFS_OPTS,subvol=@root /dev/mapper/GCrypt /mnt/VoidR/
sudo mount "${device}2" /mnt/VoidR/boot
sudo mount "${device}1" /mnt/VoidR/boot/efi
sudo mount -o $BTRFS_OPTS,subvol=@home /dev/mapper/GCrypt /mnt/VoidR/home
sudo mount -o $BTRFS_OPTS,subvol=@snapshots /dev/mapper/GCrypt /mnt/VoidR/.snapshots

read dir
sudo cryptsetup luksOpen "${device}3" GCrypt
sudo mount --rbind /dev /$dir/dev
sudo mount --make-rslave /$dir/dev
sudo mount -t proc /proc /$dir/proc
sudo mount --rbind /sys /$dir/sys
sudo mount --make-rslave /$dir/sys
sudo mount --rbind /tmp /$dir/tmp
sudo mount --bind /run /$dir/run

sudo cp --dereference /etc/resolv.conf /$dir/etc
