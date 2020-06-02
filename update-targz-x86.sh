#! /bin/bash

bash "$(dirname "$0")"/update-targz.sh amd64 x86_64 testing >/vagrant/build/update-targz-x86.log
