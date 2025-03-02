# Security audit with Kali linux

Start Kali linux and emulate testing your localhost from external network.

```bash
docker-compose up -d
docker compose exec -it kali /bin/bash
```

Without Docker Compose:

```bash
docker network create isolated_network
docker run -it --cap-add NET_RAW --cap-add NET_ADMIN --security-opt seccomp=unconfined --security-opt apparmor=unconfined --network isolated_network --name kali kalilinux/kali-rolling /bin/bash
apt update && apt install -y nmap iputils-ping iproute2
```

Get your host ip address:

```bash
# ip route
default via 172.18.0.1 dev eth0
172.18.0.0/16 dev eth0 proto kernel scope link src 172.18.0.2
```

This output means your host address is `172.18.0.1`

Scan ports with Nmap:

```bash
nmap -A 172.18.0.1
```

Try to ping:

```bash
ping 172.18.0.1
```
