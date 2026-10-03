#!/usr/bin/env bash

set -euo pipefail

# Enable the flathub repo
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Export list of installed applications
APP_LIST="${XDG_CONFIG_HOME}/flatpak/apps.txt"
flatpak list --columns=ref >> $APP_LIST

# Remove duplicates
sort -u -o $APP_LIST $APP_LIST

# Install applications
cat $APP_LIST | xargs -n 1 flatpak install flathub
