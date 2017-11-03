#!/bin/bash

PREFIX='git clone git@github.com:evpo'
declare -A dotdirs
dotdirs=( 
[zsh-config.git]=.zsh 
[tmux-config.git]=.tmux
[vim-config.git]=.vim
[gdb-config.git]=.gdb)

pushd $HOME
for k in ${!dotdirs[@]}
do
  dir=${dotdirs[$k]}
  $PREFIX/$k $dir
  if [ -x $dir/install.sh ]; then
    pushd $dir
    ./install.sh
    popd
  fi
done
popd
