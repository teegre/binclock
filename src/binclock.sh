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
# M : 2022/03/30
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
    q: quit.
    r: redraw the clock.
EOH
}

[[ $1 == "-h" ]] && {
  _help
  exit
}

[[ $1 == "-m" ]] && { f=1; shift; }

[[ $1 ]] && {
  >&2 echo "Error: invalid option: $*"
  exit 1
}

B=("0000" "0001" "0010" "0011" "0100" "0101" "0110" "0111" "1000" "1001")

b="\e[1m"      # bold
d="\e[2m"      # dim
c="\e[38;5;4m" # color
r="\e[m"       # reset

hidecursor()    { echo -ne "\e[?25l"; }
showcursor()    { echo -ne "\e[?25h"; }
locate()        { local y x; y=$1; x=$2; printf '\e[%d;%dH' $((y)) $((x)); }
get_scr_size()  { shopt -s checkwinsize; (:;:); }
random_color()  { local C; ((C=(RANDOM%254)+1)); c="\e[38;5;${C}m"; }

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

hidecursor; stty -echo -icanon time 0 min 0; clear

trap 'echo -en "\e[m"; showcursor; stty sane; exit' INT QUIT
trap 'init_screen; h=""; m=""; s=""; p=""; clear' WINCH

init_screen() {
  get_scr_size
  ((oy=(LINES/2)-1))
  ((ox=(COLUMNS/2)-3))
}

init_screen
random_color

declare h m s p

while :; do
  # shellcheck disable=SC2162
  IFS= read key
  case $key in
    q | Q) clear; break ;;
    r | R) clear; init_screen; h=""; m=""; s=""; p="" ;;
    c | C) random_color; h=""; m=""; s=""; p="" ;;
  esac

  _sync

  [[ $f ]] && TIME="$(date '+%H %M %S')"
  [[ $f ]] || TIME="$(LC_TIME=C date '+%I%p %M %S ')"
  
  # shellcheck disable=SC2162
  IFS=' ' read H M S <<< "$TIME"

  oh="${B[${H:0:1}]}${B[${H:1:1}]}"
  om="${B[${M:0:1}]}${B[${M:1:1}]}"
  os="${B[${S:0:1}]}${B[${S:1:1}]}"
  [[ $f ]] || { [[ ${H:2:1} == "P" ]] && op=1 || op=0; }

  ((y=oy))
  ((x=ox))
  ((g=8))

  [[ $oh != "$h" ]] && {
    h=$oh
    for ((i=0;i<${#h};i++)); do
      locate $((y)) $((x))
      (( ${h:i:1} == 1 )) && {
        echo -en "${c}${b}1${r}"
        locate $((y-1)) $((x))
        echo -en "${c}${b}${g}${r}"
      }
      (( ${h:i:1} == 0 )) && {
        echo -en "${c}${d}0${r}"
        locate $((y-1)) $((x))
        echo -en "${c}${d}.${r}"
      }
      ((x++))
      ((g=g==1 ? 8 : g/2))
    done
  }

  ((y+=2))
  ((x=ox))

  [[ $om != "$m" ]] && {
    m=$om
    for ((i=0;i<${#m};i++)); do
      locate $((y)) $((x))
      (( ${m:i:1} == 1 )) && {
        echo -en "${c}${b}1${r}"
        locate $((y-1)) $((x))
        echo -en "${c}${b}${g}${r}"
      }
      (( ${m:i:1} == 0 )) && {
        echo -en "${c}${d}0${r}"
        locate $((y-1)) $((x))
        echo -en "${c}${d}.${r}"
      }
      ((x++))
      ((g=g==1 ? 8 : g/2))
    done
  }

  ((y+=2))
  ((x=ox))

  [[ $os != "$s" ]] && {
    s=$os
    for ((i=0;i<${#s};i++)); do
      locate $((y)) $((x))
      (( ${s:i:1} == 1 )) && {
        echo -en "${c}${b}1${r}"
        locate $((y-1)) $((x))
        echo -en "${c}${b}${g}${r}"
      }
      (( ${s:i:1} == 0 )) && {
        echo -en "${c}${d}0${r}"
        locate $((y-1)) $((x))
        echo -en "${c}${d}.${r}"
      }
      ((x++))
      ((g=g==1 ? 8 : g/2))
    done
  }

  [[ $f ]] || { [[ $p != "$op" ]] && {
    p=$op
    locate $((y)) $((x))
    ((p == 1)) && echo -en "${c}${d}1${r}"
    ((p == 0)) && echo -en "${c}${d}0${r}"
    locate $((y-1)) $((x))
    ((p == 1)) && echo -en "${c}${d}P${r}"
    ((p == 0)) && echo -en "${c}${d}A${r}"
  } }

  pause 0.5

done

echo -en "${r}"
stty sane; showcursor
