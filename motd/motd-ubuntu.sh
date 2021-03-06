#!/usr/bin/env bash

# check if root
if [[ $EUID -ne 0 ]]; then
  { echo "This script must be run as root." >&2; }
  exit 1
fi

# remove documentation info
if [ -f /etc/update-motd.d/10-help-text ]; then
  sed -i 's/^printf/# printf/' /etc/update-motd.d/10-help-text
  echo "Removed Ubuntu documentation info"
fi

# remove landscape footnote notice
if [ -f /usr/lib/python2.7/dist-packages/landscape/sysinfo/landscapelink.py ]; then
  sed -i 's/^        self._sysinfo.add_footnote/#       self._sysinfo.add/' /usr/lib/python2.7/dist-packages/landscape/sysinfo/landscapelink.py
  sed -i 's/^            \"Graph this data/#           \"Graph this data/' /usr/lib/python2.7/dist-packages/landscape/sysinfo/landscapelink.py
  sed -i 's/^            \"    https/#           \"    https/' /usr/lib/python2.7/dist-packages/landscape/sysinfo/landscapelink.py
  echo "Removed landscape notice"
fi

# remove cloud guest notice
if [ -f /etc/update-motd.d/51-cloudguest ]; then
  rm /etc/update-motd.d/51-cloudguest
  echo "Removed Ubuntu Cloud Guest notice"
fi

# remove overlayroot
if [ -f /etc/update-motd.d/97-overlayroot ]; then
  chmod -x /etc/update-motd.d/97-overlayroot
  echo "Removed overlay root"
fi

# add banner file
if [ ! -f /etc/update-motd.d/20-banner ]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd/20-banner-ubuntu -O /etc/update-motd.d/20-banner
  chmod +x /etc/update-motd.d/20-banner
  echo "Added banner (customize /etc/update-motd.d/20-banner)"
fi

# autoremove script
[ -f "$0" ] && rm -- "$0"
