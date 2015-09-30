#!/usr/bin/env bash

# Initial server setup script for Ubuntu and Debian
# based on Digital Ocean's setup tutorials 
# converted to bash script by Tommaso Barbato (@epistrephein)
# https://github.com/epistrephein/serverscripts

# be careful with what you execute in your shell!
# double check this script to make sure it does what you expect

# -------------------------------------------------
# usage: wget -q git.io/serverinit; bash serverinit
# -------------------------------------------------


# if interrupted, remove script file
trap cleanup SIGINT
function cleanup() {
  [ -f $0 ] && rm -- "$0"
  stty echo
  echo
  echo "Aborted."
  exit 1
}

# check if Ubuntu/Debian
if [[ "$(python -mplatform)" !=  *"Ubuntu-14"* ]] && [[ "$(python -mplatform)" !=  *"Ubuntu-12"* ]] && [[ "$(python -mplatform)" !=  *"debian-7"* ]] && [[ "$(python -mplatform)" !=  *"debian-8"* ]]; then
  { echo "This script requires Ubuntu or Debian." >&2; }
  [ -f $0 ] && rm -- "$0"
  exit 1
fi

DISTRO=$(python -mplatform | grep -io --color=never 'debian\|ubuntu' | tr '[:upper:]' '[:lower:]')

# check if root
if [[ $EUID -ne 0 ]]; then
  { echo "This script must be run as root." >&2; }
  [ -f $0 ] && rm -- "$0"
  exit 1
fi

echo
echo "====================================="
echo "     Initial Server Setup Script     "
echo "====================================="
echo

## update packages
echo "Updating packages index..."
apt-get update >/dev/null

# install essentials packages
hash sudo 2>/dev/null || apt-get install -y sudo >/dev/null
hash curl 2>/dev/null || apt-get install -y curl >/dev/null
hash wget 2>/dev/null || apt-get install -y wget >/dev/null
hash vim 2>/dev/null || { apt-get install -y vim >/dev/null; rm /usr/bin/vi; ln -s /usr/bin/vim /usr/bin/vi; }

if [ "$DISTRO" == "debian" ]; then
  dpkg -s debian-keyring >/dev/null 2>&1 || apt-get install -y debian-keyring >/dev/null
  dpkg -s debian-archive-keyring >/dev/null 2>&1 || apt-get install -y debian-archive-keyring >/dev/null
fi

# install useful packages
hash htop 2>/dev/null || apt-get install -y htop >/dev/null
hash autojump 2>/dev/null || apt-get install -y autojump >/dev/null

echo "Done."


## users options
echo
echo "==== Configuring users ===="

# create new sudo user without password
read -p "Create new user? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  read -p "Enter new user: " NEWUSER
  echo "Creating user $NEWUSER without password"
  adduser --gecos "" --disabled-password --quiet $NEWUSER
  gpasswd -a $NEWUSER sudo

  echo "$NEWUSER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

  # ssh key authentication
  echo
  su $NEWUSER -c "cd; mkdir .ssh; chmod 700 .ssh; touch .ssh/authorized_keys; chmod 600 .ssh/authorized_keys"

  SSHKEY=0
  until [ -z "$SSHKEY" ]; do
    read -p "Paste the SSH public key, empty to finish: " SSHKEY
    if [ -z "$SSHKEY" ] && [ ! -s /home/$NEWUSER/.ssh/authorized_keys ]; then
      echo "You haven't added any key. You can't skip this step, otherwise you won't be able to login."
      SSHKEY=0
    else
      echo "$SSHKEY" >> /home/$NEWUSER/.ssh/authorized_keys
    fi
  done
  echo "Done."
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
  sed -i -e "/^Port/s/^.*$/Port $SSHPORT/" /etc/ssh/sshd_config
  SSHRESTART=1
fi

# change ssh login policy
echo
read -p "Prevent root login? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  sed -i -e '/^PermitRootLogin/s/^.*$/PermitRootLogin no/' /etc/ssh/sshd_config
  sed -i -e '/^#PasswordAuthentication/s/^.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
  SSHRESTART=1
fi

if [ $SSHRESTART == 1 ]; then
  echo "Restarting ssh service..."
  service ssh restart >/dev/null
  echo "Done."
fi

