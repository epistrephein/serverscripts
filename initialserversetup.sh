#!/usr/bin/env bash

# Initial server setup script for Ubuntu
# based on Digital Ocean's setup tutorials
# converted to bash script by Tommaso Barbato (@epistrephein)
# https://github.com/epistrephein/serverscripts
#
# be careful with what you execute in your shell!
# double check this script to make sure you understand what it does
#
# usage: wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/initialserversetup.sh; bash initialserversetup.sh
# short version: wget -q git.io/ubuntuserver; bash ubuntuserver

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

echo
echo "====================================="
echo "     Initial Server Setup Script     "
echo "====================================="
echo

## update packages
echo "Updating packages index"
apt-get update > /dev/null

# essentials packages
hash curl 2>/dev/null || apt-get install -y curl > /dev/null
hash wget 2>/dev/null || apt-get install -y wget > /dev/null
hash vim 2>/dev/null || apt-get install -y vim > /dev/null
hash add-apt-repository 2>/dev/null || apt-get install -y software-properties-common > /dev/null

# useful packages
hash pwgen 2>/dev/null || apt-get install -y pwgen > /dev/null
hash autojump 2>/dev/null || apt-get install -y autojump > /dev/null

echo "Done."


## users options
echo
echo "==== Configuring users ===="

# create new user
read -p "Create new user? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  read -p "Enter new user: " NEWUSER
  echo "Here's a newly generated password you can use: ==>  `pwgen -s 13 1`  <=="; echo
  adduser --gecos "" $NEWUSER
  gpasswd -a $NEWUSER sudo

  # passwordless sudo
  echo
  read -p "Enable passwordless sudo? [Y/n] " -s -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
    echo "$NEWUSER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  fi
  echo "Done."

  # add ssh key authentication and public keys
  echo
  read -p "Add SSH public key auth? [Y/n] " -s -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
    su $NEWUSER -c "cd; mkdir .ssh; chmod 700 .ssh; touch .ssh/authorized_keys; chmod 600 .ssh/authorized_keys"

    SSHKEY=0
    until [ -z "$SSHKEY" ]; do 
      read -p "Paste the SSH public key, empty to quit: " SSHKEY
      echo "$SSHKEY" >> /home/$NEWUSER/.ssh/authorized_keys
    done
  fi
fi


## security options
echo
echo "==== Configuring security ===="

# change default ssh port
SSHRESTART=0
read -p "Change SSH port? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  read -p "Enter port for SSH: " SSHPORT
  VALIDINPUT='^[0-9]+$'
  until [[ ! -z "$SSHPORT" && $SSHPORT =~ $VALIDINPUT ]]; do
    read -p "Invalid input. Please insert a number: " SSHPORT
  done
  sed -i "s/Port 22/Port $SSHPORT/g" /etc/ssh/sshd_config
  SSHRESTART=1
fi

# change ssh login policy
read -p "Prevent root login and password authentication? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  sed -i 's/PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
  sed -i 's/\#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
  SSHRESTART=1
fi

if [ $SSHRESTART == 1 ]; then
  echo "Restarting ssh service..."
  service ssh restart
  echo "Done."
fi

# configure ufw
echo
read -p "Enable ufw? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  hash ufw 2>/dev/null || { echo "Installing ufw"; apt-get install -y ufw > /dev/null; }
  printf "Insert ports to allow (separated by space): "; read -a ALLOWEDPORTS
  VALIDINPUT='^[0-9]+$'
  for p in ${ALLOWEDPORTS[@]}
  do
    if [[ $p =~ $VALIDINPUT ]]; then
      ufw allow $p/tcp
    else
      echo "$p is not a valid port number"
    fi
  done
  [ ! -z "$SSHPORT" ] && ufw allow $SSHPORT/tcp || ufw allow `cat /etc/ssh/sshd_config | grep Port | head -1 | cut -c 6-`/tcp
  ufw show added
  printf "Starting ufw... "; ufw enable
  echo "Done."
fi

# install fail2ban
echo
read -p "Enable fail2ban? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  hash fail2ban 2>/dev/null || { echo "Installing fail2ban"; apt-get install -y fail2ban > /dev/null; }
  echo "Applying basic fail2ban configuration"
  cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
  sed -i 's/bantime *= *600/bantime = 1800/g' /etc/fail2ban/jail.local
  echo "Starting fail2ban"
  service fail2ban restart
  echo "Done."
fi


## timezone options
echo
echo "==== Timezone settings ===="

# change timezone
read -p "Reconfigure timezone [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  dpkg-reconfigure tzdata
  echo "Installing NTP"
  apt-get install -y ntp > /dev/null
  echo "Done."
fi


## swap options
echo
echo "==== Configuring swap ===="

# add swap file
read -p "Add swap file? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  read -p "Swap file in GB: " SWAPSIZE
  SWAPSIZE+="G"
  fallocate -l $SWAPSIZE /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
  echo "Done."
fi


## system options
echo
echo "==== Configuring system ===="

# dotfiles
read -p "Apply basic dotfiles? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  if [ ! -z "$NEWUSER" ]; then
    su $NEWUSER -c "cd; wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles.sh; bash dotfiles.sh"
  fi
  echo "Done."
fi

# change motd
echo
read -p "Clean up the default motd and add a banner? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd.sh; bash motd.sh
  echo "Done."
fi


echo
echo "All done. Bye!"
echo

# autoremove script
rm -- "$0"
