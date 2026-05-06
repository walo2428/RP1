# 18 — Plan d'Adressage IP et VLANs RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Plan d'adressage complet

### Tableau général des VLANs

| VLAN ID | Nom | Réseau | Masque | Plage hôtes | Passerelle | Utilisation |
|---------|-----|--------|--------|------------|-----------|-------------|
| 10 | Etudiants | 192.168.10.0 | /24 | .1 — .254 | 192.168.10.1 | SISR + SLAM WiFi & filaire |
| 20 | Professeurs | 192.168.20.0 | /24 | .1 — .254 | 192.168.20.1 | Profs WiFi & filaire |
| 30 | Administration | 192.168.30.0 | /24 | .1 — .254 | 192.168.30.1 | Secrétariat, direction |
| 40 | Guest | 192.168.40.0 | /24 | .1 — .254 | 192.168.40.1 | Invités, SSID ouvert |
| 50 | Management | 192.168.50.0 | /24 | .1 — .254 | 192.168.50.254 | Serveurs, équipements réseau |
| 99 | PreAuth | 192.168.99.0 | /24 | .1 — .254 | 192.168.99.1 | Transit 802.1X non authentifiés |

---

## 2. Adresses IP fixes — VLAN 50 Management

| Equipement | Hostname | IP | Rôle |
|-----------|---------|-----|------|
| Serveur DC | SRV-DC01 | 192.168.50.10 | DC, DNS, DHCP, NPS, ADCS |
| Switch | SW-IRIS | 192.168.50.253 | Cisco Catalyst 2960-S |
| Borne WiFi | AP-IRIS | 192.168.50.150 | Cisco C9105AXI |
| Routeur | R1-IRIS | 192.168.50.254 | Cisco 1941W (passerelle VLAN 50) |

---

## 3. Interfaces du routeur R1-IRIS (router-on-a-stick)

| Interface | VLAN | IP | Description |
|----------|------|-----|-------------|
| Gi0/0 | trunk | — | Lien trunk vers SW-IRIS |
| Gi0/0.10 | 10 | 192.168.10.1/24 | Passerelle VLAN Etudiants |
| Gi0/0.20 | 20 | 192.168.20.1/24 | Passerelle VLAN Professeurs |
| Gi0/0.30 | 30 | 192.168.30.1/24 | Passerelle VLAN Administration |
| Gi0/0.40 | 40 | 192.168.40.1/24 | Passerelle VLAN Guest |
| Gi0/0.50 | 50 | 192.168.50.254/24 | Passerelle VLAN Management |
| Gi0/0.99 | 99 | 192.168.99.1/24 | Passerelle VLAN PreAuth |
| Gi0/1 | — | DHCP (opérateur) | Interface WAN vers internet |

---

## 4. VirtualBox — Configuration réseau LAB

Dans le cadre du LAB VirtualBox, la configuration est simplifiée :

| Carte VirtualBox | Type | IP | Usage |
|-----------------|------|-----|-------|
| Ethernet (Carte 1) | NAT | 10.0.2.15 (DHCP VBox) | Accès internet pour SRV-DC01 |
| Ethernet 2 (Carte 2) | Host-Only (vboxnet0) | 192.168.50.10 | Communication SRV-DC01 ↔ SISR-01 |

> En LAB VirtualBox, les VLANs 10/20/30/40/99 sont simulés. Le réseau réel entre les VMs est le VLAN 50 (192.168.50.0/24). Sur infrastructure physique, les VLANs sont portés par le switch Cisco 2960-S.

---

## 5. Configuration IP de SRV-DC01

```powershell
# Carte Ethernet 2 (Host-Only) — IP fixe
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 192.168.50.10 -PrefixLength 24 -DefaultGateway 192.168.50.254
Set-DnsClientServerAddress -InterfaceAlias "Ethernet 2" -ServerAddresses 127.0.0.1

# Carte Ethernet (NAT) — reste en DHCP VirtualBox
# IP automatique 10.0.2.15
```

