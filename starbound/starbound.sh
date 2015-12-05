#!/usr/bin/env bash

# starbound server install script

# if interrupted, remove script file
trap cleanup SIGINT
function cleanup() {
  [ -f $0 ] && rm -- "$0"
  stty echo
  echo
  exit 1
}

# check if root
if [[ $EUID -ne 0 ]]; then
  { echo "This script must be run as root." >&2; }
  [ -f $0 ] && rm -- "$0"
  exit 1
fi

# get architecture
if [ $(uname -m) == "i686" ]; then
  ARCH="x86"
elif [ $(uname -m) == "x86_64" ]; then
  ARCH="amd64"
else
  echo "Unsupported architecture $(uname -m)."
  [ -f $0 ] && rm -- "$0"
  exit 1
fi

echo "Installing SteamCMD"
# required library for Steam
dpkg -s lib32gcc1 >/dev/null 2>&1 || apt-get install -y lib32gcc1 >/dev/null
id -u >/dev/null 2>&1 "starbound" || adduser --disabled-login --gecos "" --quiet starbound
su -c "mkdir ~/steamcmd && cd ~/steamcmd; wget -q http://media.steampowered.com/client/steamcmd_linux.tar.gz && tar -xzf steamcmd_linux.tar.gz && rm steamcmd_linux.tar.gz" starbound
su -c "cd ~/steamcmd && ./steamcmd.sh +quit" starbound >/dev/null

# login to Steam and download Starbound
read -p "Enter Steam username: " STEAMUSER
read -s -p "Enter $STEAMUSER password: " STEAMPASSWORD; echo

echo | su -c "cd ~/steamcmd && ./steamcmd.sh +login $STEAMUSER $STEAMPASSWORD +quit" starbound >/dev/null
if [ $? -eq 0 ]; then
  echo "Installing Starbound. It may take a bit."
  su -c "cd ~/steamcmd && ./steamcmd.sh +login $STEAMUSER $STEAMPASSWORD +force_install_dir /home/starbound/starbound +app_update 211820 +quit" starbound >/dev/null
else
  echo "Wrong password or SteamGuard active, running interactively"
  sleep 2
  su -c "cd ~/steamcmd && ./steamcmd.sh +login $STEAMUSER +force_install_dir /home/starbound/starbound +app_update 211820 +quit" starbound
  echo
fi

# create init script
echo "Creating service"
wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/starbound/starbound-init.sh -O /etc/init.d/starbound_server
chmod +x /etc/init.d/starbound_server
[ "$ARCH" == "i686" ] && sed -i 's/linux64/linux32/g' /etc/init.d/starbound_server
update-rc.d starbound_server defaults >/dev/null 2>&1

# allow ufw port
hash ufw 2>/dev/null && echo "Allowing port 21025 on UFW" && ufw allow 21025/tcp >/dev/null

# start service
service starbound_server start
echo "Run tail -f /home/starbound/starbound/giraffe_storage/starbound_server.log to monitor the server."

# autoremove script
[ -f $0 ] && rm -- "$0"
