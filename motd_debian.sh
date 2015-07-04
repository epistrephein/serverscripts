#!/usr/bin/env bash

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

[ ! -d /etc/update-motd.d/ ] && mkdir /etc/update-motd.d/

if [ ! -f /etc/update-motd.d/10-header ]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd/10-header -O /etc/update-motd.d/10-header
  chmod +x /etc/update-motd.d/10-header
  echo "Added distribution infos header"
fi

if [ ! -f /etc/update-motd.d/20-banner ]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd/20-banner -O /etc/update-motd.d/20-banner
  chmod +x /etc/update-motd.d/20-banner
  echo "Added banner (customize /etc/update-motd.d/20-banner)"
fi

if [ ! -f /etc/update-motd.d/50-sysinfo ]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd/50-sysinfo -O /etc/update-motd.d/50-sysinfo
  chmod +x /etc/update-motd.d/50-sysinfo
  echo "Added system information"
fi

if [ ! -f /etc/update-motd.d/90-footer ]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd/90-footer -O /etc/update-motd.d/90-footer
  chmod +x /etc/update-motd.d/90-footer
  echo "Added footer"
fi

[ -f /etc/motd ] && rm /etc/motd
[ -f /var/run/motd.dynamic ] && rm /var/run/motd.dynamic
ln -s /var/run/motd /etc/motd

# autoremove script
[ -f $0 ] && rm -- "$0"