---

## 6. Configuration IP de SISR-01 (Windows 11)

```powershell
# Après jonction au domaine, IP obtenue par DHCP sur VLAN simulé en LAB
# IP : 192.168.50.x (Host-Only — même réseau que SRV-DC01 en LAB)
# DNS : 192.168.50.10 (SRV-DC01)
# Passerelle : 192.168.50.254
```

---

## 7. Plan de sous-réseaux détaillé

### VLAN 10 — Etudiants (192.168.10.0/24)

| Plage | Usage |
|-------|-------|
| 192.168.10.1 | Passerelle (R1-IRIS Gi0/0.10) |
| 192.168.10.2 — .9 | Réservées (futurs équipements) |
| 192.168.10.10 — .250 | DHCP — postes étudiants |
| 192.168.10.251 — .254 | Réservées |
| 192.168.10.255 | Broadcast |

### VLAN 20 — Professeurs (192.168.20.0/24)

| Plage | Usage |
|-------|-------|
| 192.168.20.1 | Passerelle (R1-IRIS Gi0/0.20) |
| 192.168.20.2 — .9 | Réservées |
| 192.168.20.10 — .250 | DHCP — postes professeurs |
| 192.168.20.255 | Broadcast |

### VLAN 30 — Administration (192.168.30.0/24)

| Plage | Usage |
|-------|-------|
| 192.168.30.1 | Passerelle (R1-IRIS Gi0/0.30) |
| 192.168.30.2 — .9 | Réservées |
| 192.168.30.10 — .250 | DHCP — postes administration |
| 192.168.30.255 | Broadcast |

### VLAN 40 — Guest (192.168.40.0/24)

| Plage | Usage |
|-------|-------|
| 192.168.40.1 | Passerelle (R1-IRIS Gi0/0.40) |
| 192.168.40.2 — .9 | Réservées |
| 192.168.40.10 — .250 | DHCP — invités WiFi |
| 192.168.40.255 | Broadcast |

### VLAN 50 — Management (192.168.50.0/24)

| Plage | Usage |
|-------|-------|
| 192.168.50.1 — .9 | Réservées |
| 192.168.50.10 | SRV-DC01 |
| 192.168.50.11 — .149 | Réservées (futurs serveurs) |
| 192.168.50.150 | AP-IRIS (Cisco C9105AXI) |
| 192.168.50.151 — .252 | Réservées |
| 192.168.50.253 | SW-IRIS (Cisco 2960-S) |
| 192.168.50.254 | R1-IRIS (Cisco 1941W) |
| 192.168.50.255 | Broadcast |

### VLAN 99 — PreAuth (192.168.99.0/24)

| Plage | Usage |
|-------|-------|
| 192.168.99.1 | Passerelle (R1-IRIS Gi0/0.99) |
| 192.168.99.2 — .9 | Réservées |
| 192.168.99.10 — .250 | DHCP — postes en cours d'auth 802.1X |
| 192.168.99.255 | Broadcast |

---

## 8. Flux réseau autorisés

| Source | Destination | Protocole | Description |
|--------|------------|-----------|-------------|
| VLAN 10/20/30 | 192.168.50.10 | TCP 389/636/88 | LDAP/LDAPS/Kerberos vers AD |
| VLAN 10/20/30 | 192.168.50.10 | UDP 53 | DNS interne |
| VLAN 10/20/30 | 192.168.50.10 | TCP 445 | SMB (partages réseau) |
| VLAN 40 | Internet | TCP 80/443 | Web seulement |
| VLAN 40 | 192.168.50.x | Bloqué | Isolation guest |
| VLAN 99 | 192.168.50.10 | UDP 1812/1813 | RADIUS auth + accounting |
| Cisco équipements | 192.168.50.10 | UDP 1812 | RADIUS depuis switch/AP/routeur |
| VLAN 10/20/30 | Internet | TCP 80/443 | Web via R1-IRIS |
