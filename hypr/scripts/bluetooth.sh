#!/bin/bash

# Color definitions
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

current_device=""
current_device_name=""

function bluetooth_power_toggle() {
  status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
  if [ "$status" = "yes" ]; then
    if bluetoothctl power off; then
      echo -e "${GREEN}Bluetooth powered OFF.${RESET}"
      current_device=""
      current_device_name=""
    else
      echo -e "${RED}Failed to power off Bluetooth.${RESET}"
    fi
  else
    if bluetoothctl power on; then
      echo -e "${GREEN}Bluetooth powered ON.${RESET}"
    else
      echo -e "${RED}Failed to power on Bluetooth.${RESET}"
    fi
  fi
  sleep 1
}

function scan_devices() {
  echo -e "${BLUE}Scanning for Bluetooth devices (15 seconds)...${RESET}"
  
  # Start scanning in background
  bluetoothctl scan on >/dev/null 2>&1 &
  scan_pid=$!
  
  # Show scanning animation
  local i=0
  while kill -0 $scan_pid 2>/dev/null && [ $i -lt 15 ]; do
    printf "\rScanning${YELLOW}%0.s.${RESET}" $(seq 1 $((i % 4 + 1)))
    sleep 1
    ((i++))
  done
  
  # Clean up
  kill $scan_pid 2>/dev/null
  bluetoothctl scan off >/dev/null 2>&1
  printf "\r"
}

function is_valid_mac() {
  [[ "$1" =~ ^([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2})$ ]]
}

function list_devices() {
  echo -e "${BLUE}===== Available Bluetooth Devices =====${RESET}"
  
  # Get only valid paired devices
  echo -e "${CYAN}Paired Devices:${RESET}"
  mapfile -t paired_devices < <(bluetoothctl paired-devices | while read -r _ mac name; do
    if is_valid_mac "$mac"; then
      echo "$mac $name"
    fi
  done)
  
  if [ ${#paired_devices[@]} -eq 0 ]; then
    echo -e "${YELLOW}No paired devices found.${RESET}"
  else
    for i in "${!paired_devices[@]}"; do
      mac=$(echo "${paired_devices[$i]}" | awk '{print $1}')
      name=$(echo "${paired_devices[$i]}" | cut -d ' ' -f 2-)
      echo -e "${CYAN}$((i + 1)))${RESET} ${name} ${YELLOW}(${mac})${RESET} [Paired]"
    done
  fi
  
  # Get only valid new devices
  echo -e "\n${CYAN}Discovered Devices:${RESET}"
  mapfile -t new_devices < <(bluetoothctl devices | while read -r _ mac name; do
    if is_valid_mac "$mac" && ! bluetoothctl paired-devices | grep -q "$mac"; then
      echo "$mac $name"
    fi
  done)
  
  if [ ${#new_devices[@]} -eq 0 ]; then
    echo -e "${YELLOW}No new devices found.${RESET}"
  else
    for i in "${!new_devices[@]}"; do
      mac=$(echo "${new_devices[$i]}" | awk '{print $1}')
      name=$(echo "${new_devices[$i]}" | cut -d ' ' -f 2-)
      echo -e "${CYAN}$((i + ${#paired_devices[@]} + 1)))${RESET} ${name} ${YELLOW}(${mac})${RESET}"
    done
  fi
  
  # Combine all valid devices for selection
  all_devices=("${paired_devices[@]}" "${new_devices[@]}")
  
  if [ ${#all_devices[@]} -eq 0 ]; then
    echo -e "\n${YELLOW}No Bluetooth devices found at all.${RESET}"
    echo -e "${CYAN}Make sure your devices are in pairing mode and try again.${RESET}"
    echo -e "${CYAN}Press Enter to return.${RESET}"
    read -r
    return 1
  fi
  
  echo -ne "\n${CYAN}Choose a number to connect (or press Enter to cancel): ${RESET}"
  read -r choice
  
  if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ -z "$choice" ] || (( choice < 1 || choice > ${#all_devices[@]} )); then
    echo -e "${YELLOW}Cancelled or invalid choice.${RESET}"
    return 1
  fi
  
  selected_mac=$(echo "${all_devices[$((choice-1))]}" | awk '{print $1}')
  selected_name=$(echo "${all_devices[$((choice-1))]}" | cut -d ' ' -f 2-)
  
  connect_device "$selected_mac" "$selected_name"
}

function connect_device() {
  local mac=$1
  local name=$2
  
  echo -e "${BLUE}Attempting to connect to ${name} (${mac})...${RESET}"
  
  # Try to pair first if not already paired
  if ! bluetoothctl info "$mac" | grep -q "Paired: yes"; then
    echo -e "${CYAN}Pairing with device...${RESET}"
    if ! bluetoothctl pair "$mac"; then
      echo -e "${RED}Pairing failed.${RESET}"
      return 1
    fi
  fi
  
  # Trust the device
  bluetoothctl trust "$mac"
  
  # Connect to the device
  if bluetoothctl connect "$mac"; then
    echo -e "${GREEN}Successfully connected to ${name} (${mac}).${RESET}"
    current_device="$mac"
    current_device_name="$name"
  else
    echo -e "${RED}Failed to connect to device.${RESET}"
    return 1
  fi
  
  echo -e "${CYAN}Press Enter to continue.${RESET}"
  read -r
}

function disconnect_device() {
  if [ -z "$current_device" ]; then
    echo -e "${YELLOW}No device currently connected.${RESET}"
    echo -e "${CYAN}Press Enter to continue.${RESET}"
    read -r
    return
  fi

  echo -e "${BLUE}Disconnecting ${current_device_name} (${current_device})...${RESET}"
  if bluetoothctl disconnect "$current_device"; then
    echo -e "${GREEN}Successfully disconnected.${RESET}"
    current_device=""
    current_device_name=""
  else
    echo -e "${RED}Failed to disconnect device.${RESET}"
  fi
  
  echo -e "${CYAN}Press Enter to continue.${RESET}"
  read -r
}

function show_status() {
  clear
  echo -e "${BLUE}===== Bluetooth Control =====${RESET}"
  
  # Bluetooth power status
  power_status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
  echo -e "Bluetooth Status: ${power_status^}"
  
  # Current connected device
  if [ -n "$current_device" ]; then
    echo -e "Connected Device: ${GREEN}${current_device_name}${RESET} ${YELLOW}(${current_device})${RESET}"
  else
    echo -e "Connected Device: ${YELLOW}None${RESET}"
  fi
  
  echo
}

function main_menu() {
  while true; do
    show_status
    
    echo "1) Power ON/OFF Bluetooth"
    echo "2) Scan and Connect to Devices"
    echo "3) Disconnect Current Device"
    echo "q) Quit"
    echo -ne "${CYAN}Choose: ${RESET}"
    read -r choice

    case $choice in
      1) bluetooth_power_toggle ;;
      2) scan_devices; list_devices ;;
      3) disconnect_device ;;
      q|Q) echo -e "${GREEN}Exiting...${RESET}"; exit 0 ;;
      *) echo -e "${RED}Invalid choice.${RESET}"; sleep 1 ;;
    esac
  done
}

# Check if bluetoothctl is available
if ! command -v bluetoothctl &>/dev/null; then
  echo -e "${RED}Error: bluetoothctl is not installed or not in PATH.${RESET}"
  exit 1
fi

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
  echo -e "${YELLOW}Warning: Running as root is not recommended.${RESET}"
  sleep 2
fi

main_menu