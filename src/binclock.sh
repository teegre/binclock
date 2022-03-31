#! /usr/bin/env bash

#  ____  _        _____ _            _    
# |  _ \(_)      / ____| |          | |   
# | |_) |_ _ __ | |    | | ___   ___| | __
# |  _ <| | '_ \| |    | |/ _ \ / __| |/ /
# | |_) | | | | | |____| | (_) | (__|   < 
# |____/|_|_| |_|\_____|_|\___/ \___|_|\_\
# 
# Copyright (C) 2022, Stéphane MEYER.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>
#
# BinClock
# C : 2022/03/29
# M : 2022/03/31
# D : A binary clock.

_help() {
cat <<- "EOH"
BinClock ver 0.1

  Display current time in binary form.

  Usage: binclock [-h]|[-m]

  Options:
    -h - show this help and exit.
    -m - display time in 24h format.

  Key Bindings:
    c: change color.
    d: display date.
    q: quit.
    r: redraw the clock.
EOH
}

[[ $1 == "-h" ]] && {
  _help
  exit
}

[[ $1 == "-m" ]] && { f=1; shift; }

(( $# > 0 )) && {
  >&2 echo "Error: invalid option: $*"
  exit 1
}

BIN=("0000" "0001" "0010" "0011" "0100" "0101" "0110" "0111" "1000" "1001")

bold="\e[1m"
dim="\e[2m"
# color="\e[38;5;0m"
rst="\e[m" # reset

hidecursor()    { echo -ne "\e[?25l"; }
showcursor()    { echo -ne "\e[?25h"; }
locate()        { local y x; y=$1; x=$2; printf '\e[%d;%dH' $((y)) $((x)); }
get_scr_size()  { shopt -s checkwinsize; (:;:); }
random_color()  { local C; ((C=(RANDOM%253)+2)); color="\e[38;5;${C}m"; }

exec {pause_fd}<> <(:)
pause() ( read -rt "$1" -u $pause_fd )

_sync() {
  local n=1
  local N
  while (( n !=0 )); do
    N="${EPOCHREALTIME#*,}"
    n=${N:0:1}
    pause 0.0625
  done
}

hidecursor; stty -echo -icanon time 0 min 0

trap 'echo -en "\e[m"; showcursor; stty sane; exit' INT QUIT
trap 'init_screen; reset_var' WINCH

init_screen() {
  clear;
  get_scr_size
  ((OY=(LINES/2)-1))
  ((OX=(COLUMNS/2)-3))
}

reset_var() { unset hy mm sd ind; }

display_bin_digit() {
  local y x D g i

  y=$1; x=$2; D=$3
  g=8

  for ((i=0;i<${#D};i++)); do

    locate $((y)) $((x))

    (( ${D:i:1} == 1 )) && {
      echo -en "${color}${bold}1${rst}"
      locate $((y-1)) $((x))
      echo -en "${color}${bold}${g}${rst}"
    }

    (( ${D:i:1} == 0 )) && {
      echo -en "${color}${dim}0${rst}"
      locate $((y-1)) $((x))
      echo -en "${color}${dim}.${rst}"
    }

    ((x++))
    ((g=g == 1 ? 8 : g/2))

  done
}

display() {
  local DT A B C y x

  [[ $SHOWDATE ]] || {
    [[ $f ]] && DT="$(date '+%H %M %S')"
    [[ $f ]] || DT="$(LC_TIME=C date '+%I%p %M %S ')"
  }

  [[ $SHOWDATE ]] && {
    DT="$(date '+%y %m %d')"
  }
  
  # shellcheck disable=SC2162
  IFS=' ' read A B C <<< "$DT"

  AHY="${BIN[${A:0:1}]}${BIN[${A:1:1}]}"
  AMM="${BIN[${B:0:1}]}${BIN[${B:1:1}]}"
  ASD="${BIN[${C:0:1}]}${BIN[${C:1:1}]}"

  [[ $SHOWDATE ]] || { [[ $f ]] || { [[ ${A:2:1} == "P" ]] && AIND=1 || AIND=0; } ;}

  ((y=OY))

  [[ $AHY != "$hy" ]] && { # ensures we only print when it's needed.
    hy=$AHY
    display_bin_digit $((y)) $((OX)) "$hy"
  }

  ((y+=2))

  [[ $AMM != "$mm" ]] && {
    mm=$AMM
    display_bin_digit $((y)) $((OX)) "$mm"
  }

  ((y+=2))

  [[ $ASD != "$sd" ]] && {
    sd=$ASD
    display_bin_digit $((y)) $((OX)) "$sd"
  }

  [[ $SHOWDATE ]] || { [[ $f ]] || { [[ $ind != "$AIND" ]] && {
    ind=$AIND
    locate $((y)) $((OX+8))
    ((ind == 1)) && echo -en "${color}${dim}1${rst}"
    ((ind == 0)) && echo -en "${color}${dim}0${rst}"
    locate $((y-1)) $((OX+8))
    ((ind == 1)) && echo -en "${color}${dim}P${rst}"
    ((ind == 0)) && echo -en "${color}${dim}A${rst}"
  } } }

  [[ $SHOWDATE ]] && { [[ $ind != "$AIND" ]] && {
    ind=$AIND
    locate $((y)) $((OX+8))
    echo -en "${color}${dim}.${rst}"
    locate $((y-1)) $((OX+8))
    echo -en "${color}${dim}D${rst}"
  } }
}

# AHY  → actual hours/year
# AMM  → actual minutes/month
# ASD  → actual seconds/day
# AIND → actual indicator (A P or D)
# hy   → displayed hours/year
# mm   → displayed minutes/month
# sd   → displayed seconds/day
# ind  → displayed indicator (A P or D)
#
# OY, OX → clock top left position
declare AHY AMM ASD AIND hy mm sd ind OY OX

init_screen

while :; do
  # shellcheck disable=SC2162
  IFS= read key
  case $key in
    q | Q) clear; break ;;
    r | R) init_screen; reset_var ;;
    c | C) random_color; reset_var ;;
    d | D) [[ $SHOWDATE ]] || { SHOWDATE=1; ((TIMER=EPOCHSECONDS)); reset_var; } ;;
  esac

  _sync

  display

  pause 0.5

  # date shows for 5 seconds
  [[ $SHOWDATE ]] && ((EPOCHSECONDS - TIMER == 5 )) && { unset SHOWDATE TIMER; reset_var; };

done

echo -en "${rst}"
stty sane; showcursor
