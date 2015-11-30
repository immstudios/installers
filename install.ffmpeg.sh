#!/bin/bash
#
# Copyright (c) 2015 imm studios, z.s.
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

function install_prerequisites {
    apt-get -y \
        build-essential \
        cmake \
        checkinstall \
        git \
        libtool \
        autoconf \
        automake \
        pkg-config \
        libtool-bin \
        sox \
        libfftw3-dev \
        fontconfig \
        libfontconfig \
        libfontconfig-dev \
        frei0r-plugins \
        frei0r-plugins-dev \
        libass-dev \
        flite1-dev \
        libfreetype6-dev \
        libmp3lame-dev \
        libtwolame-dev \
        libopenjpeg-dev \
        librtmp-dev \
        libschroedinger-dev \
        libopus-dev \
        libspeex-dev \
        libtheora-dev \
        libvorbis-dev \
        libwavpack-dev \
        libxvidcore4 \
        libxvidcore-dev \
        libzvbi-dev || exit 1
}



