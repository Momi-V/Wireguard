#!/bin/bash

systemctl enable --now firewalld
firewall-cmd --permanent --new-service reversevpn
firewall-cmd --permanent --service reversevpn --add-port 51880/udp
firewall-cmd --permanent --add-service=ssh --add-service=reversevpn
firewall-cmd --reload

IFS=$'\n'
for i in $(firewall-cmd --list-rich-rules); do firewall-cmd --permanent --remove-rich-rule="$i"; done

ipv4="10.13.13.2"
ipv6="fd00:13:13:13::2"

for i in ipv4 ipv6; do
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=80 protocol=tcp to-port=80 to-addr=${!i}"
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=443 protocol=tcp to-port=443 to-addr=${!i}"
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=3478 protocol=tcp to-port=3478 to-addr=${!i}"
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=3478 protocol=udp to-port=3478 to-addr=${!i}"
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=8022 protocol=tcp to-port=22 to-addr=${!i}"
firewall-cmd --permanent --add-rich-rule="rule family=$i forward-port port=51820-51836 protocol=udp to-port=51820-51836 to-addr=${!i}"
done

firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=0.0.0.0/0 masquerade"
firewall-cmd --permanent --add-rich-rule="rule family=ipv6 source address=::/0 masquerade"

firewall-cmd --reload
