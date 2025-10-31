#! /bin/bash

bash "$(dirname "$0")"/update-targz.sh arm64 aarch64 trixie >/vagrant/build/update-targz-arm.log
