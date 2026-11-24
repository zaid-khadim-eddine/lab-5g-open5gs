#!/bin/bash
# Configuration persistante du cœur (VM 5G-Lab) : routage IP + NAT des UE
# À exécuter une seule fois. Usage : sudo ./preparer-coeur.sh

set -e

# Routage IP permanent
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-5g.conf
sysctl --system > /dev/null

# NAT des adresses des UE vers Internet (ajout seulement si absent)
if ! iptables -t nat -C POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE 2>/dev/null; then
  iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE
fi

# Persistance des règles
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent > /dev/null
netfilter-persistent save
systemctl enable netfilter-persistent

echo "Cœur prêt : ip_forward=$(sysctl -n net.ipv4.ip_forward), NAT sauvegardé."
