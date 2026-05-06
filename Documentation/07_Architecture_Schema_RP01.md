# 07 — Architecture et plan d'adressage RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Schéma réseau

Le schéma réseau complet est disponible dans `/schema/schema-reseau-RP1.png`.

```
                            INTERNET
                                |
                       [R1-IRIS — Cisco 1941W]
                            192.168.50.254
                     NAT | ACL | Router-on-stick
                     ip helper-address 192.168.50.10
                                |
                          Trunk 802.1Q
                         (VLANs 10-99)
                                |
                  [SW-IRIS — Cisco Catalyst 2960-S]
                           192.168.50.253
                        802.1X sur Fa0/1-20
                    /           |            \
                   /            |             \
         [SRV-DC01]      [AP-IRIS C9105AXI]  [Postes filaires]
         192.168.50.10   192.168.50.150       VLAN 99 (PRE-AUTH)
                                              --> auth 802.1X
         AD DS | DNS             |            --> VLAN 10/20/30
         DHCP | NPS         IRIS-WiFi
         ADCS | SMB         WPA3-Enterprise
                            802.1X
                            IRIS-Guest (VLAN 40)

    VLANs dynamiques apres authentification
    VLAN 10 : Etudiants SISR+SLAM  192.168.10.0/24
    VLAN 20 : Professeurs          192.168.20.0/24
    VLAN 30 : Administration       192.168.30.0/24
    VLAN 40 : Guest (ouvert)       192.168.40.0/24
    VLAN 50 : Management (fixes)   192.168.50.0/24
    VLAN 99 : PRE-AUTH (defaut)    192.168.99.0/24
```

---

## 2. Plan d'adressage complet

### Equipements fixes — VLAN 50 Management

| Equipement | Modèle | Nom | IP | Interface |
|-----------|--------|-----|-----|----------|
| Contrôleur de domaine | Windows Server 2022 | SRV-DC01 | 192.168.50.10 | Ethernet 2 |
| Switch | Cisco Catalyst 2960-S | SW-IRIS | 192.168.50.253 | Vlan50 |
| Borne WiFi | Cisco C9105AXI-E | AP-IRIS | 192.168.50.150 | Management |
| Routeur | Cisco 1941W-E/K9 | R1-IRIS | 192.168.50.254 | Gi0/0.50 |

### Sous-interfaces routeur (Router-on-stick)

| Interface | VLAN | IP passerelle | ip helper-address |
|-----------|------|-------------|------------------|
| Gi0/0.10 | 10 | 192.168.10.254 | 192.168.50.10 |
| Gi0/0.20 | 20 | 192.168.20.254 | 192.168.50.10 |
| Gi0/0.30 | 30 | 192.168.30.254 | 192.168.50.10 |
| Gi0/0.40 | 40 | 192.168.40.254 | 192.168.50.10 |
| Gi0/0.50 | 50 | 192.168.50.254 | — |
| Gi0/0.99 | 99 native | 192.168.99.254 | 192.168.50.10 |
| Gi0/1 | — | DHCP (WAN) | — |

### Scopes DHCP

| Scope | Réseau | Plage | Passerelle | DNS | Bail |
|-------|--------|-------|-----------|-----|------|
| VLAN10-Etudiants | 192.168.10.0/24 | .10 – .250 | 192.168.10.254 | 192.168.50.10 | 8 jours |
| VLAN20-Professeurs | 192.168.20.0/24 | .10 – .250 | 192.168.20.254 | 192.168.50.10 | 8 jours |
| VLAN30-Administration | 192.168.30.0/24 | .10 – .250 | 192.168.30.254 | 192.168.50.10 | 8 jours |
| VLAN40-Guest | 192.168.40.0/24 | .10 – .250 | 192.168.40.254 | 8.8.8.8 | 1 jour |
| VLAN99-PreAuth | 192.168.99.0/24 | .10 – .250 | 192.168.99.254 | 192.168.50.10 | 1 jour |

