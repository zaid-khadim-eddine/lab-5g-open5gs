# Analyse protocolaire avec Wireshark

## Méthode

- Capture sur la **VM 5G-Lab**, interface `any` (ens33 pour N2/N3, lo pour N4 et SBI, ogstun pour N6)
- Capture lancée **avant** le démarrage du gNB et de l'UE
- Filtres d'affichage :

| Filtre | Ce qu'il montre |
|---|---|
| `ngap \|\| nas-5gs \|\| pfcp \|\| gtp` | Toute la 5G |
| `ngap \|\| nas-5gs` | Signalisation N2 et N1 |
| `pfcp` | Pilotage de l'UPF par le SMF (N4) |
| `gtp && icmp` | Pings encapsulés dans le tunnel N3 |
| `http2` | Échanges SBI entre fonctions du cœur |
| `nas-5gs.mm.message_type == 0x41` | Registration request uniquement |

Sur une capture de démarrage : ~2 700 paquets enregistrés, dont ~3 % de trafic 5G.

## Séquence observée

### Démarrage du cœur (N4)
- `PFCP Association Setup Request` du SMF (127.0.0.4) vers l'UPF (127.0.0.7)
- Premier essai : `ICMP Destination unreachable` (UPF pas encore prêt)
- Nouvel essai quelques secondes plus tard : `Association Setup Response` → association établie
- Puis `PFCP Heartbeat Request / Response` périodiques dans les deux sens

### Raccordement du gNB (N2)
- `NGSetupRequest` 192.168.223.20 → 192.168.223.10, SCTP port 38412 ; le nom `UERANSIM-gnb-999-70-1` est visible dans le message
- `NGSetupResponse` ≈ 6 ms plus tard

### Enregistrement de l'UE (N1 transporté par N2)
- `InitialUEMessage, Registration request` : identité de type **SUCI**, MCC 999 / MNC 70, **schéma de protection NULL** (MSIN lisible)
- `DownlinkNASTransport, Authentication request` / `UplinkNASTransport, Authentication response` (5G-AKA) ; une `Authentication failure` (synch failure) peut apparaître lors d'une resynchronisation SQN
- `Security mode command / complete` : intégrité NIA2, chiffrement NEA0
- `InitialContextSetupRequest, Registration accept` puis `Registration complete`

### Session PDU
- `PDU session establishment request` (UE → AMF → SMF)
- `PFCP Session Establishment Request / Response` (SMF → UPF) : création des règles et du TEID
- `PDUSessionResourceSetupRequest, PDU session establishment accept` (adresse IP de l'UE, TEID côté UPF)
- `PDUSessionResourceSetupResponse` (TEID côté gNB)

### Plan utilisateur (N3)
- Paquets GTP-U 192.168.223.20:2152 → 192.168.223.10:2152 contenant l'ICMP 10.45.0.2 → 8.8.8.8 (double en-tête IP visible)

## Points à retenir

- La signalisation NAS est **transportée de façon transparente** par le gNB dans NGAP (Uplink/DownlinkNASTransport)
- AMF et SMF ne voient jamais le trafic utilisateur : seul l'UPF le transporte
- En laboratoire, SUCI non chiffré et NEA0 rendent tout lisible ; en production : SUCI Profile A/B et NEA1/NEA2
- Diagramme de séquence : *Statistics → Flow Graph*
