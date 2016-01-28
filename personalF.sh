#!/bin/bash
#shell vars
IPT="iptables"
#this must match the name of the network card on the machine
ETH="eno1"
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

#user defined chains to implement accounting rules for www and ssh
$IPT -N track-inbound
$IPT -N track-outbound

#drop all packets coming in and out of reserved port 0
$IPT -A INPUT -j DROP -p tcp --sport 0
$IPT -A INPUT -j DROP -p udp --sport 0
$IPT -A INPUT -j DROP -p tcp --dport 0
$IPT -A INPUT -j DROP -p udp --dport 0

#drop invalid or weird packets
$IPT -A INPUT -p ALL -m state --state INVALID -j DROP
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
$IPT -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
$IPT -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
$IPT -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
$IPT -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
$IPT -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
$IPT -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP

#route stuff not dropped into accounting rules
$IPT -A INPUT -p tcp -i $ETH -j track-inbound

#allow DHCP traffic
$IPT -A INPUT -p UDP -s 0/0 --sport 67 --dport 68 -j ACCEPT
$IPT -A OUTPUT -p UDP --dport 68 -m state --state NEW -j ACCEPT

#allow DNS traffic
$IPT -A OUTPUT -p TCP --dport 53 -m state --state NEW -j ACCEPT
$IPT -A OUTPUT -p UDP --dport 53 -m state --state NEW -j ACCEPT

#allow established and related incoming traffic
$IPT -A INPUT -p ALL -i $ETH -m state --state ESTABLISHED,RELATED -j ACCEPT

#permit inbound/outbound ssh packets
$IPT -A INPUT -i $ETH -p tcp --dport 22 -m state  --state NEW,ESTABLISHED -j ACCEPT
$IPT -A OUTPUT -o $ETH -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
#permit inbound/outbound www packets
$IPT -A INPUT -p tcp -m multiport --sport 80,443 -j ACCEPT
$IPT -A OUTPUT -p tcp -m multiport --dport 80,443 -j ACCEPT
#permit inbound/outbound for apache server
$IPT -A INPUT -p tcp -m multiport --dport 80,443 -j ACCEPT
$IPT -A OUTPUT -p tcp -m multiport --sport 80,443 -j ACCEPT

#accounting for HTTP and SSH
#for the input chain
$IPT -A track-inbound -p tcp -s 0/0 --dport 80 --sport 1024:65535 -j ACCEPT
$IPT -A track-inbound -p tcp -s 0/0 --dport 22 -j ACCEPT
#for the forward chain
$IPT -A FORWARD -i $ETH -m tcp -p TCP --dport 22 -j ACCEPT
$IPT -A FORWARD -i $ETH -m tcp -p TCP --dport 80 -j ACCEPT
$IPT -A FORWARD -i $ETH -m tcp -p TCP --sport 22 -j ACCEPT
$IPT -A FORWARD -i $ETH -m tcp -p TCP --sport 80 -j ACCEPT
$IPT -A FORWARD -s 0/0 -m tcp -p TCP --dport 22 -j ACCEPT
$IPT -A FORWARD -s 0/0 -m tcp -p TCP --dport 80 -j ACCEPT
$IPT -A FORWARD -s 0/0 -m tcp -p TCP --sport 22 -j ACCEPT
$IPT -A FORWARD -s 0/0 -m tcp -p TCP --sport 80 -j ACCEPT

$IPT -A FORWARD -i $ETH -m tcp -p TCP --dport 22 -j track-inbound
$IPT -A FORWARD -i $ETH -m tcp -p TCP --dport 80 -j track-inbound
$IPT -A FORWARD -i $ETH -m tcp -p TCP --sport 22 -j track-inbound
$IPT -A FORWARD -i $ETH -m tcp -p TCP --sport 80 -j track-inbound
$IPT -A FORWARD -s 0/0 -m tcp -p TCP --dport 22 -j track-outbound
$IPT -A FORWARD -s 0/0 -m tcp -p TCP --dport 80 -j track-outbound
$IPT -A FORWARD -s 0/0 -m tcp -p TCP --sport 22 -j track-outbound
$IPT -A FORWARD -s 0/0 -m tcp -p TCP --sport 80 -j track-outbound
#for the output chain
$IPT -A track-outbound -p TCP --sport 80 -j ACCEPT
$IPT -A track-outbound -p TCP --dport 80 -j ACCEPT
$IPT -A track-outbound -p TCP --sport 22 -j ACCEPT
$IPT -A track-outbound -p TCP --dport 22 -j ACCEPT
#the rest of outbound traffic goes to accounting rules
$IPT -A OUTPUT -p tcp -s 0/0 -j track-outbound
