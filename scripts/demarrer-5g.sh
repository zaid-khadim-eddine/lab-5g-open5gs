#!/bin/bash
# Démarrage du laboratoire 5G (VM 5G-RAN) : gNB + UE, puis test d'accès Internet
# Usage : ~/demarrer-5g.sh

CORE_IP="192.168.223.10"
UERANSIM_DIR="$HOME/UERANSIM"

echo "=== 1. Vérification de la liaison avec le cœur ($CORE_IP) ==="
if ! ping -c 2 -W 2 "$CORE_IP" > /dev/null; then
  echo "ERREUR : le cœur est injoignable."
  echo "Vérifie que la VM 5G-Lab est démarrée et que les deux VM sont en NAT."
  exit 1
fi
echo "OK : le cœur est joignable."

echo "=== 2. Démarrage de l'antenne (gNB) ==="
gnome-terminal -- bash -c "printf '\033]0;1 - ANTENNE\007'; cd $UERANSIM_DIR; ./build/nr-gnb -c config/open5gs-gnb.yaml; exec bash"
sleep 3

echo "=== 3. Démarrage du téléphone (UE) ==="
echo "-> Tape ton mot de passe dans la fenêtre 2 - TELEPHONE"
gnome-terminal -- bash -c "printf '\033]0;2 - TELEPHONE\007'; cd $UERANSIM_DIR; sudo ./build/nr-ue -c config/open5gs-ue.yaml; exec bash"

echo "=== 4. Attente de la connexion du téléphone ==="
for i in $(seq 1 60); do
  if ip link show uesimtun0 > /dev/null 2>&1; then
    echo "OK : le téléphone est connecté."
    break
  fi
  sleep 1
done

if ! ip link show uesimtun0 > /dev/null 2>&1; then
  echo "ERREUR : le téléphone ne s'est pas connecté. Regarde les fenêtres 1 et 2."
  exit 1
fi

echo "=== 5. Test d'accès à Internet ==="
sleep 2
ping -I uesimtun0 -c 3 8.8.8.8
