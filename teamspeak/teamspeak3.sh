#!/usr/bin/env bash

# teamspeak3 server install script


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
  echo "Unable to retrieve platform architecture."
  PS3="
Choose manually: "
  options=("i686 (x86)" "x86_64 (amd64)")
  select opt in "${options[@]}"
  do
    case $opt in
      "i686 (x86)")
        ARCH="x86"
        break
        ;;
      "x86_64 (amd64)")
        ARCH="amd64"
        break
        ;;
      *) echo "Invalid option";;
    esac
  done
fi

# fetch teamspeak server latest stable release
# (stolen from https://github.com/TS3Tools/TS3UpdateScript)
wget 'http://dl.4players.de/ts/releases/?C=M;O=D' -q -O - | grep -i dir | grep -Eo '<a href=\".*\/\">.*\/<\/a>' | grep -Eo '[0-9\.?]+' | uniq | sort -V -r > TS3_STABLE_RELEASES.txt

while read release; do
  wget --spider -q http://dl.4players.de/ts/releases/${release}/teamspeak3-server_linux-amd64-${release}.tar.gz
  if [[ $? == 0 ]]; then
    LATEST="$release"
    break
  fi
done < TS3_STABLE_RELEASES.txt

rm TS3_STABLE_RELEASES.txt

# install teamspeak server
echo "Downloading latest teamspeak server"
wget -q http://ftp.4players.de/pub/hosted/ts3/releases/"$LATEST"/teamspeak3-server_linux-"$ARCH"-"$LATEST".tar.gz
id -u >/dev/null 2>&1 "teamspeak3" || adduser --disabled-login --gecos "" --quiet teamspeak3
tar xzf teamspeak3-server_linux-"$ARCH"-"$LATEST".tar.gz
rm teamspeak3-server_linux-"$ARCH"-"$LATEST".tar.gz
mv teamspeak3-server_linux-"$ARCH" /usr/local/teamspeak3
chown -R teamspeak3 /usr/local/teamspeak3

# create init script
echo "Creating service"
cat <<'EOF' > /etc/init.d/teamspeak3
#!/bin/sh

su -c "/usr/local/teamspeak3/ts3server_startscript.sh $@" teamspeak3
EOF
chmod u+x /etc/init.d/teamspeak3
update-rc.d teamspeak3 defaults >/dev/null 2>&1

# allow ufw port
hash ufw 2>/dev/null && echo "Allowing port 9987 on UFW" && ufw allow 9987/udp >/dev/null

# start service
service teamspeak3 start
sleep 10

# autoremove script
[ -f $0 ] && rm -- "$0"
