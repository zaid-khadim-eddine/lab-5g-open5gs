# Dépannage — problèmes rencontrés et diagnostics

Méthode suivie : suivre le paquet **interface par interface** (`tcpdump -i any`), du téléphone jusqu'à Internet, et identifier la dernière étape où il est encore visible.

---

## 1. Architecture sur une seule VM : accès Internet impossible

**Symptôme** : UE enregistré, session PDU établie, adresse IP attribuée, mais ping vers Internet en échec.

**Diagnostic** (`tcpdump -i any -n icmp`) : le paquet est visible sur `uesimtun0` puis sur `ogstun`, mais ne ressort jamais sur `ens33`.

**Cause** : l'adresse de l'UE (`uesimtun0`) est une adresse **locale** de la machine qui héberge l'UPF. Le noyau Linux rencontre trois problèmes successifs :

| Étape | Effet | Contournement testé |
|---|---|---|
| Paquet entrant sur `ogstun` avec une source locale | Rejeté comme paquet « martien » | `accept_local=1`, `rp_filter=0` |
| Règle `ip rule from 10.45.0.x lookup rt_uesimtun0` ajoutée par UERANSIM | Boucle de routage : `Time to live exceeded` | `ip rule … iif lo` |
| Paquet vu deux fois par conntrack | NAT non appliqué | `iptables -t raw … NOTRACK` |

**Décision** : plutôt qu'empiler des contournements, séparer le RAN et le cœur sur **deux VM**, ce qui correspond au déploiement réel d'un opérateur. Toutes les difficultés disparaissent.

---

## 2. `SCTP could not connect: Connection refused`

**Cause** : dans `amf.yaml`, `address:192.168.223.132` sans espace après les deux-points. YAML n'interprète pas la ligne comme une clé/valeur, l'AMF n'écoute pas sur cette adresse.

**Solution** : `address: 192.168.223.10` puis `systemctl restart open5gs-amfd`.

---

## 3. `Socket bind failed: Address already in use` côté gNB

**Cause** : une instance précédente de `nr-gnb` tourne encore en arrière-plan (ports RLS et GTP occupés).

**Solution** :
```bash
pgrep -a nr-
sudo pkill nr-gnb; sudo pkill nr-ue
```
Puis utilisation systématique de `arreter-5g.sh`.

---

## 4. `ping: SO_BINDTODEVICE uesimtun0: No such device`

**Cause** : l'UE n'est pas connecté (gNB arrêté ou en erreur, mot de passe `sudo` non saisi, gNB lancé après l'UE).

**Solution** : ordre de démarrage **gNB puis UE**, attente de `TUN interface … is up`.

---

## 5. L'adresse de la VM RAN change

**Cause** : adresses attribuées par le DHCP de VMware (plage .128-.254).

**Solution** : adresses fixes hors plage DHCP (.10 et .20) avec `nmcli`, puis mise à jour de `amf.yaml`, `upf.yaml` et `open5gs-gnb.yaml`.

---

## 6. Table de routage vide, `Network is unreachable`

**Diagnostic** : `nmcli device status` → toutes les interfaces `unmanaged` ; `nmcli networking` → `disabled`.

**Solution** : `sudo nmcli networking on`.

---

## 7. VM RAN injoignable, même la passerelle (`Destination Host Unreachable`)

**Diagnostic** : la VM RAN ne joint pas `192.168.223.2` alors que sa configuration IP est correcte → problème sous Ubuntu, dans l'hyperviseur.

**Cause** : carte réseau virtuelle en mode **Bridged** (réseau physique) au lieu de **NAT** (VMnet8).

**Solution** : Settings → Network Adapter → NAT, puis `nmcli connection up`.

---

## 8. Erreur `404 Not Found` pendant `apt install`

**Cause** : liste de paquets locale périmée.

**Solution** : `sudo apt update` avant toute installation.
