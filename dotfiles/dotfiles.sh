#!/usr/bin/env bash

curl -sL https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/.bashrc >> $HOME/.bashrc
echo "Updated .bashrc"

curl -sL https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/.inputrc >> $HOME/.inputrc 
echo "Updated .inputrc"

[ ! -d $HOME/.vim/colors ] && mkdir -p $HOME/.vim/colors
curl -sL -o $HOME/.vim/colors/rdark.vim https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/rdark.vim
echo "Installed rdark vim theme"

curl -sL https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/.vimrc > $HOME/.vimrc
echo "Updated .vimrc"

# autoremove script
[ -f $0 ] && rm -- "$0"
