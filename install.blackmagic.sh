#!/bin/bash
#
# Copyright (c) 2015 - 2016 imm studios, z.s.
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

DESKTOP_VIDEO_VERSION="10.11a1"

REPO_URL="http://repo.imm.cz"
DESKTOP_VIDEO_FNAME="desktopvideo_${DESKTOP_VIDEO_VERSION}_amd64.deb"

function install_desktop_video {
    apt update || return 1
    apt install linux-headers-$(uname -r) || return 1

    wget ${REPO_URL}/${DESKTOP_VIDEO_FNAME} || return 1
    dpkg -i ${DESKTOP_VIDEO_FNAME}
    apt -y -f install
    return 0
}

install_desktop_video || error_exit
finished
