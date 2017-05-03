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

FFMPEG_VERSION="3.3"
VPX_VERSION="1.6.0"
OPUS_VERSION="1.1.3"
NVENC_VERSION="7.1.9"
X265_VERSION="2.3"
YASM_VERSION="1.3.0"


if [ -d "/usr/local/cuda" ]; then
    CUDA_PARAMS="--enable-cuda --enable-cuvid --enable-libnpp"
    CUDA_PARAMS="$CUDA_PARAMS --extra-cflags=\"-I/usr/local/cuda/include/\""
    CUDA_PARAMS="$CUDA_PARAMS --extra-ldflags=\"-L/usr/local/cuda/lib64/\""
else
    CUDA_PARAMS=""
fi


REPOS=(
    "https://github.com/mstorsjo/fdk-aac"
    "https://github.com/mirror/x264"
    "https://github.com/martastain/bmd-sdk"
)

if [ -z "$PREFIX" ]; then
    PREFIX="/usr/local"
fi

function install_prerequisites {
    apt-get -y install\
        build-essential \
        unzip \
        cmake \
        checkinstall \
        git \
        libtool \
        autoconf \
        automake \
        pkg-config \
        sox \
        libbluray-dev \
        libfftw3-dev \
        fontconfig \
        libfontconfig1 \
        libfontconfig1-dev \
        frei0r-plugins \
        frei0r-plugins-dev \
        libass-dev \
        flite1-dev \
        ladspa-sdk \
        libfreetype6-dev \
        libchromaprint-dev \
        libcaca-dev \
        libfribidi-dev \
        libmp3lame-dev \
        libmodplug-dev \
        libtwolame-dev \
        libbs2b-dev \
        librtmp-dev \
        librtmp1 \
        libsoxr-dev \
        libopus-dev \
        libspeex-dev \
        libssh-dev \
        libv4l-dev \
        libwavpack-dev \
        libwebp-dev \
        libzvbi-dev || exit 1
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


function install_yasm {
    cd $TEMPDIR
    wget http://www.tortall.net/projects/yasm/releases/yasm-${YASM_VERSION}.tar.gz || return 1
    echo "Extracting YASM"
    tar -xf yasm-${YASM_VERSION}.tar.gz
    cd yasm-${YASM_VERSION}
    ./configure --prefix=$PREFIX || return 1
    make || return 1
    make install || return 1
    return 0
}


function install_fdk_aac {
    cd $TEMPDIR/fdk-aac
    autoreconf -fiv || return 1
    ./configure --prefix=$PREFIX || return 1
    make || return 1
    make install || return 1
    return 0
}


function install_opus {
    cd $TEMPDIR
    wget http://downloads.xiph.org/releases/opus/opus-${OPUS_VERSION}.tar.gz
    tar -xf opus-${OPUS_VERSION}.tar.gz
    cd opus-${OPUS_VERSION}
    ./configure --prefix=$PREFIX \
        --disable-static || return 1
    make || return 1
    make install || return 1
    return 0
}


function install_nvenc {
    cd $TEMPDIR
    MODULE_NAME="Video_Codec_SDK_${NVENC_VERSION}"
    wget "http://repo.imm.cz/${MODULE_NAME}.zip"
    if [ -d ${MODULE_NAME} ]; then
        rm -rf ${MODLE_NAME}
    fi
    unzip ${MODULE_NAME}.zip || return 1
    cp -v ${MODULE_NAME}/Samples/common/inc/*.h /usr/include/
    cp -rv ${MODULE_NAME}/Samples/common/inc/GL /usr/include/
    return 0
}


function install_vpx {
    cd $TEMPDIR
    wget http://storage.googleapis.com/downloads.webmproject.org/releases/webm/libvpx-${VPX_VERSION}.tar.bz2
    tar -xf libvpx-${VPX_VERSION}.tar.bz2
    cd libvpx-${VPX_VERSION}
    ./configure \
        --prefix=$PREFIX \
        --disable-examples \
        --enable-shared \
        --disable-unit-tests ||  return 1
    make || return 1
    make install || return 1
    make clean
    ldconfig
    return 0
}


function install_x264 {
    cd $TEMPDIR/x264
    ./configure --prefix=$PREFIX \
        --enable-pic \
        --enable-shared \
        --disable-lavf || return 1
    make || return 1
    make install || return 1
    ldconfig
    return 0
}


function install_x265 {
    cd $TEMPDIR
    wget http://ftp.videolan.org/pub/videolan/x265/x265_${X265_VERSION}.tar.gz
    tar -xf x265_${X265_VERSION}.tar.gz
    cd $TEMPDIR/x265_${X265_VERSION}
    cmake source/
    make || return 1
    make install || return 1
    return 0
}


function install_bmd {
    cd $TEMPDIR
    cp bmd-sdk/* /usr/include/ || return 1
    return 0
}


function install_ffmpeg {
    cd $TEMPDIR
    MODULE_NAME="ffmpeg-${FFMPEG_VERSION}"
    if [ ! -f ${MODULE_NAME}.tar.bz2 ]; then
        wget http://ffmpeg.org/releases/${MODULE_NAME}.tar.bz2 || return 1
    fi

    if [ -d ${MODULE_NAME} ]; then
        rm -rf ${MODULE_NAME}
    fi

    tar -xf ${MODULE_NAME}.tar.bz2 || return 1
    cd ${MODULE_NAME}

    ./configure --prefix=$PREFIX \
      --enable-nonfree \
      --enable-gpl \
      --enable-version3 \
      --enable-shared \
      --enable-pic \
    \
    --enable-avresample \
    --enable-fontconfig      ` # enable fontconfig, useful for drawtext filter` \
    --enable-frei0r          ` # enable frei0r video filtering` \
    --enable-ladspa          ` # enable LADSPA audio filtering` \
    --enable-libass          ` # enable libass subtitles rendering` \
    --enable-libbluray       ` # enable BluRay reading using libbluray` \
    --enable-libbs2b         ` # enable bs2b DSP library` \
    --enable-libcaca         ` # enable textual display using libcaca` \
    --enable-libfdk-aac      ` # enable AAC de/encoding via libfdk-aac` \
    --enable-libflite        ` # enable flite (voice synthesis) support via libflite` \
    --enable-libfreetype     ` # enable libfreetype, needed for drawtext filter` \
    --enable-libfribidi      ` # enable libfribidi, improves drawtext filter` \
    --enable-libmodplug      ` # enable ModPlug via libmodplug` \
    --enable-libmp3lame      ` # enable MP3 encoding via libmp3lame` \
    --enable-libopus         ` # enable Opus de/encoding via libopus` \
    --enable-librtmp         ` # enable LibRTMP` \
    --enable-libsoxr         ` # enable Include libsoxr resampling` \
    --enable-libspeex        ` # enable Speex de/encoding via libspeex` \
    --enable-libssh          ` # enable SFTP protocol via libssh` \
    --enable-libtwolame      ` # enable MP2 encoding via libtwolame` \
    --enable-libv4l2         ` # enable libv4l2/v4l-utils` \
    --enable-libvpx          ` # enable VP8 and VP9 de/encoding via libvpx` \
    --enable-libwavpack      ` # enable wavpack encoding via libwavpack` \
    --enable-libwebp         ` # enable WebP encoding via libwebp` \
    --enable-libx264         ` # enable H.264 encoding via x264` \
    --enable-libx265         ` # enable HEVC encoding via x265` \
    --enable-libzvbi         ` # enable teletext support via libzvbi` \
    --enable-decklink        ` # enable Blackmagic DeckLink I/O support` \
    --enable-nvenc           ` # enable NVIDIA NVENC support` \
    --enable-openssl         ` # needed for https support if gnutls is not used` \
    $CUDA_PARAMS \
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

install_yasm || error_exit
install_fdk_aac || error_exit
install_opus || error_exit
install_vpx || error_exit
install_x264 || error_exit
install_x265 || error_exit
install_nvenc || error_exit
install_bmd || error_exit
install_ffmpeg || error_exit

finished
