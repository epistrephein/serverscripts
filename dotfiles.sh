#!/usr/bin/env bash

curl -sL https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/.bashrc >> $HOME/.bashrc
curl -sL https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/.inputrc >> $HOME/.inputrc 
mkdir -p $HOME/.vim/colors
curl -sL -o $HOME/.vim/colors/rdark.vim https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/rdark.vim
curl -sL https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/.vimrc > $HOME/.vimrc

# autoremove script
rm -- "$0"
