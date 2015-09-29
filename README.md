# Server Scripts
Quickly bootstrap a barebone Ubuntu or Debian server. 

## Usage
Simply run this command from root:

    wget -q git.io/serverinit; bash serverinit

## Features

    * Run `apt-get update`.
    * Install basic utilities (sudo, curl, wget and vim) and some extra packages (htop, autojump). On Debian, install also debian-keyring and debian-archive-keyring.
    * Create a new user without password and with sudo privileges. Requires one or more SSH public keys.
    * Change the default SSH port for extra safety.
    * Prevent root login and password authentication via SSH.
    * Install/enable UFW.
    * Install/enable fail2ban.
    * Reconfigure the timezone and install NTP.
    * Add a swap file.
    * Apply some basic dotfiles (specifically .bashrc, .inputrc, .vimrc and a vim theme).
    * Cleanup the MOTD and add a customizable banner for ASCII art.

## Errors
Here are some common errors (with solutions) you may encounter on new servers.

    error: Could not load host key: /etc/ssh/ssh_host_ecdsa_key

Solution: Regenerate SSH host keys

    $ sudo rm -r /etc/ssh/ssh*key
    $ sudo dpkg-reconfigure openssh-server

***

    -su: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)

Solution: Generate missing locales

    $ export LANGUAGE=en_US.UTF-8
    $ export LANG=en_US.UTF-8
    $ export LC_ALL=en_US.UTF-8
    $ locale-gen en_US.UTF-8
    $ dpkg-reconfigure locales
