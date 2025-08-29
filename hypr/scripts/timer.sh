#!/bin/bash
# stopwatch.sh

# Hide cursor
tput civis

# Reset cursor and color on exit
trap "tput cnorm; tput sgr0; exit" SIGINT SIGTERM

SECONDS=0

while true; do
  hrs=$((SECONDS / 3600))
  mins=$(((SECONDS % 3600) / 60))
  secs=$((SECONDS % 60))
  clear
  echo -e "\n\n"
  # Green color: \e[32m, reset: \e[0m
  echo -e "      \e[32m$(printf "%02d:%02d:%02d" $hrs $mins $secs)\e[0m"
  sleep 1
  SECONDS=$((SECONDS + 1))
done
