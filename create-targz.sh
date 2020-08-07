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

echo 'Using debootstrap to create rootfs'
sudo bash -c "debootstrap --verbose --variant=minbase --foreign --arch=${PREBOOTSTRAP_ARCH} --include=sudo,locales,git,ssh,gnupg,apt-transport-https,wget,ca-certificates,less,curl,bash-completion,vim,man-db,socat,gcc-9-base,iputils-ping ${PREBOOTSTRAP_RELEASE} ./rootfs/"

echo 'Entering chroot to mount dev, sys, proc and dev/pts'
(
  # shellcheck disable=SC2164
  cd rootfs
  
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

echo 'Manually setting up debootstrap'
sudo chroot rootfs/ /bin/bash -c "/debootstrap/debootstrap --second-stage --verbose"

echo 'Installing default profile'
sudo curl https://salsa.debian.org/rhaist-guest/WSL/raw/master/linux_files/profile -so rootfs/etc/profile

echo 'Installing Pengwin bootstrap script'
sudo curl https://raw.githubusercontent.com/WhitewaterFoundry/Pengwin/master/linux_files/setup -so rootfs/etc/setup

echo 'Running Pengwin bootstrap script'
sudo chroot rootfs/ /bin/bash -c "bash /etc/setup --silent --install"

echo 'Configuring language settings'
sudo chroot rootfs/ /bin/bash -c "echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && locale-gen"
sudo chroot rootfs/ /bin/bash -c "update-locale LANGUAGE=en_US.UTF-8 LC_ALL=C"

echo 'Configuring sudo message'
sudo chroot rootfs/ /bin/bash -c "echo 'Defaults lecture_file = /etc/sudoers.lecture' >> /etc/sudoers"
sudo chroot rootfs/ /bin/bash -c "echo 'Enter your UNIX password below. This is not your Windows password.' > /etc/sudoers.lecture"

echo 'Clean up apt cache'
sudo chroot rootfs/ apt-get -y -q remove systemd dmidecode --allow-remove-essential
sudo chroot rootfs/ /bin/bash -c "yes 'N' | apt-get -y -q dist-upgrade"
sudo chroot rootfs/ apt-get install -q -y --allow-downgrades libc6=2.31-1.wsl
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
(
  # shellcheck disable=SC2164
  cd rootfs
  rm ../install_"${PREBOOTSTRAP_ARCH}"_rootfs.tar.gz
  sudo tar -zcvf ../install_"${PREBOOTSTRAP_ARCH}"_rootfs.tar.gz --exclude proc --exclude dev --exclude sys --exclude='boot/*' ./* >/dev/null
)

echo 'Run tests'
sudo cp /usr/bin/qemu-"${PREBOOTSTRAP_QEMU_ARCH}"-static rootfs/usr/bin/
sudo chmod +x rootfs/usr/bin/qemu-"${PREBOOTSTRAP_QEMU_ARCH}"-static

sudo chroot rootfs/ /bin/bash -c "git clone https://github.com/WhitewaterFoundry/pengwin-setup.git"
sudo chroot rootfs/ /bin/bash -c "cp -r pengwin-setup/tests /usr/local/bin/ && chmod -R +x /usr/local/bin/tests"
sudo chroot rootfs/ /bin/bash -c "apt-get -y -q install shunit2"
sudo chroot rootfs/ /bin/bash -c "cd /usr/local/bin/tests && ./run_tests.sh"

mkdir -p /vagrant/build
mv /vagrant/build/install_"${PREBOOTSTRAP_ARCH}"_rootfs.tar.gz /vagrant/build/install_"${PREBOOTSTRAP_ARCH}"_rootfs.tar.gz.bak
mv install_"${PREBOOTSTRAP_ARCH}"_rootfs.tar.gz /vagrant/build/

