#! /bin/bash

export PREBOOTSTRAP_ARCH="${1:-amd64}"
export PREBOOTSTRAP_QEMU_ARCH="${2:-x86_64}"
export PREBOOTSTRAP_RELEASE="${3:-testing}"

echo 'Installing build dependencies'
sudo apt-get update -y -q
sudo apt-get install -y -q curl gnupg debootstrap qemu-user-static

echo 'Creating rootfs folder'
sudo rm -rf rootfs
mkdir rootfs

echo 'Extract previous rootfs, entering chroot to mount dev, sys, proc and dev/pts'
(
  # shellcheck disable=SC2164
  cd rootfs
  sudo tar -zxvf /vagrant/build/install_"${PREBOOTSTRAP_ARCH}"_rootfs.tar.gz >/dev/null

  sudo mkdir -p sys
  sudo mkdir -p proc
  sudo mkdir -p dev/pts

  sudo mount --bind /dev dev/
  sudo mount --bind /sys sys/
  sudo mount --bind /proc proc/
  sudo mount --bind /dev/pts dev/pts/
)

echo 'Copy static QEMU to rootfs'
sudo cp /usr/bin/qemu-"${PREBOOTSTRAP_QEMU_ARCH}"-static rootfs/usr/bin/

echo "Marking static [rootfs/usr/bin/qemu-${PREBOOTSTRAP_QEMU_ARCH}-static] as executable"
sudo chmod +x rootfs/usr/bin/qemu-"${PREBOOTSTRAP_QEMU_ARCH}"-static

echo 'Copy dns'
sudo cp /etc/resolv.conf rootfs/etc/

echo 'Upgrade packages and install more'
sudo chroot rootfs/ apt-get -y -q update
sudo chroot rootfs/ apt-get -y -q install man-db socat gcc-9-base
sudo chroot rootfs/ /bin/bash -c "yes 'N' | apt-get -y -q upgrade"

echo 'Run again in case of a change in sources'
sudo chroot rootfs/ apt-get -y -q update
sudo chroot rootfs/ /bin/bash -c "yes 'N' | apt-get -y -q dist-upgrade"
sudo chroot rootfs/ apt-get install -q -y --allow-downgrades libc6=2.31-1.wsl

echo 'Clean up apt cache'
sudo chroot rootfs/ apt-get -y -q remove systemd dmidecode --allow-remove-essential
sudo chroot rootfs/ apt-get -y -q autoremove
sudo chroot rootfs/ apt-get -y -q autoclean
sudo chroot rootfs/ apt-get -y -q clean

echo 'Add defaults for readline and vim'
sudo chroot rootfs/ /bin/bash -c "echo 'source /etc/vim/vimrc' > /etc/skel/.vimrc"
sudo chroot rootfs/ /bin/bash -c "echo 'syntax on' >> /etc/skel/.vimrc"
sudo chroot rootfs/ /bin/bash -c "echo 'set background=dark' >> /etc/skel/.vimrc"
sudo chroot rootfs/ /bin/bash -c "echo 'set visualbell' >> /etc/skel/.vimrc"
sudo chroot rootfs/ /bin/bash -c "echo 'set noerrorbells' >> /etc/skel/.vimrc"
sudo chroot rootfs/ /bin/bash -c "echo '\$include /etc/inputrc' > /etc/skel/.inputrc"
sudo chroot rootfs/ /bin/bash -c "echo 'set bell-style none' >> /etc/skel/.inputrc"
sudo chroot rootfs/ /bin/bash -c "echo 'set show-all-if-ambiguous on' >> /etc/skel/.inputrc"
sudo chroot rootfs/ /bin/bash -c "echo 'set show-all-if-unmodified on' >> /etc/skel/.inputrc"

echo 'Deleting QEMU from chroot'
sudo rm rootfs/usr/bin/qemu-"${PREBOOTSTRAP_QEMU_ARCH}"-static

echo 'Compressing rootfs'
mkdir -p /vagrant/build
rm /vagrant/build/install_"${PREBOOTSTRAP_ARCH}"_rootfs.tar.gz.bak
mv /vagrant/build/install_"${PREBOOTSTRAP_ARCH}"_rootfs.tar.gz /vagrant/build/install_"${PREBOOTSTRAP_ARCH}"_rootfs.tar.gz.bak
(
  # shellcheck disable=SC2164
  cd rootfs
  sudo tar -zcvf /vagrant/build/install_"${PREBOOTSTRAP_ARCH}"_rootfs.tar.gz --exclude proc --exclude dev --exclude sys --exclude='boot/*' ./* >/dev/null
)

