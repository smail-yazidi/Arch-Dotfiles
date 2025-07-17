#!/bin/bash

# ===== Colors =====
BLUE="\e[34m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

# ===== Initialize DEFAULT_SINK from current default sink =====
DEFAULT_SINK=$(pactl info | grep "Default Sink" | awk -F': ' '{print $2}')

# ===== Function to select audio output =====
select_output() {
  echo -e "${BLUE}===== Available Audio Outputs =====${RESET}"
  mapfile -t sinks < <(pactl list short sinks)

  if [ ${#sinks[@]} -eq 0 ]; then
    echo -e "${RED}No audio outputs found.${RESET}"
    sleep 2
    return 1
  fi

  for i in "${!sinks[@]}"; do
    sink_name=$(echo "${sinks[$i]}" | awk '{print $2}')
    echo -e "${YELLOW}$((i + 1)))${RESET} $sink_name"
  done

  back_option=$((${#sinks[@]} + 1))
  echo -e "${YELLOW}${back_option})${RESET} Back"

  echo -ne "${YELLOW}Choose output: ${RESET}"
  read -r out_choice
  index=$((out_choice - 1))

  if [ "$out_choice" -eq "$back_option" ]; then
    return 1 # Go back to main menu
  elif [ -z "${sinks[$index]}" ]; then
    echo -e "${RED}Invalid choice.${RESET}"
    sleep 1
    return 1
  fi

  DEFAULT_SINK=$(echo "${sinks[$index]}" | awk '{print $2}')
  pactl set-default-sink "$DEFAULT_SINK"
  echo -e "${BLUE}Selected output:${RESET} $DEFAULT_SINK"
  sleep 1
}

# ===== Audio Control Menu =====
sound_menu() {

  while true; do
    clear
    echo -e "${BLUE}===== Audio Control - Sink: $DEFAULT_SINK =====${RESET}"
    echo -e "1) Select Output"
    echo -e "2) Volume Up"
    echo -e "3) Volume Down"
    echo -e "4) Toggle Mute"
    echo -e "q) Quit"
    echo -n "Choose: "
    read -r s_choice

    case $s_choice in
    1) select_output ;;
    2) pactl set-sink-volume "$DEFAULT_SINK" +5% ;;
    3) pactl set-sink-volume "$DEFAULT_SINK" -5% ;;
    4) pactl set-sink-mute "$DEFAULT_SINK" toggle ;;
    q) break ;;
    *)
      echo -e "${RED}Invalid option${RESET}"
      sleep 1
      ;;
    esac
  done
}

# Run the menu
sound_menu
