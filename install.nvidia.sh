#!/bin/bash
#
# Copyright (c) 2015 - 2017 imm studios, z.s.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
##############################################################################
## COMMON UTILS

BASEDIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TEMPDIR=/tmp/$(basename "${BASH_SOURCE[0]}")

function error_exit {
    printf "\n\033[0;31mInstallation failed\033[0m\n"
    cd $BASEDIR
    exit 1
}

function finished {
    printf "\n\033[0;92mInstallation completed\033[0m\n"
    cd $BASEDIR
    exit 0
}


if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   error_exit
fi

if [ ! -d $TEMPDIR ]; then
    mkdir $TEMPDIR || error_exit
fi

## COMMON UTILS
##############################################################################

DRIVER_VERSION="375.39"

function install_prerequisites {
    apt install linux-headers-$(uname -r|sed 's,[^-]*-[^-]*-,,')
}

function install_driver {
    cd $TEMPDIR
    SCRIPT_NAME="NVIDIA-Linux-x86_64-$DRIVER_VERSION.run"
    if [ ! -f $SCRIPT_NAME ]; then
        wget http://us.download.nvidia.com/XFree86/Linux-x86_64/$DRIVER_VERSION/$SCRIPT_NAME
    fi
    chmod +x "$SCRIPT_NAME"

    ./$SCRIPT_NAME -q -a -n -X -s

    # That's all there is to it.
    # The -q option means quiet, the -a option means accept licence,
    # the -n action suppresses questions, the -X option updates the xorg.conf file
    # and the -s option disables the ncurses interface.

    return 0
}

install_prerequisites || error_exit
install_driver || error_exit

