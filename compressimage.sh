echo "Choose image to compress:"
ls
read file
sudo tar -c --use-compress-program='xz -T6 -4e' -vpf ./$file".tar.xz"  --exclude=./proc/* --exclude=./tmp/* --exclude=./dev/* --exclude=./sys/* --exclude=./run/*  --exclude=./mnt/* --exclude=./var/log/* --exclude=./var/cache/xbps/* --exclude=./usr/src/linux-headers* -C ./$file . && sudo chown arqex ./$file".tar.xz"

