#!/bin/ksh
export LANG=ja_JP.UTF-8
export TZ=JST-9
export SHELL=/usr/bin/ksh
export ENV=$HOME/.kshrc
export PS1=`whoami`['$PWD']\$
screen -U -t local
