#!/bin/sh
# Run this to generate all the initial makefiles, etc.

srcdir=`dirname $0`
test -z "$srcdir" && srcdir=.

PKG_NAME="california"

which gnome-autogen.sh || {
    echo "You need to install gnome-common."
    exit 1
}

. gnome-autogen.sh
