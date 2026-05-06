# 16 — Configuration DHCP Complète RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Vue d'ensemble

Le service DHCP est hébergé sur **SRV-DC01** (192.168.50.10). Il distribue des adresses IP dynamiques pour 5 VLANs. Le VLAN 50 (Management) n'a pas de scope DHCP : tous les équipements du VLAN 50 ont des IPs fixes.

| Paramètre | Valeur |
|-----------|--------|
| Serveur DHCP | SRV-DC01 |
| IP du serveur | 192.168.50.10 |
| Service | Windows Server DHCP Server |
| Autorisation AD | Oui — serveur autorisé dans AD |
| Nombre de scopes | 5 |

---

## 2. Détail des scopes

### Scope VLAN 10 — Etudiants SISR/SLAM

| Paramètre | Valeur |
|-----------|--------|
| Nom du scope | VLAN10-Etudiants |
| ID du réseau | 192.168.10.0 |
| Masque | 255.255.255.0 (/24) |
| Plage de distribution | 192.168.10.10 — 192.168.10.250 |
| Exclusions | 192.168.10.1 — 192.168.10.9 (réservées infrastructure) |
| Passerelle (003) | 192.168.10.1 (interface VLAN 10 du routeur R1-IRIS) |
| DNS (006) | 192.168.50.10 (SRV-DC01) |
| Domaine (015) | iris.local |
| Durée du bail | 8 heures |
| Etat | Actif |
| VLAN associé | VLAN 10 — 802.1Q tag 10 |

### Scope VLAN 20 — Professeurs

| Paramètre | Valeur |
|-----------|--------|
| Nom du scope | VLAN20-Professeurs |
| ID du réseau | 192.168.20.0 |
| Masque | 255.255.255.0 (/24) |
| Plage de distribution | 192.168.20.10 — 192.168.20.250 |
| Exclusions | 192.168.20.1 — 192.168.20.9 |
| Passerelle (003) | 192.168.20.1 |
| DNS (006) | 192.168.50.10 |
| Domaine (015) | iris.local |
| Durée du bail | 8 heures |
| Etat | Actif |
| VLAN associé | VLAN 20 — 802.1Q tag 20 |

### Scope VLAN 30 — Administration

| Paramètre | Valeur |
|-----------|--------|
| Nom du scope | VLAN30-Administration |
| ID du réseau | 192.168.30.0 |
| Masque | 255.255.255.0 (/24) |
| Plage de distribution | 192.168.30.10 — 192.168.30.250 |
| Exclusions | 192.168.30.1 — 192.168.30.9 |
| Passerelle (003) | 192.168.30.1 |
| DNS (006) | 192.168.50.10 |
| Domaine (015) | iris.local |
| Durée du bail | 8 heures |
| Etat | Actif |
| VLAN associé | VLAN 30 — 802.1Q tag 30 |

### Scope VLAN 40 — Guest (Invités)

| Paramètre | Valeur |
|-----------|--------|
| Nom du scope | VLAN40-Guest |
| ID du réseau | 192.168.40.0 |
| Masque | 255.255.255.0 (/24) |
| Plage de distribution | 192.168.40.10 — 192.168.40.250 |
| Exclusions | 192.168.40.1 — 192.168.40.9 |
| Passerelle (003) | 192.168.40.1 |
| DNS (006) | **8.8.8.8** (pas SRV-DC01 — invités n'ont pas accès AD) |
| Domaine (015) | Non configuré |
| Durée du bail | 2 heures (bail court pour les invités) |
| Etat | Actif |
| VLAN associé | VLAN 40 — 802.1Q tag 40 |
| ⚠️ Remarque | DNS = 8.8.8.8 volontairement — les invités ne doivent pas résoudre iris.local |

### Scope VLAN 99 — PRE-AUTH 802.1X

| Paramètre | Valeur |
|-----------|--------|
| Nom du scope | VLAN99-PreAuth |
| ID du réseau | 192.168.99.0 |
| Masque | 255.255.255.0 (/24) |
| Plage de distribution | 192.168.99.10 — 192.168.99.250 |
| Exclusions | 192.168.99.1 — 192.168.99.9 |
| Passerelle (003) | 192.168.99.1 |
| DNS (006) | 192.168.50.10 |
| Durée du bail | 30 minutes (très court — VLAN de transit) |
| Etat | Actif |
| VLAN associé | VLAN 99 — 802.1Q tag 99 |
| ⚠️ Remarque | VLAN de pré-authentification 802.1X. Les postes non authentifiés arrivent ici. Après auth RADIUS, ils basculent vers VLAN 10/20/30. |

---

## 3. VLAN 50 — Management (pas de scope DHCP)

Le VLAN 50 n'a **pas de scope DHCP**. Tous les équipements ont des IPs fixes :

| Equipement | IP Fixe | Usage |
|-----------|---------|-------|
| SRV-DC01 | 192.168.50.10 | Contrôleur de domaine, DHCP, DNS, NPS, ADCS |
| SW-IRIS | 192.168.50.253 | Switch Cisco 2960-S |
| AP-IRIS | 192.168.50.150 | Borne WiFi Cisco C9105AXI |
| R1-IRIS | 192.168.50.254 | Routeur Cisco 1941W |

---

## 4. Relayage DHCP (ip helper-address)

Le serveur DHCP est unique (SRV-DC01 192.168.50.10). Pour que les clients des VLANs 10/20/30/40/99 obtiennent leurs adresses, le routeur R1-IRIS doit relayer les requêtes DHCP vers SRV-DC01.

Configuration sur R1-IRIS (interface VLAN par VLAN) :

```cisco
interface GigabitEthernet0/0.10
 ip helper-address 192.168.50.10

interface GigabitEthernet0/0.20
 ip helper-address 192.168.50.10

interface GigabitEthernet0/0.30
 ip helper-address 192.168.50.10

interface GigabitEthernet0/0.40
 ip helper-address 192.168.50.10

interface GigabitEthernet0/0.99
 ip helper-address 192.168.50.10
```

---

## 5. Commandes PowerShell de vérification

```powershell
# Lister tous les scopes
Get-DhcpServerv4Scope

# Voir les baux actifs d'un scope
Get-DhcpServerv4Lease -ScopeId 192.168.10.0

# Vérifier les options d'un scope
Get-DhcpServerv4OptionValue -ScopeId 192.168.10.0

# Vérifier que le serveur est autorisé dans AD
Get-DhcpServerInDC

# Statistiques de baux
Get-DhcpServerv4ScopeStatistics

# Exclure une plage
Add-DhcpServerv4ExclusionRange -ScopeId 192.168.10.0 -StartRange 192.168.10.1 -EndRange 192.168.10.9
```

---

## 6. Tableau récapitulatif

| VLAN | Réseau | Plage DHCP | Passerelle | DNS | Bail |
|------|--------|-----------|-----------|-----|------|
| 10 | 192.168.10.0/24 | .10 — .250 | 192.168.10.1 | 192.168.50.10 | 8h |
| 20 | 192.168.20.0/24 | .10 — .250 | 192.168.20.1 | 192.168.50.10 | 8h |
| 30 | 192.168.30.0/24 | .10 — .250 | 192.168.30.1 | 192.168.50.10 | 8h |
| 40 | 192.168.40.0/24 | .10 — .250 | 192.168.40.1 | 8.8.8.8 | 2h |
| 50 | 192.168.50.0/24 | Pas de scope | — | — | IPs fixes |
| 99 | 192.168.99.0/24 | .10 — .250 | 192.168.99.1 | 192.168.50.10 | 30min |
