This Bash script sets the wlan0 interface to monitor mode with a new MAC address.
It first checks whether the wlan0 wireless interface exists.
If the interface is found, the script generates a random MAC address
and applies it to the wlan0 interface.
Finally, it brings the interface up in monitor mode with the new MAC address,
configured to a specified channel and transmit power.

To run the script sudo ./enable_monitor.sh <interface> <channel> <txpower>

Example:
    sudo ./enable_monitor.sh wlan0 6 20
