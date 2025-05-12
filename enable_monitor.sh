#!/bin/bash

: <<'COMMENT'
This Bash script sets the wlan0 interface to monitor mode with a new MAC address.
It first checks whether the wlan0 wireless interface exists.
If the interface is found, the script generates a random MAC address
and applies it to the wlan0 interface.
Finally, it brings the interface up in monitor mode with the new MAC address,
configured to a specified channel and transmit power.

To run the script sudo ./enable_monitor.sh <interface> <channel> <txpower>

Example:
    sudo ./enable_monitor.sh wlan0 6 20

COMMENT

# ========== Color definitions ==========
RED='\033[0;31m'
YELLOW='\033[0;33;1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ========== Root check ==========
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Please run this script as root.${NC}"
   exit 1
fi

# ========== Default values ==========
INTERFACE="${1:-wlan0}"
CHANNEL="${2:-1}"
TXPOWER="${3:-30}"

echo -e "${CYAN}Searching for interface ${YELLOW}$INTERFACE${NC}..."

if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
    echo -e "${RED}ERROR:${YELLOW} Interface $INTERFACE not found!${NC}"
    echo -e "${NC}Usage: $0 [interface:wlan0] [channel:1] [txpower:30]${NC}"
    exit 1
fi

# ========== Stop conflicting services ==========
echo -e "${CYAN}Killing interfering services...${NC}"
airmon-ng check kill > /dev/null 2>&1

# ========== Generate a random MAC address ==========
echo -e "${CYAN}Generating random MAC address...${NC}"
hexchars="0123456789ABCDEF"
mac="02"
for i in {1..5}; do
    octet="${hexchars:$((RANDOM % 16)):1}${hexchars:$((RANDOM % 16)):1}"
    mac+=":$octet"
done

echo -e "${CYAN}Setting new MAC address to ${YELLOW}$mac${NC}"
ip link set dev "$INTERFACE" down
ip link set dev "$INTERFACE" address "$mac"
ip link set dev "$INTERFACE" up

# ========== Confirm MAC ==========
new_mac=$(ip link show "$INTERFACE" | awk '/ether/ {print $2}')
echo -e "${YELLOW}Confirmed MAC: $new_mac${NC}"

# ========== Enable monitor mode ==========
echo -e "${CYAN}Enabling monitor mode on ${YELLOW}$INTERFACE${NC}..."
iwconfig "$INTERFACE" mode monitor
iw dev "$INTERFACE" set channel "$CHANNEL"
iwconfig "$INTERFACE" txpower "$TXPOWER"
ip link set "$INTERFACE" up

# ========== Confirm monitor mode ==========
if iwconfig "$INTERFACE" | grep -q "Mode:Monitor"; then
    echo -e "${GREEN}✔ Monitor mode enabled on $INTERFACE${NC}"
else
    echo -e "${RED}✘ Failed to enable monitor mode on $INTERFACE${NC}"
    exit 1
fi

echo -e "${GREEN}✔ Interface: $INTERFACE | MAC: $new_mac | Channel: $CHANNEL | TX Power: $TXPOWER dBm${NC}"
