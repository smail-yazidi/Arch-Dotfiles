#!/bin/bash

# ===== Colors =====
BLUE="\e[34m"
RED="\e[31m"
RESET="\e[0m"

# ===== Spotify Control Menu =====
spotify_menu() {
  while true; do
    clear

    echo -e "${BLUE}===== Spotify Control =====${RESET}"
    echo -e "$(playerctl -p spotify metadata --format '{{ artist }} - {{ title }}')"
    echo "1) Play/Pause"
    echo "2) Next Track"
    echo "3) Previous Track"
    echo "4) Show Current Song"
    echo "5) Exit"
    echo -n "Choose: "
    read -r choice

    case $choice in
    1) playerctl -p spotify play-pause ;;
    2) playerctl -p spotify next ;;
    3) playerctl -p spotify previous ;;
    4) playerctl -p spotify metadata --format "{{ artist }} - {{ title }}" ;;
    5) break ;;
    *)
      echo -e "${RED}Invalid option${RESET}"
      sleep 1
      ;;
    esac

    sleep 1
  done
}

spotify_menu
