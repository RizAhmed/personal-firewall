#!/bin/bash
#user defined section
#shell vars
IPT="iptables"
ETH="eth0"
LOOPBACK_INTERFACE="lo"
LOOPBACK_IP="127.0.0.1"

#shortcut to resetting the default policy
if [ "$1" = "reset" ]
then
  $IPT --policy INPUT ACCEPT
  $IPT --policy OUTPUT ACCEPT
  $IPT --policy FORWARD ACCEPT
  $IPT -t nat --policy PREROUTING ACCEPT
  $IPT -t nat --policy OUTPUT ACCEPT
  $IPT -t nat --policy POSTROUTING ACCEPT
  $IPT -t mangle --policy PREROUTING ACCEPT
  $IPT -t mangle --policy OUTPUT ACCEPT

  $IPT --flush
  $IPT -t nat --flush
  $IPT -t mangle --flush

  $IPT -X
  $IPT -t nat -X
  $IPT -t mangle -X

  echo "Firewall rules reset!"
  exit 0
fi

#accounting rules
#track www
#track ssh
#versus rest of traffic on system

#firewall rules do not touch pls
#remove any existing rules from all chains
$IPT --flush
$IPT -t nat --flush
$IPT -t mangle --flush
#remove any user defined chains
$IPT -X
$IPT -t nat -X
$IPT -t mangle -X
#reset the default policy
$IPT --policy INPUT ACCEPT
$IPT --policy OUTPUT ACCEPT
$IPT --policy FORWARD ACCEPT
$IPT -t nat --policy PREROUTING ACCEPT
$IPT -t nat --policy OUTPUT ACCEPT
$IPT -t nat --policy POSTROUTING ACCEPT
$IPT -t mangle --policy PREROUTING ACCEPT
$IPT -t mangle --policy OUTPUT ACCEPT
#set the default policy to drop
$IPT --policy INPUT DROP
$IPT --policy OUTPUT DROP
$IPT --policy FORWARD DROP
#permit inbound/outbound ssh packets
$IPT -A INPUT -i $ETH -p tcp --dport 22 -m state  --state NEW,ESTABLISHED -j ACCEPT
$IPT -A OUTPUT -o $ETH -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
#permit inbound/outbound www packets
$IPT -A INPUT -p tcp -m multiport --sport 80,443 -j ACCEPT
$IPT -A OUTPUT -p tcp -m multiport --dport 80,443 -j ACCEPT
#permit inbound/outbound for apache server
$IPT -A INPUT -p tcp -m multiport --dport 80,443 -j ACCEPT
$IPT -A OUTPUT -p tcp -m multiport --sport 80,443 -j ACCEPT
