#!/bin/bash
#
# Copyright (c) 2015 - 2017  imm studios, z.s.
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

base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
temp_dir=/tmp/$(basename "${BASH_SOURCE[0]}")

function error_exit {
    printf "\n\033[0;31mInstallation failed\033[0m\n"
    cd ${base_dir}
    exit 1
}

function finished {
    printf "\n\033[0;92mInstallation completed\033[0m\n"
    cd ${base_dir}
    exit 0
}


if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   error_exit
fi

if [ ! -d ${temp_dir} ]; then
    mkdir ${temp_dir} || error_exit
fi

## COMMON UTILS
##############################################################################

FFMPEG_VERSION="3.4"
NVENC_VERSION="7.1.9"

REPOS=(
    "https://github.com/mstorsjo/fdk-aac"
    "https://github.com/martastain/bmd-sdk"
)

if [ -z "$PREFIX" ]; then
    PREFIX="/usr/local"
fi

HAS_NVIDIA=`hash nvidia-smi && echo 1|| echo 0`
if [ $HAS_NVIDIA ] ; then
    nvidia_params="--enable-nvenc --enable-cuda --enable-cuvid"
fi

function install_prerequisites {
    apt -y install\
        build-essential \
        unzip \
        cmake \
        checkinstall \
        yasm \
        git \
        libtool \
        autoconf \
        automake \
        pkg-config \
        libfftw3-dev \
        fontconfig \
        libfontconfig1 \
        libfontconfig1-dev \
        libfribidi-dev \
        libfribidi0 \
        libass-dev \
        libfreetype6-dev \
        libx264-dev \
        libx265-dev \
        libmp3lame-dev \
        libtwolame-dev \
        librtmp-dev \
        librtmp1 \
        libopus-dev \
        librubberband-dev \
        librubberband2 \
        libssh-dev \
        libv4l-dev \
        libwebp-dev \
        libzvbi-dev || exit 1
}


function download_repos {
    cd ${temp_dir}
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


function install_fdk_aac {
    cd ${temp_dir}/fdk-aac
    autoreconf -fiv || return 1
    ./configure --prefix=$PREFIX || return 1
    make || return 1
    make install || return 1
    return 0
}

function install_nvenc {
    if [ $HAS_NVIDIA ]; then
        cd ${temp_dir}
        MODULE_NAME="Video_Codec_SDK_${NVENC_VERSION}"
        if [ ! -f ${MODULE_NAME}.zip ]; then
            wget "http://repo.imm.cz/${MODULE_NAME}.zip" || return 1
        fi
        if [ ! -d ${MODULE_NAME} ]; then
            unzip ${MODULE_NAME}.zip || return 1
        fi
        cp -v ${MODULE_NAME}/Samples/common/inc/*.h /usr/include/
        cp -rv ${MODULE_NAME}/Samples/common/inc/GL /usr/include/
    fi
    return 0
}

function install_bmd {
    cd ${temp_dir}
    cp bmd-sdk/* /usr/include/ || return 1
    return 0
}

function install_ndi {
    cd ${temp_dir}
    ndi_file="InstallNDISDK_v3_Linux.sh"
    wget http://repo.imm.cz/$ndi_file
    chmod +x $ndi_file
    ./$ndi_file
    return 0
}


function install_ffmpeg {
    cd ${temp_dir}
    ffmpeg_base_name="ffmpeg-${FFMPEG_VERSION}"
    if [ ! -f ${ffmpeg_base_name}.tar.bz2 ]; then
        wget http://ffmpeg.org/releases/${ffmpeg_base_name}.tar.bz2 || return 1
    fi

    if [ -d ${ffmpeg_base_name} ]; then
        rm -rf ${ffmpeg_base_name}
    fi

    tar -xf ${ffmpeg_base_name}.tar.bz2 || return 1
    cd ${ffmpeg_base_name}

    ./configure --prefix=$PREFIX \
      --enable-nonfree \
      --enable-gpl \
      --enable-version3 \
      --enable-shared \
      --enable-pic \
    \
    --enable-avresample \
    --enable-fontconfig      ` # enable fontconfig, useful for drawtext filter` \
    --enable-libass          ` # enable libass subtitles rendering` \
    --enable-libfreetype     ` # enable libfreetype, needed for drawtext filter` \
    --enable-libfribidi      ` # enable libfribidi, improves drawtext filter` \
    --enable-librubberband   ` # resample using librubberband` \
    --enable-libmp3lame      ` # enable MP3 encoding via libmp3lame` \
    --enable-libtwolame      ` # enable MP2 encoding via libtwolame` \
    --enable-libwebp         ` # enable WebP encoding via libwebp` \
    --enable-libx264         ` # enable H.264 encoding via x264` \
    --enable-libx265         ` # enable HEVC encoding via x265` \
    --enable-libfdk-aac      ` # enable AAC de/encoding via libfdk-aac` \
    --enable-libopus         ` # enable Opus de/encoding via libopus` \
    --enable-libzvbi         ` # enable teletext support via libzvbi` \
    --enable-libv4l2         ` # enable libv4l2/v4l-utils` \
    --enable-librtmp         ` # enable LibRTMP` \
    --enable-openssl         ` # needed for https support if gnutls is not used` \
    --enable-libssh          ` # enable SFTP protocol via libssh` \
    --enable-decklink        ` # enable Blackmagic DeckLink I/O support` \
    $nvidia_params \
    || return 1

    echo "Making ffmpeg"
    make || return 1
    make install || return 1
    make clean
    ldconfig
    return 0
}

################################################

install_prerequisites || error_exit
download_repos || error_exit

install_fdk_aac || error_exit
install_nvenc || error_exit
install_bmd || error_exit
#install_ndi || error_exit #TODO
install_ffmpeg || error_exit

finished
