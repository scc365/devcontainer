#!/usr/bin/env bash
set -e

function start_openvswitch_service {
    service openvswitch-switch start > /dev/null 2>&1
    ovs-vswitchd --pidfile --detach > /dev/null 2>&1
    ovs-vsctl set-manager ptcp:6640 > /dev/null 2>&1
}

start_openvswitch_service
