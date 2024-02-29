#!/bin/bash

mkdir /var/rprox
cd /var/rprox

cat <<'EOL' > /etc/modules-load.d/wireguard.conf
# Load wireguard module at boot
wireguard
EOL

curl -O "https://raw.githubusercontent.com/HPPinata/Wireguard/main/server/forward.bash"
nano forward.bash
chmod +x forward.bash
bash forward.bash

mkdir -p build/dynv6
mkdir -p build/wireguard

curl -O https://raw.githubusercontent.com/HPPinata/Wireguard_P/wire-ui/server/dynv6/dyndns.bash
mv dyndns.bash build/dynv6
cat build/dynv6/dyndns.bash

curl -O https://raw.githubusercontent.com/HPPinata/Wireguard/main/server/dynv6/Dockerfile
mv Dockerfile build/dynv6
cat build/dynv6/Dockerfile

nano wg0.conf
mkdir -p config/wg_confs
mv wg0.conf config/wg_confs/wg-base.conf

cat <<'EOL' > compose.yml
services:
  dynv6:
    build: ./build/dynv6
    container_name: dynv6
    network_mode: host
    environment:
      - ZONE=( your.zone ) #set dynv6 Zone
      - TK=YOURTOKEN #set dynv6 Token
    restart: unless-stopped

  wireguard:
    image: linuxserver/wireguard:latest
    container_name: wireguard
    cap_add:
      - NET_ADMIN
    network_mode: host
    volumes:
      - ./config:/config
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

cat <<'EOL' | crontab -
SHELL=/bin/bash
BASH_ENV=/etc/profile

@reboot /var/rprox/update.bash
*/5 * * * * /var/rprox/forward.bash
EOL

reboot
