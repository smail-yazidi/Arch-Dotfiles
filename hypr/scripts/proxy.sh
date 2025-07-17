#!/bin/bash

# Colors
BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

get_current_proxy() {
  grep -E '^(http|https)_proxy=' /etc/environment | head -n 1 | cut -d= -f2 | tr -d '"'
}

while true; do
  clear
  CURRENT_PROXY=$(get_current_proxy)

  echo -e "${BLUE}===== Proxy Configuration Menu =====${RESET}"
  if [[ -n "$CURRENT_PROXY" ]]; then
    echo -e "${GREEN}Current proxy: $CURRENT_PROXY${RESET}"
  else
    echo -e "${RED}No proxy is currently set.${RESET}"
  fi
  echo "1) Add Proxy"
  echo "2) Remove Proxy"
  echo "3) Exit"
  echo -n "Choose an option: "
  read choice

  case $choice in
  1)
    read -p "Enter proxy host (e.g. 127.0.0.1): " HOST
    read -p "Enter proxy port (e.g. 8080): " PORT
    PROXY="http://$HOST:$PORT"

    # Export to current session
    export http_proxy="$PROXY"
    export https_proxy="$PROXY"
    export HTTP_PROXY="$PROXY"
    export HTTPS_PROXY="$PROXY"

    echo -e "${GREEN}[✔] Proxy set for current session: $PROXY${RESET}"

    read -p "Apply proxy to /etc/environment (requires sudo)? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      sudo sed -i '/http_proxy/d;/https_proxy/d;/HTTP_PROXY/d;/HTTPS_PROXY/d' /etc/environment
      sudo bash -c "echo '
http_proxy=\"$PROXY\"
https_proxy=\"$PROXY\"
HTTP_PROXY=\"$PROXY\"
HTTPS_PROXY=\"$PROXY\"
' >> /etc/environment"
      echo -e "${GREEN}[✔] Proxy written to /etc/environment${RESET}"
    fi
    read -p "Press Enter to return to menu..."
    ;;

  2)
    # Unset current session
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

    # Remove from /etc/environment
    sudo sed -i '/http_proxy/d;/https_proxy/d;/HTTP_PROXY/d;/HTTPS_PROXY/d' /etc/environment

    echo -e "${RED}[✘] Proxy removed from session and /etc/environment${RESET}"
    read -p "Press Enter to return to menu..."
    ;;

  3)
    echo -e "${BLUE}Exiting...${RESET}"
    break
    ;;

  *)
    echo -e "${RED}Invalid choice. Try again.${RESET}"
    sleep 1
    ;;
  esac
done
