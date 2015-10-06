#!/usr/bin/env bash

# if interrupted, remove script file
trap cleanup SIGINT
function cleanup() {
  [ -f $0 ] && rm -- "$0"
  stty echo
  echo
  echo "Aborted."
  exit 1
}

# check if root
if [[ $EUID -ne 0 ]]; then
  { echo "This script must be run as root." >&2; }
  [ -f $0 ] && rm -- "$0"
  exit 1
fi

# check if apache is installed & purge
if $(hash httpd 2>/dev/null) || $(hash apache 2>/dev/null) || $(hash apache2 2>/dev/null); then
  read -p "Apache is installed. Remove it? [Y/n] " -s -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
    echo "Purging Apache..."
    service apache2 stop >/dev/null 2>&1
    apt-get purge -y apache2* >/dev/null
    if [ $(ls -1 /var/www/html/ | wc -l) == 1 ] && [ -f /var/www/html/index.html ]; then
      rm -rf /var/www/html
    fi
    echo "Done."
  fi
fi

# choose between nginx flavors and install
if $(hash nginx 2>/dev/null); then
  echo "nginx is already installed, skipping..."
else
  PS3='Choose your nginx flavor: '
  options=("core" "light" "full" "extras")
  select opt in "${options[@]}"
  do
    case $opt in
      "core")
        echo "Installing nginx-core..."
        apt-get install -y nginx-core > /dev/null
        break
        ;;
      "light")
        echo "Installing nginx-light..."
        apt-get install -y nginx-light > /dev/null
        break
        ;;
      "full")
        echo "Installing nginx-full..."
        apt-get install -y nginx-full > /dev/null
        break
        ;;
      "extras")
        echo "Installing nginx-extras..."
        apt-get install -y nginx-extras  > /dev/null
        break
        ;;
      *) echo invalid option;;
    esac
  done
fi


echo
read -p "Create nginx root folder? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  read -p "Enter root folder name: " NGINXROOTFOLDER

  # this variable should exist if the script is called from serverinit
  if [ -z $NEWUSER ]; then
    read -p "Which user do you want to own the folder? " CHOWNUSER
    # validate the user
    while ! id -u "$CHOWNUSER" >/dev/null 2>&1; do
      read -p "No such user. Please enter a valid user of this system: " CHOWNUSER
    done
  else
    CHOWNUSER=$NEWUSER
  fi

  mkdir -p /var/www/$NGINXROOTFOLDER/html
  chown -R $CHOWNUSER:$CHOWNUSER /var/www/$NGINXROOTFOLDER/html
  chmod -R 755 /var/www
  echo "Done."
fi

echo
read -p "Replace default server settings? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  cat << EOF >> /etc/nginx/sites-available/$NGINXROOTFOLDER
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    root /var/www/$NGINXROOTFOLDER/html;
    index index.html index.htm;

    server_name $NGINXROOTFOLDER;

    access_log  /var/log/nginx/$NGINXROOTFOLDER.access.log;
    error_log   /var/log/nginx/$NGINXROOTFOLDER.error.log;

    location / {
        try_files $uri $uri/ =404;
    }
}
  EOF

  echo "Created virtual host /etc/nginx/sites-available/$NGINXROOTFOLDER"

  ln -s /etc/nginx/sites-available/$NGINXROOTFOLDER /etc/nginx/sites-enabled/
  rm /etc/nginx/sites-enabled/default

  # can also be /usr/share/nginx/www/index.html
  cp /usr/share/nginx/html/index.html /var/www/$NGINXROOTFOLDER/html/index.html
fi

echo "Restarting nginx..."
service nginx restart >/dev/null

echo "Done."

# autoremove script
[ -f $0 ] && rm -- "$0"
