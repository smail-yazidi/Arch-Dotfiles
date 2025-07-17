#!/bin/bash

CURRENT=$(hyprctl getoption input:kb_layout | grep -oP '(?<=str: ).*' | cut -d',' -f1)
if [[ "$1" == "toggle" ]]; then
  if [[ "$CURRENT" == "us" ]]; then
    hyprctl keyword input:kb_layout ara
  else
    hyprctl keyword input:kb_layout us
  fi
else
  case "$CURRENT" in
  us)
    echo "us"
    ;;
  ara)
    echo "ar"
    ;;
  *)
    echo "$CURRENT"
    ;;
  esac
fi
