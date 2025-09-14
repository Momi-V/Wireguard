#!/bin/bash

mkdir /var/rprox
cd /var/rprox

cat <<'EOL' > /etc/modules-load.d/wireguard.conf
# Load wireguard module at boot
wireguard
EOL

curl -O https://raw.githubusercontent.com/Momi-V/Wireguard/main/client/forward.bash
nano forward.bash
chmod +x forward.bash
bash forward.bash

curl -O https://raw.githubusercontent.com/Momi-V/Wireguard/main/client/Caddyfile
nano ./Caddyfile
cat ./Caddyfile

nano wg0.conf
mkdir -p config-prox/wg_confs
mv wg0.conf config-prox/wg_confs/wg-base.conf

mkdir config
cat <<'EOL' > config/config.yml
advanced:
  log_level: trace

core:
  admin_user: admin@admin.net
  admin_password: changeME #your password
  import_existing: false

web:
  external_url: https://your.external.url #replace with the external URL
  request_logging: true
EOL
nano config/config.yml

cat <<'EOL' > compose.yml
services:
  wireguard-prox:
    image: linuxserver/wireguard:latest
    container_name: wireguard-prox
    cap_add:
      - NET_ADMIN
    network_mode: host
    volumes:
      - ./config-prox:/config
    environment:
      - TZ=Europe/Berlin
    restart: unless-stopped

  caddy:
    image: caddy:alpine
    container_name: caddy
    network_mode: host
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    environment:
      - TZ=Europe/Berlin
    restart: unless-stopped

  wg-portal:
    image: wgportal/wg-portal:latest
    container_name: wg-portal
    cap_add:
      - NET_ADMIN
    network_mode: host
    volumes:
      - wg_data:/app/data
      - ./config:/app/config
    environment:
      - TZ=Europe/Berlin
    restart: unless-stopped

volumes:
  caddy_data:
  caddy_config:
  wg_data:
EOL
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
