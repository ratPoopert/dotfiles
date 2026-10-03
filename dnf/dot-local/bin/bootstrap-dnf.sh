#!/usr/bin/env bash

set -euo pipefail

# Append currently installed packages to the package list
PACKAGE_LIST="$XDG_CONFIG_HOME/dnf/packages.txt"
mkdir -p $(dirname $PACKAGE_LIST)
dnf repoquery --userinstalled --queryformat '%{name}\n' >> $PACKAGE_LIST

# Remove duplicates
sort -u -o $PACKAGE_LIST $PACKAGE_LIST

# Install all packages
sudo dnf install -y -q $(cat $PACKAGE_LIST)
