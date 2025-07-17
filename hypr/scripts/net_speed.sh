#!/bin/bash

INTERFACE="wlan0"

RX_PREV=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_PREV=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

sleep 1

RX_NEXT=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_NEXT=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

RX_RATE=$((RX_NEXT - RX_PREV))
TX_RATE=$((TX_NEXT - TX_PREV))

# Convert to KB
RX_KB=$((RX_RATE / 1024))
TX_KB=$((TX_RATE / 1024))

# Display in MB if >= 1024 KB
if [ "$RX_KB" -ge 1024 ]; then
    RX_DISPLAY=$(echo "scale=1; $RX_KB / 1024" | bc)  # e.g. 1.2
    RX_UNIT="MB/s"
else
    RX_DISPLAY="$RX_KB"
    RX_UNIT="KB/s"
fi

if [ "$TX_KB" -ge 1024 ]; then
    TX_DISPLAY=$(echo "scale=1; $TX_KB / 1024" | bc)
    TX_UNIT="MB/s"
else
    TX_DISPLAY="$TX_KB"
    TX_UNIT="KB/s"
fi

echo " ${RX_DISPLAY}${RX_UNIT}  ${TX_DISPLAY}${TX_UNIT}"
