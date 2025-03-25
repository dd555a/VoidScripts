ls
echo "Choose image to mount(Directory in the script path):"
read dir
sudo mount --rbind /dev ./$dir/dev
sudo mount --make-rslave ./$dir/dev
sudo mount -t proc /proc ./$dir/proc
sudo mount --rbind /sys ./$dir/sys
sudo mount --make-rslave ./$dir/sys
sudo mount --rbind /tmp ./$dir/tmp
sudo mount --bind /run ./$dir/run

sudo cp --dereference /etc/resolv.conf ./$dir/etc
sudo chroot ./$dir /bin/bash
