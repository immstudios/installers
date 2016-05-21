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

DEB_BRANCH=`lsb_release -is | tr '[:upper:]' '[:lower:]'`
DEB_RELEASE=`lsb_release -cs`

VAGRANT_VERSION="1.8.1"

function install_virtualbox {
    APT="deb http://download.virtualbox.org/virtualbox/debian ${DEB_RELEASE} contrib"
    echo $APT > /etc/apt/sources.list.d/virtualbox.list
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | apt-key add -
    wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | apt-key add -
    apt-get update
    apt-get -y install virtualbox-5.0
}

function install_vagrant {
    cd $TEMPDIR
    wget https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.deb || return 1
    dpkg -i vagrant_${VAGRANT_VERSION}_x86_64.deb || return 1
}

function install_ansible {
    apt-get -y install python-pip python-dev libssl-dev || return 1
    pip install cffi || return 1
    pip install paramiko PyYAML Jinja2 httplib2 six markupsafe cryptography || return 1
    pip install ansible || return 1
}

install_virtualbox || error_exit
install_vagrant || error_exit
install_ansible || error_exit
finished
