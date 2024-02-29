#!/bin/bash

systemctl enable --now firewalld
firewall-cmd --permanent --new-service multivpn
firewall-cmd --permanent --service multivpn --add-port 51820-51836/udp
firewall-cmd --permanent --add-service=ssh --add-service=http --add-service=https --add-service=multivpn
firewall-cmd --reload

IFS=$'\n'
for i in $(firewall-cmd --list-rich-rules); do firewall-cmd --permanent --remove-rich-rule="$i"; done

ipv4=10.10.10.10 #ip of target server
ipv6=fd00:beef:cafe::10 #ipv6 of target server

for i in ipv4 ipv6; do
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=3478 protocol=tcp to-port=3478 to-addr=${!i}"
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=3478 protocol=udp to-port=3478 to-addr=${!i}"
done

firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=0.0.0.0/0 masquerade"
firewall-cmd --permanent --add-rich-rule="rule family=ipv6 source address=::/0 masquerade"

firewall-cmd --reload
