ls
echo "Choose dir to unmount:"
read dir
sudo umount /$dir/dev
sudo umount /$dir/dev
sudo umount /$dir/proc
sudo umount /$dir/sys
sudo umount /$dir/sys
sudo umount /$dir/tmp
sudo umount /$dir/run
sudo umount -R /$dir

sudo cryptsetup luksClose /dev/mapper/GCrypt

