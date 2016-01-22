#!/bin/bash
#user defined section
#shell var
IPT="iptables"

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
