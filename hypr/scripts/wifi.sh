#!/bin/bash

# Configuration
device="wlan0"
scan_timeout=5  # seconds to wait for scan to complete
connect_timeout=30  # seconds to wait for connection

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check iwctl installed
if ! command -v iwctl &> /dev/null; then
  echo -e "${RED}Error: iwctl is not installed. Please install iwd package.${NC}"
  exit 1
fi

# Check if device exists
if ! iwctl device list | grep -q "$device"; then
  echo -e "${RED}Error: Network device '$device' not found.${NC}"
  echo -e "Available devices:"
  iwctl device list
  exit 1
fi

function scan_networks() {
  echo -e "${BLUE}Scanning for Wi-Fi networks (this may take a few seconds)...${NC}"
  
  # Start scan
  iwctl station "$device" scan >/dev/null 2>&1
  
  # Wait for scan to complete
  local end_time=$((SECONDS + scan_timeout))
  while [ $SECONDS -lt $end_time ]; do
    if iwctl station "$device" get-networks | grep -q "network"; then
      break
    fi
    sleep 1
  done
  
  # Get available networks
  mapfile -t networks < <(iwctl station "$device" get-networks | \
    awk 'NR>2 && !/^-+$/ && !/^$/ && !/^\s*>/ {
      # Extract SSID (handles SSIDs with spaces)
      ssid=$1; 
      for(i=2;i<=NF && $i !~ /^(no|yes|PSK|SAE|8021X)$/;i++) {ssid=ssid " " $i}
      # Extract security type
      security=$(NF)
      printf "%s|%s\n", ssid, security
    }')
  
  if [[ ${#networks[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No networks found.${NC}"
    return 1
  fi
  return 0
}

function connect_to_network() {
  local ssid="$1"
  local password="$2"
  local security="$3"
  
  echo -e "${BLUE}Attempting to connect to '${ssid}'...${NC}"
  
  # For open networks
  if [[ "$security" == "no" ]]; then
    if iwctl --passphrase "$password" station "$device" connect "$ssid"; then
      echo -e "${GREEN}Connected to '${ssid}' successfully.${NC}"
      return 0
    else
      echo -e "${RED}Failed to connect to '${ssid}'.${NC}"
      return 1
    fi
  fi
  
  # For secured networks
  if [[ -z "$password" ]]; then
    echo -e "${YELLOW}This network requires a password. Please try again.${NC}"
    return 1
  fi
  
  # Try connecting with password
  if iwctl --passphrase "$password" station "$device" connect "$ssid"; then
    echo -e "${GREEN}Connected to '${ssid}' successfully.${NC}"
    return 0
  else
    echo -e "${RED}Failed to connect to '${ssid}'. Wrong password?${NC}"
    return 1
  fi
}

function show_network_status() {
  echo -e "\n${BLUE}===== Connection Status =====${NC}"
  iwctl station "$device" show
  echo -e "${BLUE}===========================${NC}"
}

# Main menu
function main_menu() {
  while true; do
    echo -e "\n${BLUE}===== Wi-Fi Menu =====${NC}"
    echo "1) Scan for networks"
    echo "2) Show current connection"
    echo "q) Quit"
    read -rp "Choose an option: " choice

    case "$choice" in
      1)
        if scan_networks; then
          echo -e "\n${GREEN}===== Available Networks =====${NC}"
          for i in "${!networks[@]}"; do
            IFS='|' read -r ssid security <<< "${networks[$i]}"
            printf "${YELLOW}%2d)${NC} %-30s ${BLUE}[%s]${NC}\n" "$((i+1))" "$ssid" "$security"
          done
          
          read -rp "Select a network (1-${#networks[@]}) or 'q' to cancel: " selection
          
          if [[ "$selection" == "q" ]]; then
            continue
          fi
          
          if [[ "$selection" =~ ^[0-9]+$ ]] && ((selection >= 1 && selection <= ${#networks[@]})); then
            IFS='|' read -r ssid security <<< "${networks[$((selection-1))]}"
            
            if [[ "$security" != "no" ]]; then
              read -rsp "Enter password for '$ssid': " password
              echo
            else
              password=""
            fi
            
            if connect_to_network "$ssid" "$password" "$security"; then
              show_network_status
            fi
          else
            echo -e "${RED}Invalid selection.${NC}"
          fi
        fi
        ;;
      2)
        show_network_status
        ;;
      q|Q)
        echo -e "${GREEN}Exiting...${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid option.${NC}"
        ;;
    esac
  done
}

# Start the menu
main_menu