---

## 3. Politique d'accès par VLAN

| VLAN | Accès aux partages SMB | Accès internet | Services internes |
|------|----------------------|---------------|------------------|
| 10 — Etudiants | SISR ou SLAM + Commun (lecture) + HomeDir | Oui | iris.local |
| 20 — Professeurs | Professeurs + Commun (modification) + HomeDir | Oui | iris.local |
| 30 — Administration | Administration + HomeDir | Oui | iris.local |
| 40 — Guest | Aucun | Oui | Non (DNS public 8.8.8.8) |
| 50 — Management | Tout | Oui | Tout |
| 99 — PRE-AUTH | Aucun (en attente auth) | Non | Non |

---

## 4. Flux réseau détaillés

### Authentification 802.1X filaire

```
Poste (VLAN 99 par défaut)
  --> EAP-Request Identity vers Switch
  --> Switch encapsule en RADIUS Access-Request vers NPS:1812
  --> NPS vérifie IP source (doit être client RADIUS enregistré)
  --> NPS authentifie via AD (MS-CHAPv2)
  --> NPS cherche politique réseau correspondante (groupe AD)
  --> RADIUS Access-Accept + Tunnel-Pvt-Group-ID
  --> Switch configure le port en VLAN 10/20/30
  --> Poste demande IP DHCP (broadcast)
  --> Routeur relaie vers SRV-DC01 (ip helper-address)
  --> SRV-DC01 répond avec IP du scope du VLAN
```

### Accès aux partages SMB

```
Client (VLAN 10/20/30)
  --> \\SRV-DC01\SISR (SMB port 445)
  --> Authentification Kerberos (ticket AD)
  --> Vérification ACL NTFS (groupe AD de l'utilisateur)
  --> Accès accordé ou refusé
```

### Mappage lecteurs réseau (GPO Préférences)

```
Logon utilisateur
  --> Moteur GPO applique IRIS-LecteursReseau
  --> Lit Drives.xml dans SYSVOL
  --> Vérifie le SID de l'utilisateur contre les FilterGroup
  --> Monte H: pour tous
  --> Monte S: selon le groupe (SISR ou SLAM ou Profs)
  --> Monte P: si SISR ou SLAM ou Profs
  --> Monte A: si Administration
  --> Connexion différée (lazy) — OK au premier accès réel
```

---

## 5. Ports réseau utilisés

| Port | Proto | Service | Direction |
|------|-------|---------|----------|
| 53 | UDP/TCP | DNS | Client → SRV-DC01 |
| 67/68 | UDP | DHCP | Client → SRV-DC01 via relais |
| 88 | TCP/UDP | Kerberos | Client → SRV-DC01 |
| 135 | TCP | RPC Endpoint Mapper | Client → SRV-DC01 |
| 389 | TCP/UDP | LDAP | Client → SRV-DC01 |
| 445 | TCP | SMB | Client → SRV-DC01 |
| 636 | TCP | LDAPS | Client → SRV-DC01 |
| 1812 | UDP | RADIUS Auth | Switch/AP → SRV-DC01 |
| 1813 | UDP | RADIUS Accounting | Switch/AP → SRV-DC01 |
| 3268 | TCP | Global Catalog LDAP | Client → SRV-DC01 |

---

## 6. Dépendances entre services

```
AD DS (iris.local)
    ├── DNS Server (intégré AD — dépendance forte)
    ├── Kerberos (intégré AD)
    ├── DHCP Server (s'enregistre dans AD)
    ├── NPS (s'enregistre dans AD — vérifie credentials)
    ├── ADCS Enterprise Root CA (nécessite AD DS)
    │   └── Certificat NPS (délivré par ADCS)
    ├── GPO / SYSVOL (stockées dans AD + SYSVOL)
    └── SMB / NTFS (permissions via groupes AD)
```

En cas de panne, priorité de restauration : **AD DS + DNS** en premier, puis les autres services.
