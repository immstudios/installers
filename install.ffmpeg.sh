#!/bin/bash
#
# Copyright (c) 2015 - 2018  imm studios, z.s.
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

FFMPEG_VERSION="4.1"
NASM_VERSION="2.13.03"

REPOS=(
    "https://github.com/mstorsjo/fdk-aac"
    "https://github.com/martastain/bmd-sdk"
    "https://github.com/mirror/x264"
    "https://git.videolan.org/git/ffmpeg/nv-codec-headers"
    "https://github.com/Haivision/srt"
)

extra_flags=""

if [ -z "$PREFIX" ]; then
    PREFIX="/usr/local"
fi

HAS_NVIDIA=`hash nvidia-smi 2> /dev/null && echo 1 || echo ""`
if [ $HAS_NVIDIA ] ; then
    extra_flags="$extra_flags --enable-nvenc --enable-cuda --enable-cuvid"
fi

function install_prerequisites {
    # bulid tools
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
	tclsh \
	|| exit 1

    # network and security
    apt -y install \
        avahi-daemon \
        avahi-discover \
        avahi-utils \
        libssl-dev \
        libfftw3-dev \
        ocl-icd-opencl-dev \
        opencl-headers \
	|| exit 1

    # text rendering
    apt -y install \
        fontconfig \
        libfontconfig1 \
        libfontconfig1-dev \
        libfribidi-dev \
        libfribidi0 \
        libfreetype6-dev \
        libass-dev \
	|| exit 1


    # 3rd party codecs
    apt -y install \
        libx265-dev \
        libmp3lame-dev \
        libtwolame-dev \
        libopus-dev \
        libv4l-dev \
        libwebp-dev \
        libzvbi-dev \
	|| exit 1
}

function download_repos {
    cd ${temp_dir}
    for i in ${REPOS[@]}; do
        MNAME=`basename $i`
        if [ -d $MNAME ]; then
            cd $MNAME
            git checkout master || return 1
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

function install_nvcodec {
    if [ $HAS_NVIDIA ]; then
        cd $temp_dir/nv-codec-headers
        make || return 1
        make install || return 1
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
    ndi_dir="NDI SDK for Linux"
    if [ ! -f $ndi_file ]; then
        wget https://repo.imm.cz/$ndi_file
    fi
    chmod +x $ndi_file
    if [ ! -d "$ndi_dir" ]; then
        echo "Unpacking NDI"
        yes | ./$ndi_file
    fi
    cp "$ndi_dir/include/"* /usr/include
    cp "$ndi_dir/lib/x86_64-linux-gnu/"* /usr/lib
    extra_flags="$extra_flags --enable-libndi_newtek"
    return 0
}

function install_nasm {
    cd $temp_dir
    wget https://www.nasm.us/pub/nasm/releasebuilds/${NASM_VERSION}/nasm-${NASM_VERSION}.tar.gz || return 1
    tar -xf nasm-${NASM_VERSION}.tar.gz
    cd nasm-${NASM_VERSION}
    ./configure || return 1
    make || return 1
    make install || return 1
    return 0
}

function install_x264 {
    cd $temp_dir/x264
    ./configure --enable-shared --bit-depth=all --chroma-format=all || return 1
    make || return 1
    make install || return 1
    return 0
}

function install_libsrt {
    cd $temp_dir/srt
    ./configure || return 1
    make || return 1
    make install || return 1
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
    --enable-fontconfig      ` # enable fontconfig, useful for drawtext filter` \
    --enable-libass          ` # enable libass subtitles rendering` \
    --enable-libfreetype     ` # enable libfreetype, needed for drawtext filter` \
    --enable-libfribidi      ` # enable libfribidi, improves drawtext filter` \
    --enable-libmp3lame      ` # enable MP3 encoding via libmp3lame` \
    --enable-libtwolame      ` # enable MP2 encoding via libtwolame` \
    --enable-libwebp         ` # enable WebP encoding via libwebp` \
    --enable-libx264         ` # enable H.264 encoding via x264` \
    --enable-libx265         ` # enable HEVC encoding via x265` \
    --enable-libopus         ` # enable Opus de/encoding via libopus` \
    --enable-libzvbi         ` # enable teletext support via libzvbi` \
    --enable-libv4l2         ` # enable libv4l2/v4l-utils` \
    --enable-libfdk-aac      ` # enable AAC de/encoding via libfdk-aac` \
    --enable-openssl         ` # needed for https support if gnutls is not used` \
    --enable-decklink        ` # enable Blackmagic DeckLink I/O support` \
    --enable-libsrt \
    --enable-libndi_newtek \
    --enable-opencl \
    $extra_flags \
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
install_libsrt || error_exit
install_nasm || error_exit
install_x264 || error_exit
install_nvcodec || error_exit
install_bmd || error_exit
install_ndi || error_exit
install_fdk_aac || error_exit

install_ffmpeg || error_exit

finished
