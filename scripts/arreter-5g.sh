#!/bin/bash
# Arrêt propre du laboratoire 5G (VM 5G-RAN) : UE puis gNB
echo "Arrêt du téléphone (UE)..."
sudo pkill nr-ue
sleep 2
echo "Arrêt de l'antenne (gNB)..."
pkill nr-gnb
echo "Laboratoire arrêté."
