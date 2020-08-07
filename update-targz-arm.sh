#! /bin/bash

bash "$(dirname "$0")"/update-targz.sh arm64 aarch64 bullseye >/vagrant/build/update-targz-arm.log
