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


function install_uwsgi {
    apt-get -y install \
        python-pip \
        python-dev
    pip install uwsgi
}


function post_install {
    echo "Running post-install configuration..."

    CONFDIR="/etc/uwsgi"
    VASSALSDIR="$CONFDIR/vassal"

    if [ ! -d $CONFDIR ]; then
        mkdir $CONFDIR
    fi

    if [ ! -d $VASSALSDIR ]; then
        mkdir $VASSALSDIR
    fi

    cd $BASEDIR
    cp uwsgi/uwsgi.service /lib/systemd/system/uwsgi.service || return 1
    cp uwsgi/emperor.ini $CONFDIR/emperor.ini
    
    return 0
}

function start_uwsgi {
    echo "(re)starting UWSGI service..."
    systemctl daemon-reload
    service uwsgi stop
    service uwsgi start
}

##############################################################################
# TASKS

install_uwsgi || error_exit
post_install || error_exit
start_uwsgi || error_exit
finished
