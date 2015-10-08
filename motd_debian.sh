#!/usr/bin/env bash

# MOTD changer script for Debian


# check if Debian
if [[ "$(python -mplatform)" !=  *"debian"* ]]; then
  { echo "This script requires Debian." >&2; }
  exit 1
fi

# check if root
if [[ $EUID -ne 0 ]]; then
  { echo "This script must be run as root." >&2; }
  exit 1
fi

# create motd folder
[ ! -d /etc/update-motd.d/ ] && mkdir /etc/update-motd.d/

# add header with distro infos
if [ ! -f /etc/update-motd.d/10-header ]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd/10-header -O /etc/update-motd.d/10-header
  chmod +x /etc/update-motd.d/10-header
  echo "Added distribution infos header"
fi

# add banner file
if [ ! -f /etc/update-motd.d/20-banner ]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd/20-banner -O /etc/update-motd.d/20-banner
  chmod +x /etc/update-motd.d/20-banner
  echo "Added banner (customize /etc/update-motd.d/20-banner)"
fi

# add system info clone of ubuntu landscape
if [ ! -f /etc/update-motd.d/50-sysinfo ]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd/50-sysinfo -O /etc/update-motd.d/50-sysinfo
  chmod +x /etc/update-motd.d/50-sysinfo
  echo "Added system information"
fi

# add footer
if [ ! -f /etc/update-motd.d/90-footer ]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd/90-footer -O /etc/update-motd.d/90-footer
  chmod +x /etc/update-motd.d/90-footer
  echo "Added footer"
fi

# remove previous motd and link new one
[ -f /etc/motd ] && rm /etc/motd
rm -f /var/run/motd.dynamic
sed -i 's|uname -snrvm > /var/run/motd.dynamic|> /var/run/motd.dynamic|' /etc/init.d/motd
ln -s /var/run/motd /etc/motd

# autoremove script
[ -f $0 ] && rm -- "$0"
