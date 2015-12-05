# Server Scripts
Quickly bootstrap a barebone Ubuntu or Debian server. 

## Usage
Simply run this command from root:

    wget -q git.io/serverinit; bash serverinit

## Features

* Run `apt-get update`.
* Install basic utilities (`sudo`, `curl`, `wget` and `vim`) and some extra packages (`htop`, `autojump`). On Debian, install also `debian-keyring` and `debian-archive-keyring`.
* Create a new user without password and with sudo privileges. Requires one or more SSH public keys.
* Change the default SSH port for extra safety.
* Prevent root login and password authentication via SSH.
* Install/enable UFW.
* Install/enable fail2ban.
* Reconfigure the timezone and install NTP.
* Add a swap file.
* Apply some basic dotfiles (specifically `.bashrc`, `.inputrc`, `.vimrc` and a vim theme).
* Cleanup the MOTD and add a customizable banner for ASCII art.
* Install additional services and utilities.
