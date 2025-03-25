#!/usr/bin/env bash

if [ $# -lt 2 ]; then
  echo "Usage: share-internet ETHERNET_DEVICE INTERNET_DEVICE"
  echo "Example: share-internet eth0 wlan0"
  exit 1
fi

ETHERNET_DEVICE="$1"
INTERNET_DEVICE="$2"
IP_RANGE="10.0.0"
NETMASK="24"
LEASE_TIME="24h"

cleanup() {
  echo "Cleaning up..."

  # Kill dnsmasq
  if [ -n "$DNSMASQ_PID" ]; then
    kill $DNSMASQ_PID 2>/dev/null
  fi

  # Remove IP address
  ip addr del ${IP_RANGE}.1/${NETMASK} dev $ETHERNET_DEVICE 2>/dev/null

  # Set interface down
  ip link set down $ETHERNET_DEVICE 2>/dev/null

  # Remove NAT rule
  HANDLE=$(nft -a list table nat 2>/dev/null | grep "oifname \"$INTERNET_DEVICE\" masquerade" | awk '{print $NF}')
  if [ -n "$HANDLE" ]; then
    nft delete rule nat POSTROUTING handle $HANDLE 2>/dev/null
  fi

  # Disable packet forwarding
  sysctl net.ipv4.ip_forward=0 >/dev/null 2>&1

  echo "Cleanup complete"
  exit 0
}

# Set up trap to call cleanup function on script termination
trap cleanup INT TERM EXIT

echo "Setting up internet sharing from $INTERNET_DEVICE to $ETHERNET_DEVICE..."

# Setup ethernet device
ip link set up $ETHERNET_DEVICE
ip addr add ${IP_RANGE}.1/${NETMASK} dev $ETHERNET_DEVICE

# Enable packet forwarding
sysctl net.ipv4.ip_forward=1

# Enable NAT for leaving packets
nft add rule nat POSTROUTING oifname $INTERNET_DEVICE masquerade

# Start dnsmasq for DHCP
dnsmasq -i $ETHERNET_DEVICE --dhcp-range=${IP_RANGE}.2,${IP_RANGE}.255,255.255.255.0,$LEASE_TIME &
DNSMASQ_PID=$!

echo "Internet sharing active. Press Ctrl+C to stop and clean up."
echo "Clients can connect to the ethernet port and will receive IP addresses in the ${IP_RANGE}.0/${NETMASK} range."

# Keep script running until interrupted
while true; do
  sleep 1
done
