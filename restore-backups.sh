#! /bin/bash

if [[ -f /vagrant/build/install_amd64_rootfs.tar.gz.bak ]]; then
  rm /vagrant/build/install_amd64_rootfs.tar.gz
  mv /vagrant/build/install_amd64_rootfs.tar.gz.bak /vagrant/build/install_amd64_rootfs.tar.gz
fi

if [[ -f /vagrant/build/install_arm64_rootfs.tar.gz.bak ]]; then
  rm /vagrant/build/install_arm64_rootfs.tar.gz
  mv /vagrant/build/install_arm64_rootfs.tar.gz.bak /vagrant/build/install_arm64_rootfs.tar.gz
fi


