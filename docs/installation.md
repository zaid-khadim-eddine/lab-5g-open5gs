# Guide d'installation

Toutes les commandes sont pour **Ubuntu 22.04 LTS**. Ubuntu 26.04 n'est pas encore supporté par le dépôt officiel de MongoDB.

---

## 1. VM 5G-Lab (cœur)

### Outils de base
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl gnupg net-tools iperf3 software-properties-common
```

### MongoDB 8.0
```bash
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update && sudo apt install -y mongodb-org
sudo systemctl enable --now mongod
```

### Open5GS
```bash
sudo add-apt-repository ppa:open5gs/latest
sudo apt update && sudo apt install -y open5gs
systemctl list-units 'open5gs-*'
```

### Node.js 20 et WebUI
```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update && sudo apt install -y nodejs
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
```

WebUI : `http://localhost:9999` (identifiants par défaut de la documentation Open5GS — à changer).

Abonné de test :
| Champ | Valeur |
|---|---|
| IMSI | 999700000000001 |
| K | 465B5CE8B199B49FAA5F0A2EE238A6BC |
| USIM Type | OPc |
| OPc | E8ED289DEBA952E4283B54E88E6183CA |

### Adresse fixe
```bash
sudo nmcli connection modify "Wired connection 1" ipv4.method manual \
  ipv4.addresses 192.168.223.10/24 ipv4.gateway 192.168.223.2 ipv4.dns 192.168.223.2
sudo nmcli connection up "Wired connection 1"
```

### Exposition N2 et N3
Dans `/etc/open5gs/amf.yaml` (section `ngap`) et `/etc/open5gs/upf.yaml` (section `gtpu`) : `address: 192.168.223.10` (voir [config/](../config/)).
```bash
sudo systemctl restart open5gs-amfd open5gs-upfd
```

### Routage et NAT persistants
```bash
sudo ./scripts/preparer-coeur.sh
```

---

## 2. VM 5G-RAN (accès radio)

Clone complet de la VM 5G-Lab (réseau VMware en **NAT**, adresse MAC régénérée si besoin).

### Nettoyage du clone
```bash
sudo hostnamectl set-hostname 5G-RAN
sudo systemctl disable --now 'open5gs-*' mongod
sudo ip link delete ogstun
```

### Adresse fixe
```bash
sudo nmcli connection modify "Wired connection 1" ipv4.method manual \
  ipv4.addresses 192.168.223.20/24 ipv4.gateway 192.168.223.2 ipv4.dns 192.168.223.2
sudo nmcli connection up "Wired connection 1"
```

### UERANSIM
```bash
sudo apt install -y make gcc g++ libsctp-dev lksctp-tools iproute2
sudo snap install cmake --classic
cd ~ && git clone https://github.com/aligungr/UERANSIM
cd UERANSIM && make -j4
```

### Configuration du gNB
```bash
cd ~/UERANSIM
sed -i 's/^ngapIp:.*/ngapIp: 192.168.223.20/' config/open5gs-gnb.yaml
sed -i 's/^gtpIp:.*/gtpIp: 192.168.223.20/' config/open5gs-gnb.yaml
sed -i 's/address: 127.0.0.5/address: 192.168.223.10/' config/open5gs-gnb.yaml
```

### Scripts
```bash
cp scripts/demarrer-5g.sh scripts/arreter-5g.sh ~/
chmod +x ~/demarrer-5g.sh ~/arreter-5g.sh
```

---

## 3. Test
```bash
~/demarrer-5g.sh
```
Attendu : `NG Setup procedure is successful`, `TUN interface[uesimtun0, 10.45.0.x] is up`, puis ping à 0 % de perte.
