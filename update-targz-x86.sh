#! /bin/bash

bash "$(dirname "$0")"/update-targz.sh amd64 x86_64 trixie >/vagrant/build/update-targz-x86.log
