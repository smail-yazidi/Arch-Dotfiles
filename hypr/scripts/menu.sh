#!/bin/bash

# ===== Helper Functions =====

# Check if Bluetooth power is on
power_on() {
  bluetoothctl show | grep -q "Powered: yes"
}
# Color definitions
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

# ===== Main Menu =====

main_menu() {
  clear
  echo -e "${BLUE}===== System Control =====${RESET}"
  echo -e "1) Manage Wi-Fi"
  echo -e "2) Manage Bluetooth"
  echo -e "3) Audio Control"
  echo -e "4) Power Options"
  echo -e "5) Exit"
  echo -n "Choose a number: "
  read choice

  case $choice in
  1) wifi_menu ;;
  2) bluetooth_menu ;;
  3) sound_menu ;;
  4) power_menu ;;
  5) exit ;;
  *)
    echo -e "${RED}Invalid option${RESET}"
    sleep 1
    main_menu
    ;;
  esac
}

# ===== Wi-Fi Menu =====

wifi_menu() {
  while true; do
    clear
    echo -e "${BLUE}===== Wi-Fi Menu =====${RESET}"

    wifi_status=$(nmcli radio wifi)
    echo -e "Wi-Fi is: ${WHITE}$wifi_status${RESET}"

    current_ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d ':' -f2)

    if [[ "$wifi_status" == "disabled" ]]; then
      echo -e "${RED}Wi-Fi is turned off.${RESET}"
      echo -e "1) Turn Wi-Fi ON"
      echo -e "q) Quit"
      echo -n "${MAGENTA}Choose an option:${RESET} "
      read choice

      case "$choice" in
      1)
        nmcli radio wifi on && echo -e "${GREEN}✅ Wi-Fi enabled.${RESET}" || echo -e "${RED}❌ Failed to enable Wi-Fi.${RESET}"
        sleep 2
        ;;
      q)
        break
        ;;
      *)
        echo -e "${RED}❌ Invalid option.${RESET}"
        sleep 2
        ;;
      esac

    elif [[ -n "$current_ssid" ]]; then
      echo -e "Connected to: ${GREEN}$current_ssid${RESET}"
      echo -e "1) Turn Wi-Fi OFF"
      echo -e "2) Disconnect from $current_ssid"
      echo -e "3) Back to Main Menu"
      echo -e "q) Quit"
      echo -n "Choose an option: "
      read choice

      case "$choice" in
      1)
        nmcli radio wifi off && echo -e "${GREEN}✅ Wi-Fi disabled.${RESET}" || echo -e "${RED}❌ Failed to disable Wi-Fi.${RESET}"
        sleep 2
        ;;
      2)
        echo -e "Disconnecting from $current_ssid..."
        nmcli con down id "$current_ssid" && echo -e "${GREEN}✅ Disconnected.${NC}" || echo -e "${RED}❌ Failed to disconnect.${RESET}"
        sleep 2
        ;;
      3)
        main_menu
        return
        ;;
      q)
        break
        ;;
      *)
        echo -e "${RED}❌ Invalid selection.${RESET}"
        sleep 2
        ;;
      esac

    else
      echo -e "Not connected to Wi-Fi."
      echo ""
      echo -e "Scanning for available networks..."
      mapfile -t network_list < <(nmcli -t -f SSID,SECURITY dev wifi | grep -v "^:" | sort -u)

      if [ ${#network_list[@]} -eq 0 ]; then
        echo -e "${YELLOW}No networks found.${RESET}"
        sleep 2
        continue
      fi

      echo -e "${BLUE}===== Available Networks =====${RESET}"
      for i in "${!network_list[@]}"; do
        ssid=$(echo "${network_list[$i]}" | cut -d ':' -f1)
        sec=$(echo "${network_list[$i]}" | cut -d ':' -f2)
        if [[ "$sec" == "--" || -z "$sec" ]]; then
          echo -e "$((i + 1))) $ssid (${GREEN}Open Network${RESET})"
        else
          echo -e "$((i + 1))) $ssid (${RED}Locked Network${RESET})"
        fi
      done
      echo -e "a) Turn Wi-Fi OFF"
      echo -e "r) Refresh"
      echo -e "q) Quit"
      echo -n "Choose a network or option: "
      read choice

      if [[ "$choice" == "q" ]]; then
        break
      elif [[ "$choice" == "r" ]]; then
        continue
      elif [[ "$choice" == "a" ]]; then
        nmcli radio wifi off && echo -e "${GREEN}✅ Wi-Fi disabled.${RESET}" || echo -e "${RED}❌ Failed to disable Wi-Fi.${RESET}"
        sleep 2
        continue
      elif ! [[ "$choice" =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#network_list[@]})); then
        echo -e "${RED}❌ Invalid selection.${RESET}"
        sleep 2
        continue
      fi

      selected="${network_list[$((choice - 1))]}"
      ssid=$(echo "$selected" | cut -d ':' -f1)
      sec=$(echo "$selected" | cut -d ':' -f2)

      if [[ "$sec" == "--" || -z "$sec" ]]; then
        echo -e "Connecting to open network: $ssid..."
        if nmcli device wifi connect "$ssid"; then
          echo -e "${GREEN}✅ Connected to $ssid${RESET}"
        else
          echo -e "${RED}❌ Failed to connect to $ssid${RESET}"
        fi
      else
        read -s -p "Enter password for $ssid: " password
        echo
        if nmcli device wifi connect "$ssid" password "$password"; then
          echo -e "${GREEN}✅ Connected to $ssid${RESET}"
        else
          echo -e "${RED}❌ Connection failed. Wrong password?${RESET}"
        fi
      fi
      sleep 2
    fi
  done
}

# ===== Bluetooth Menu =====

bluetooth_menu() {
  while true; do
    clear
    echo -e "${BLUE}===== Bluetooth Control =====${RESET}"

    if power_on; then
      echo -e "Bluetooth Status: ${GREEN}ON${RESET}"
      bluetooth_on=true
    else
      echo -e "Bluetooth Status: ${RED}OFF${RESET}"
      bluetooth_on=false
    fi

    echo -e "1) Power ON/OFF Bluetooth"
    echo -e "2) Scan and Connect to Devices"
    echo -e "3) Disconnect Current Device"
    echo -e "4) Back to Main Menu"
    echo -n "Choose: "
    read choice

    case $choice in
    1)
      if $bluetooth_on; then
        bluetoothctl power off
        echo -e "${RED}Bluetooth turned OFF.${RESET}"
      else
        bluetoothctl power on
        echo -e "${GREEN}Bluetooth turned ON.${RESET}"
      fi
      sleep 1
      ;;

    2)
      if ! power_on; then
        echo -e "${YELLOW}Bluetooth is OFF. Turning it ON...${RESET}"
        bluetoothctl power on
        sleep 2
      fi

      echo -e "${BLUE}Scanning for devices...${RESET}"
      bluetoothctl scan on &>/dev/null
      sleep 5
      bluetoothctl scan off &>/dev/null
      echo -e "${BLUE}===== Available Bluetooth Devices =====${RESET}"
      mapfile -t device_lines < <(bluetoothctl devices | grep "Device")
      if [ ${#device_lines[@]} -eq 0 ]; then
        echo -e "${YELLOW}No devices found.${RESET}"
        echo -e "Press Enter to return."
        read
        continue
      fi

      declare -a macs
      declare -a names

      for line in "${device_lines[@]}"; do
        mac=$(echo "$line" | awk '{print $2}')
        name=$(echo "$line" | cut -d ' ' -f 3-)
        macs+=("$mac")
        names+=("$name")
      done

      for i in "${!names[@]}"; do
        echo -e "$((i + 1))) ${names[$i]} (${macs[$i]})"
      done

      echo -n "Choose a number to connect: "
      read dev_choice
      index=$((dev_choice - 1))

      if [ -z "${macs[$index]}" ]; then
        echo -e "${RED}Invalid choice.${RESET}"
        sleep 1
        continue
      fi

      device_mac="${macs[$index]}"
      device_name="${names[$index]}"
      echo -e "Pairing with $device_name..."
      bluetoothctl pair "$device_mac"
      sleep 2

      echo -e "Connecting to $device_name..."
      bluetoothctl connect "$device_mac"
      sleep 2

      if bluetoothctl info "$device_mac" | grep -q "Connected: yes"; then
        echo -e "${GREEN}Connected to $device_name.${RESET}"
      else
        echo -e "${RED}Failed to connect.${RESET}"
      fi

      echo -e "Press Enter to continue."
      read
      ;;

    3)
      connected_mac=$(bluetoothctl info | grep "Device" | awk '{print $2}')
      if [ -z "$connected_mac" ]; then
        echo -e "${YELLOW}No connected device.${RESET}"
      else
        bluetoothctl disconnect "$connected_mac"
        echo -e "${GREEN}Disconnected from $connected_mac.${RESET}"
      fi
      sleep 2
      ;;

    4)
      main_menu
      return
      ;;

    *)
      echo -e "${RED}Invalid option.${RESET}"
      sleep 1
      ;;
    esac
  done
}