# configure ufw
echo
read -p "Enable ufw? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  hash ufw 2>/dev/null || { echo "Installing ufw..."; apt-get install -y ufw >/dev/null; }
  printf "Insert ports to allow (separated by space): "; read -a ALLOWEDPORTS
  VALIDINPUT='^[0-9]+$'
  for p in ${ALLOWEDPORTS[@]}
  do
    if [[ $p =~ $VALIDINPUT ]]; then
      ufw allow $p/tcp >/dev/null
      echo "Allow port: $p"
    else
      echo "$p is not a valid port number, skipping"
    fi
  done

  SSHDCONFIGPORT=$(grep --color=never Port /etc/ssh/sshd_config | head -1 | cut -c 6-)

  if [ ! -z "$SSHPORT" ] && ! [[ " ${ALLOWEDPORTS[@]} " =~ " ${SSHPORT} " ]]; then
    ufw allow $SSHPORT/tcp >/dev/null
    echo "Allow port: $SSHPORT (auto-added)"
  elif [ -z "$SSHPORT" ] && ! [[ " ${ALLOWEDPORTS[@]} " =~ " ${SSHDCONFIGPORT} " ]]; then
    ufw allow $SSHDCONFIGPORT/tcp >/dev/null
    echo "Allow port: $SSHDCONFIGPORT (auto-added)" 
  fi
  echo "Starting ufw... "; echo y | ufw enable >/dev/null
  echo "Done."
fi

# install fail2ban
echo
read -p "Enable fail2ban? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  hash fail2ban 2>/dev/null || { echo "Installing fail2ban..."; apt-get install -y fail2ban >/dev/null; }
  echo "Applying basic fail2ban configuration..."
  cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
  sed -i 's/bantime *= *600/bantime = 1800/g' /etc/fail2ban/jail.local
  echo "Starting fail2ban..."
  service fail2ban restart >/dev/null
  echo "Done."
fi


## timezone options
echo
echo "==== Timezone settings ===="

# change timezone
read -p "Reconfigure timezone [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  dpkg-reconfigure tzdata
  echo "Installing NTP..."
  apt-get install -y ntp >/dev/null
  echo "Done."
fi


## swap options
echo
echo "==== Configuring swap ===="

# add swap file
read -p "Add swap file? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  read -p "Swap file in GB: " SWAPSIZE
  VALIDINPUT='^[0-9]+$'
  while ! [[ $SWAPSIZE =~ $VALIDINPUT ]]; do
    read -p "Invalid input. Please insert a number: " SWAPSIZE
  done
  SWAPSIZE+="G"
  fallocate -l $SWAPSIZE /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  sh -c 'echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab'
  echo "Done."
fi


## system options
echo
echo "==== Configuring system ===="

# set vim as default editor
update-alternatives --set editor /usr/bin/vim.basic >/dev/null

# dotfiles
read -p "Apply basic dotfiles? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  if [ ! -z "$NEWUSER" ]; then
    su $NEWUSER -c "curl -s https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles.sh | bash 1>/dev/null"
  fi
    curl -s https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles.sh | bash 1>/dev/null
  echo "Done."
fi

# change motd
echo
read -p "Clean up MOTD and add a banner? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  if [ "$DISTRO" == "debian" ]; then
    curl -s https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd_debian.sh | bash 1>/dev/null
    if [[ "$(python -mplatform)" ==  *"debian-7"* ]]; then
      dpkg -s update-notifier-common >/dev/null 2>&1 || apt-get install -y update-notifier-common >/dev/null
    elif [[ "$(python -mplatform)" ==  *"debian-8"* ]]; then
      sed -i '$ d' /etc/update-motd.d/50-sysinfo
      sed -i '$ d' /etc/update-motd.d/50-sysinfo
    fi
  elif [ "$DISTRO" == "ubuntu" ]; then
    curl -s https://raw.githubusercontent.com/epistrephein/serverscripts/master/motd_ubuntu.sh | bash 1>/dev/null
  fi
  read -p "Customize the banner now? [y/N] " -s -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    vim /etc/update-motd.d/20-banner
  fi
  echo "Done."
fi

if [ ! -z "$NEWUSER" ]; then
  export $NEWUSER
fi

echo
echo "All done. Bye!"
echo

# autoremove script
[ -f $0 ] && rm -- "$0"
