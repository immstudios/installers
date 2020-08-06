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

cuda_version="11.0.2"
driver_version="450.51.05"

#http://developer.download.nvidia.com/compute/cuda/11.0.2/local_installers/cuda_11.0.2_450.51.05_linux.run

function install_prerequisites {
    apt install -y \
        linux-headers-$(uname -r) \
        ssl-cert \
        build-essential || return 1
    return 0
}

function nvidia_uninstall {
    HAS_NVIDIA_UNINSTALL=`hash nvidia-uninstall 2> /dev/null && echo 1 || echo ""`
    if [ $HAS_NVIDIA_NVIDIA_UNINSTALL ] ; then
        echo "Uninstalling previous nvidia driver"
        nvidia-uninstall -s || return 1
    elif [ `aptitude search nvidia | grep ^i | wc -l` != 0 ]; then
        echo "Jsou tam zbytky nvidie. Zkusime to odinstalovat";
        apt remove --purge nvidia*
        apt autoremove
        if [ `aptitude search nvidia | grep ^i | wc -l` != 0 ]; then
            echo
            echo "Furt jsou tu zbytky nvidie. Zkus tyhle baliky vykopat rucne";
            aptitude search nvidia | grep ^i
            return 1
        fi
        echo ""
        echo "nVidia uninstall finished. Reboot computer and run installer again"
        return 1
    fi
    return 0
}


function nvidia_cuda_install {
    cd ~

    # Smazeme stare error logy
    rm /tmp/cuda_install* 2> /dev/null
    rm /var/log/nvidia-installer.log* 2> /dev/null

    installer_file="cuda_${cuda_version}_${driver_version}_linux.run"
    if [ ! -f ${installer_file} ]; then
        wget https://developer.download.nvidia.com/compute/cuda/${cuda_version}/local_installers/${installer_file} || return 1
    fi
    chmod +x ${installer_file}
    ./${installer_file} --silent --driver --toolkit --run-nvidia-xconfig || cat /tmp/cuda_install*

    # Cuda instalator kasle na navratove kody, takze uspesnost instalace
    # otestujeme pritomnosti programu nvidia-smi

    HAS_NVIDIA=`hash nvidia-smi 2> /dev/null && echo 1 || echo ""`
    if [ $HAS_NVIDIA ] ; then
        return 0
    else
        echo ""
        cat /var/log/nvidia-installer.log
	echo ""
        return 1
    fi
}

install_prerequisites || error_exit
nvidia_uninstall || error_exit
nvidia_cuda_install || error_exit