# ===== Audio Control Menu =====

sound_menu() {
  while true; do
    clear
    echo -e "${BLUE}===== Audio Control =====${RESET}"
    echo -e "1) Volume Up"
    echo -e "2) Volume Down"
    echo -e "3) Toggle Mute"
    echo -e "4) Back to Main Menu"
    echo -n "Choose: "
    read s_choice

    case $s_choice in
    1) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    2) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
    3) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
    4)
      main_menu
      return
      ;;
    *)
      echo -e "${RED}Invalid option${RESET}"
      sleep 1
      ;;
    esac
  done
}

# ===== Power Menu =====

power_menu() {
  clear
  echo -e "${BLUE}===== Power Options =====${RESET}"
  echo -e "1) Logout from Hyprland"
  echo -e "2) Reboot"
  echo -e "3) Shutdown"
  echo -e "4) Lock Screen"
  echo "5) Back"
  echo -n "Choose: "
  read p_choice

  case $p_choice in
  1) hyprctl dispatch exit ;;
  2) reboot ;;
  3) shutdown now ;;
  4) loginctl lock-session ;;
  5)
    main_menu
    return
    ;;
  *)
    echo "Invalid option"
    sleep 1
    power_menu
    ;;
  esac
}
main_menu
# ===== Start Script =====
