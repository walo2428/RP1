# 10 — Configuration Cisco — RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Routeur Cisco 1941W — R1-IRIS

### Rôles

- NAT (Internet → LAN)
- Router-on-stick (inter-VLAN routing via sous-interfaces 802.1Q)
- DHCP Relay (ip helper-address 192.168.50.10)
- SNMP (supervision par SRV-DC01 si implémenté)
- Syslog (journaux vers SRV-DC01)

### Configuration complète

Voir `/cisco/R1-Cisco1941W_config.txt`

### Points clés

```
interface GigabitEthernet0/0.10
 encapsulation dot1Q 10
 ip address 192.168.10.254 255.255.255.0
 ip helper-address 192.168.50.10    <- relay DHCP vers SRV-DC01
```

Le `ip helper-address` est essentiel — sans lui, les clients des VLANs 10/20/30/40/99 ne reçoivent pas d'IP DHCP car leurs broadcasts ne traversent pas le routeur.

---

## 2. Switch Cisco Catalyst 2960-S — SW-IRIS

### Rôles

- Segmentation VLANs (802.1Q)
- Authentification 802.1X sur les ports utilisateurs
- Port trunk vers le routeur
- Port Management vers SRV-DC01

### Configuration complète

Voir `/cisco/SW-Cisco2960S_config.txt`

### Points clés

```
! Tous les ports utilisateurs démarrent en VLAN 99 (PRE-AUTH)
! L'authentification 802.1X change dynamiquement le VLAN selon NPS
interface range FastEthernet0/1 - 20
 switchport access vlan 99
 dot1x port-control auto
```

### VLANs configurés

| VLAN ID | Nom |
|---------|-----|
| 10 | IRIS-Etudiants |
| 20 | Professeurs |
| 30 | Administration |
| 40 | Guest |
| 50 | Management |
| 99 | PRE-AUTH |

---

## 3. Borne WiFi Cisco C9105AXI — AP-IRIS

### Rôles

- SSID IRIS-WiFi : WPA3-Enterprise 802.1X → NPS → VLAN dynamique
- SSID IRIS-Guest : ouvert → VLAN 40 fixe

### Configuration de base

```
ssid IRIS-WiFi
 security wpa3
 dot1x authentication-server 192.168.50.10
 vlan 99              ! VLAN par défaut avant auth

ssid IRIS-Guest
 security open
 vlan 40              ! VLAN fixe - pas de NPS

radius-server host 192.168.50.10
 auth-port 1812
 acct-port 1813
 key [SECRET_RADIUS]
```

---

## 4. Secret RADIUS partagé

Le secret RADIUS est configuré de façon identique sur :
- SRV-DC01 (NPS — dans les propriétés de chaque client RADIUS)
- SW-IRIS (commande `radius-server host 192.168.50.10 key [SECRET]`)
- AP-IRIS (configuration RADIUS de la borne)
- R1-IRIS (si authentification VPN via RADIUS)

Le secret n'est pas publié dans ce dépôt.

---

## 5. Journaux Syslog (optionnel)

Pour envoyer les journaux Cisco vers SRV-DC01 (si rsyslog est installé) :

```
logging host 192.168.50.10
logging source-interface Vlan50
logging trap informational
service timestamps log datetime msec
```

---

## 6. Supervision SNMP (optionnel)

```
snmp-server community iris-nice RO
snmp-server host 192.168.50.10 version 2c iris-nice
```

---

## 7. Accès SSH sécurisé au switch

```
ip domain-name iris.local
crypto key generate rsa modulus 2048
ip ssh version 2
username admin privilege 15 secret [MOT_DE_PASSE]
line vty 0 15
 transport input ssh
 login local
```
