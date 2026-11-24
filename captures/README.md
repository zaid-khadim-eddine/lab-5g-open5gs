# Captures Wireshark

Déposer ici les fichiers `.pcapng` (par exemple `capture-5g-3.pcapng`).

Ouvrir avec Wireshark et appliquer le filtre :

```
ngap || nas-5gs || pfcp || gtp
```

Les captures ne contiennent que du trafic de laboratoire (adresses privées, abonné de test).
