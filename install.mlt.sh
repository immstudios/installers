#!/bin/bash
#
# Copyright (c) 2015 - 2020 imm studios, z.s.
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

REPOS=(
    "https://github.com/mltframework/mlt"
)

if [ -z "$PREFIX" ]; then
    PREFIX="/usr/local"
fi

function install_prerequisites {
     apt-get -y install \
        libjack-dev \
        libmovit-dev \
        sox \
        libsox-dev \
        librtaudio-dev \
        libsamplerate-dev \
        libxml2-dev \
        || exit 1
}

function download_repos {
    cd $TEMPDIR
    for i in ${REPOS[@]}; do
        MNAME=`basename $i`
        if [ -d $MNAME ]; then
            cd $MNAME
            git pull || return 1
            cd ..
        else
            git clone $i || return 1
        fi
    done
    return 0
}

function install_mlt {
    cd $TEMPDIR/mlt
    ./configure --prefix=$PREFIX \
        --enable-gpl \
        --enable-gpl \
        --enable-shared \
        --disable-gtk2 \
        --disable-kdenlive \
        --disable-opengl \
        --disable-sdl \
        --disable-sdl2 \
        || return 1
    make || return 1
    make install || return 1
    ldconfig
    return 0
}

################################################


install_prerequisites || error_exit
download_repos || error_exit
install_mlt || error_exit

finished
