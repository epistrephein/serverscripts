#!/usr/bin/env bash

curl -sL https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/.bashrc >> $HOME/.bashrc
curl -sL https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/.inputrc >> $HOME/.inputrc 
mkdir -p $HOME/.vim/colors
curl -sL -o $HOME/.vim/colors/rdark-terminal.vim https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/rdark-terminal.vim
curl -sL https://raw.githubusercontent.com/epistrephein/serverscripts/master/dotfiles/.vimrc > $HOME/.vimrc
