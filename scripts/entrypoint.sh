#!/usr/bin/env bash
set -e

function start_openvswitch_service {
    service openvswitch-switch start > /dev/null 2>&1
    ovs-vswitchd --pidfile --detach > /dev/null 2>&1 || true
    ovs-vsctl set-manager ptcp:6640 > /dev/null 2>&1
}

start_openvswitch_service
mininet_version=$(mn --version 2>&1 >/dev/null)
osken_version=$(osken-manager --version)

figlet "SCC365 DevContainer"

echo "Installed tools:"
echo -e "\tMininet: ${mininet_version}"
echo -e "\tOS-Ken: ${osken_version#"osken-manager "}"
