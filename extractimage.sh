echo "Choose image to extract (eg VoidBASE.tar.gz):"
ls
read file
mkdir ./${file%%.*}
sudo tar  --xattrs-include='*.*' --numeric-owner -xpf ./$file -C ./${file%%.*}
