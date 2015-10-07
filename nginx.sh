#!/usr/bin/env bash

# nginx bootstrap install script


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

# check if apache is installed & purge
if $(hash httpd 2>/dev/null) || $(hash apache 2>/dev/null) || $(hash apache2 2>/dev/null); then
  read -p "Apache is installed. Remove it? [Y/n] " -s -n 1 -r; echo
  if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
    echo "Purging Apache..."
    echo
    service apache2 stop >/dev/null 2>&1
    apt-get purge -y apache2* >/dev/null 2>&1
    if [ $(ls -1 /var/www/html/ | wc -l) == 1 ] && [ -f /var/www/html/index.html ]; then
      rm -rf /var/www/html
    fi
  fi
fi

# choose between nginx flavors and install
if $(hash nginx 2>/dev/null); then
  echo "nginx is already installed, quitting..."
  exit 1
else
  echo "Choose your nginx flavor."
  PS3="
Make a selection: "
  options=("nginx-core" "nginx-light" "nginx-full" "nginx-extras")
  select opt in "${options[@]}"
  do
    case $opt in
      "nginx-core")
        echo "Installing nginx-core..."
        apt-get install -y nginx-core > /dev/null
        echo "Done."
        break
        ;;
      "nginx-light")
        echo "Installing nginx-light..."
        apt-get install -y nginx-light > /dev/null
        echo "Done."
        break
        ;;
      "nginx-full")
        echo "Installing nginx-full..."
        apt-get install -y nginx-full > /dev/null
        echo "Done."
        break
        ;;
      "nginx-extras")
        echo "Installing nginx-extras..."
        apt-get install -y nginx-extras  > /dev/null
        echo "Done."
        break
        ;;
      *) echo "Invalid option";;
    esac
  done
fi


# website folder in /var/www
echo
read -p "Create nginx root folder? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  read -p "Enter root folder name: " NGINXROOTFOLDER
  read -p "Which user do you want to own the folder? " CHOWNUSER
  # validate the user
  while ! id -u "$CHOWNUSER" >/dev/null 2>&1; do
    read -p "No such user. Please enter a valid user of this system: " CHOWNUSER
  done

  mkdir -p /var/www/$NGINXROOTFOLDER/html
  chown -R $CHOWNUSER:$CHOWNUSER /var/www/$NGINXROOTFOLDER/html
  chmod -R 755 /var/www
  echo "Done."
fi


# basic server settings
echo
read -p "Replace default server settings? [Y/n] " -s -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ || $REPLY == "" ]]; then
  wget -q https://raw.githubusercontent.com/epistrephein/serverscripts/master/nginx/default-nginx-settings -O /etc/nginx/sites-available/$NGINXROOTFOLDER
  sed -i 's/NGINXROOTFOLDER/'"$NGINXROOTFOLDER"'/g' /etc/nginx/sites-available/$NGINXROOTFOLDER

  echo "Created virtual host /etc/nginx/sites-available/$NGINXROOTFOLDER"

  ln -s /etc/nginx/sites-available/$NGINXROOTFOLDER /etc/nginx/sites-enabled/
  rm /etc/nginx/sites-enabled/default

  if [ -f /usr/share/nginx/html/index.html ]; then
    cp /usr/share/nginx/html/index.html /var/www/$NGINXROOTFOLDER/html/index.html
  elif [ -f /usr/share/nginx/www/index.html ]; then
    cp /usr/share/nginx/www/index.html /var/www/$NGINXROOTFOLDER/html/index.html
  fi
fi

echo "Restarting nginx..."
service nginx restart >/dev/null

# autoremove script
[ -f $0 ] && rm -- "$0"
