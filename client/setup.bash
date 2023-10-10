#!/bin/bash

mkdir /var/rprox
cd /var/rprox

cat <<'EOL' > /etc/modules-load.d/wireguard.conf
# Load wireguard module at boot
wireguard
EOL

wget "https://raw.githubusercontent.com/HPPinata/Wireguard/main/client/forward.bash"
nano forward.bash
chmod +x forward.bash
bash forward.bash

cat <<'EOL' | crontab -
*/5 * * * * bash /var/rprox/forward.bash
EOL

mkdir -p build/wireguard

cat <<'EOL' > ./Caddyfile
{
  email    your@mail.com
  key_type p384
  #acme_ca  https://acme-staging-v02.api.letsencrypt.org/directory
  #local_certs
}

prefix.your.domain:port {
  reverse_proxy https://intern:port {
    transport http {
      tls_insecure_skip_verify #if internal cert is self signed
    }
  }
}

prefix2.your.domain:port {
  reverse_proxy https://intern:port #http:// for non-TLS, https:// for trusted cert
}
EOL
nano ./Caddyfile
cat ./Caddyfile

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
  wireguard:
    build: ./build/wireguard
    container_name: wireguard
    privileged: true
    network_mode: host
    restart: unless-stopped

  caddy:
    image: caddy:alpine
    container_name: caddy
    network_mode: host
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    restart: unless-stopped

volumes:
  caddy_data:
  caddy_config:
EOL
cat compose.yml

cat <<'EOL' > /var/rprox/update.bash
#!/bin/bash
cd /var/rprox
docker-compose pull
docker-compose build --pull
docker-compose up -dV
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
ExecStop=bash -c '/bin/docker-compose down -f /var/rprox/compose.yml'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOL
systemctl enable /etc/systemd/system/proxy-compose.service
