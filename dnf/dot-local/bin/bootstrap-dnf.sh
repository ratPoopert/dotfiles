#!/usr/bin/env bash

set -euo pipefail

# Enable RPM Fusion (Free and Nonfree)
FEDORA=$(rpm -E %fedora)
sudo dnf install \
https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA}.noarch.rpm \
https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA}.noarch.rpm

# Install the copr plugin
sudo dnf install -y -q dnf-plugins-core

# Append enabled copr repos to the copr list
COPR_LIST="$XDG_CONFIG_HOME/dnf/copr.txt"
mkdir -p $(dirname $COPR_LIST)
dnf copr list >> $COPR_LIST

# Remove duplicates
sort -u -o $COPR_LIST $COPR_LIST

# Enable copr repos. Each repo must be passed to a separate command
# because the second argument is the chroot/architecture.
cat $COPR_LIST | xargs -n 1 sudo dnf copr enable -y

# Append currently installed packages to the package list
PACKAGE_LIST="$XDG_CONFIG_HOME/dnf/packages.txt"
mkdir -p $(dirname $PACKAGE_LIST)
dnf repoquery --userinstalled --queryformat '%{name}\n' >> $PACKAGE_LIST

# Remove duplicates
sort -u -o $PACKAGE_LIST $PACKAGE_LIST

# Install all packages
sudo dnf install -y -q $(cat $PACKAGE_LIST)
