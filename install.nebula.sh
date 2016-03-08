#!/bin/bash
#
# Copyright (c) 2016 imm studios, z.s.
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

DB_USER="nebula"
DB_PASS="nebula1"
DB_NAME="nebula"

SCRIPT_PATH="/tmp/nebula.sql"

function install_prerequisites {
    apt-get -y install \
        python-pip \
        python-psycopg2
}

function create_user {
    echo "
        DROP DATABASE IF EXISTS ${DB_NAME};
        DROP USER IF EXISTS ${DB_USER};
        CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';
    " > ${SCRIPT_PATH}
    su postgres -c "psql --file=${SCRIPT_PATH}"
    rm ${SCRIPT_PATH}
}

function create_db {
    echo "
        DROP DATABASE IF EXISTS ${DB_NAME};
        CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};
        CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;
    " > ${SCRIPT_PATH}
    su postgres -c "psql --file=${SCRIPT_PATH}"
    rm ${SCRIPT_PATH}
}

function create_schema {
    export PGPASSWORD="${DB_PASS}";
    psql -h localhost -U ${DB_USER} nebula --file=i${BASEDIR}/nebula/schema.sql
}

echo ""
echo ""

#create_user
#create_db
create_schema
