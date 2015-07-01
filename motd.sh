#!/usr/bin/env bash

# check if Ubuntu
if [[ "$(python -mplatform)" !=  *"Ubuntu"* ]]; then
  >&2 echo "This script requires Ubuntu."
  exit 1
fi

# check if root
if [[ $EUID -ne 0 ]]; then
  >&2 echo "This script must be run as root."
  exit 1
fi

# remove documentation info
if [ -f /etc/update-motd.d/10-help-text ]; then
  sed -i "s/^printf/# printf/g" /etc/update-motd.d/10-help-text
  echo "Removing Ubuntu documentation info"
fi

# remove landscape footnote notice
if [ -f /usr/lib/python2.7/dist-packages/landscape/sysinfo/landscapelink.py ]; then
  sed -i "s/^        self._sysinfo.add_footnote/#       self._sysinfo.add/g" /usr/lib/python2.7/dist-packages/landscape/sysinfo/landscapelink.py
  sed -i "s/^            \"Graph this data/#           \"Graph this data/g" /usr/lib/python2.7/dist-packages/landscape/sysinfo/landscapelink.py
  sed -i "s/^            \"    https/#           \"    https/g" /usr/lib/python2.7/dist-packages/landscape/sysinfo/landscapelink.py
  echo "Removing landscape notice"
fi

# remove cloud guest notice
if [ -f /etc/update-motd.d/51-cloudguest ]; then
  rm /etc/update-motd.d/51-cloudguest
  echo "Removing Ubuntu Cloud Guest notice"
fi

# add banner file
if [ ! -f /etc/update-motd.d/20-banner ]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd/20-banner
  chmod +x /etc/update-motd.d/20-banner
  echo "Adding banner (remember to customize the file /etc/update-motd.d/20-banner)"
fi

# autoremove script
rm -- "$0"