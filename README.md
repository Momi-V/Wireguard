# Wireguard
Setup Scripts to create a Wireguard reverseVPN

## Preparation:
  1. Domain: 1 Zone with Wildcard CNAME (completely free) from [dynv6.com](https://dynv6.com)
  2. Install wireguard-tools locally to generate Keys
  3. wg0 config files with keys prepared [(see below)](https://github.com/HPPinata/Wireguard//main/README.md#generate-keys)
  4. Cloud server with public IP/IPv6
       - Kernel with Wireguard
       - Firewalld, Docker, Docker-Compose, nano, cron and wget installed
  5. VM/RasPi/PC in local Network
       - Kernel with Wireguard
       - Firewalld, Docker, Docker-Compose, nano, cron and wget installed

### Generate Keys:
```
mkdir server client
for i in server client; do
  cd $i
  wget https://raw.githubusercontent.com/HPPinata/Wireguard/main/$i/wg0.conf.templ
  cat wg0.conf.templ > wg0.conf
  wg genkey > pri.key
  wg pubkey > pub.key < pri.key
  wg genpsk > psk.key
  cd ..
done
for i in server/pri.key server/pub.key server/psk.key client/pri.key client/pub.key; do
  sed -i "s;$i;$(cat $i);g" ./server/wg0.conf ./client/wg0.conf
done
```
