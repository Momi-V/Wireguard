#!/bin/bash

mkdir /var/rprox
cd /var/rprox

cat <<'EOL' > /etc/modules-load.d/wireguard.conf
# Load wireguard module at boot
wireguard
EOL

wget "https://raw.githubusercontent.com/HPPinata/Wireguard/main/server/forward.bash"
nano forward.bash
chmod +x forward.bash
bash forward.bash

cat <<'EOL' | crontab -
*/5 * * * * bash /var/rprox/forward.bash
EOL

mkdir -p build/dynv6
mkdir -p build/wireguard

cat <<'EOL' > build/dynv6/dyndns.bash
#!/bin/bash

OLD4=$(cat tempaddr4)
NEW4=$(curl api.ipify.org)
if [ "$OLD4" != "$NEW4" ]; then
  for Z in ${ZONE[@]}; do
    curl -4 -L "https://ipv4.dynv6.com/api/update?zone=$Z&ipv4=auto&token=$TK"
  done
fi

OLD6=$(cat tempaddr6)
NEW6=$(curl api64.ipify.org)
if [ "$OLD6" != "$NEW6" ]; then
  for Z in ${ZONE[@]}; do
    curl -6 -L "https://ipv6.dynv6.com/api/update?zone=$Z&ipv6=auto&ipv6prefix=auto&token=$TK"
  done
fi

echo $NEW4 > tempaddr4
echo $NEW6 > tempaddr6
sleep 300
EOL
cat build/dynv6/dyndns.bash

cat <<'EOL' > build/dynv6/Dockerfile
FROM alpine:latest

RUN apk add --no-cache curl bash

ADD ./dyndns.bash /
RUN chmod +x ./dyndns.bash

CMD ["./dyndns.bash"]
EOL
cat build/dynv6/Dockerfile

nano wg0.conf
mv wg0.conf build/wireguard

cat <<'EOL' > build/wireguard/Dockerfile
FROM alpine:latest

RUN apk add --no-cache wireguard-tools

ADD ./wg0.conf /etc/wireguard/

CMD ["sh", "-c", "wg-quick up wg0; sleep infinity"]
EOL
cat build/wireguard/Dockerfile

cat <<'EOL' > compose.yml
services:
  dynv6:
    build: ./build/dynv6
    container_name: dynv6
    privileged: true
    network_mode: host
    environment:
      - ZONE=( your.zone ) #set dynv6 Zone
      - TK=YOURTOKEN #set dynv6 Token
    restart: unless-stopped

  wireguard:
    build: ./build/wireguard
    container_name: wireguard
    privileged: true
    network_mode: host
    restart: unless-stopped
EOL
nano compose.yml
cat compose.yml

cat <<'EOL' > /var/rprox/update.bash
#!/bin/bash
cd /var/rprox
docker compose pull
docker compose build --pull
docker compose up -dV
docker system prune -a -f --volumes
EOL
chmod +x /var/rprox/update.bash

cat <<'EOL' > /etc/systemd/system/proxy-compose.service
[Unit]
Description=Start Reverse-Proxy Container
After=network-online.target docker.service

[Service]
Type=oneshot
ExecStart=bash -c '/var/rprox/update.bash'
ExecStop=bash -c '/bin/docker compose down -f /var/rprox/compose.yml'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL
systemctl enable /etc/systemd/system/proxy-compose.service

reboot
