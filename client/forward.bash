#!/bin/bash

systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh --add-service=http --add-service=https
firewall-cmd --reload

IFS=$'\n'
for i in $(firewall-cmd --list-rich-rules); do firewall-cmd --permanent --remove-rich-rule="$i"; done

ipv4=1.2.3.4 #ip of target server
ipv6=2001::beef:cafe # ipv6 of target server

# list of ports & protocols to forward
for i in ipv4 ipv6; do
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=3478 protocol=tcp to-port=3478 to-addr=${!i}"
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=3478 protocol=udp to-port=3478 to-addr=${!i}"
done

ipv4=1.2.3.40 #ip of target server2
ipv6=2001::aabb:beef:cafe # ipv6 of target server2

# list of ports & protocols to forward
for i in ipv4 ipv6; do
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=51820-51836 protocol=udp to-port=51820-51836 to-addr=${!i}"
done

firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=0.0.0.0/0 masquerade"
firewall-cmd --permanent --add-rich-rule="rule family=ipv6 source address=::/0 masquerade"

firewall-cmd --reload
