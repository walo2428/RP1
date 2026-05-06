# 17 — Configuration DNS Complète RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Vue d'ensemble

Le service DNS est hébergé sur **SRV-DC01** (192.168.50.10), intégré à Active Directory. Il est le seul résolveur DNS interne du domaine iris.local.

| Paramètre | Valeur |
|-----------|--------|
| Serveur DNS | SRV-DC01 |
| IP | 192.168.50.10 |
| Type | DNS intégré à Active Directory |
| Zone principale | iris.local |
| Zone inverse | 50.168.192.in-addr.arpa |
| Forwarders | 8.8.8.8, 1.1.1.1 |

---

## 2. Zones DNS

### Zone directe — iris.local

| Paramètre | Valeur |
|-----------|--------|
| Nom | iris.local |
| Type | Principale intégrée AD |
| Réplication | Tous les contrôleurs de domaine de la forêt |
| Mise à jour dynamique | Sécurisée uniquement |
| Durée TTL par défaut | 1 heure (3600s) |

#### Enregistrements principaux

| Nom | Type | Valeur | Description |
|-----|------|--------|-------------|
| @ (iris.local) | SOA | SRV-DC01.iris.local | Serveur faisant autorité |
| @ (iris.local) | NS | SRV-DC01.iris.local | Serveur de noms |
| SRV-DC01 | A | 192.168.50.10 | Contrôleur de domaine |
| _ldap._tcp.iris.local | SRV | 192.168.50.10:389 | Localisation LDAP (auto AD) |
| _kerberos._tcp.iris.local | SRV | 192.168.50.10:88 | Kerberos (auto AD) |
| _gc._tcp.iris.local | SRV | 192.168.50.10:3268 | Global Catalog (auto AD) |
| SW-IRIS | A | 192.168.50.253 | Switch Cisco 2960-S |
| AP-IRIS | A | 192.168.50.150 | Borne WiFi Cisco |
| R1-IRIS | A | 192.168.50.254 | Routeur Cisco |

> Les enregistrements SRV pour Kerberos, LDAP et Global Catalog sont créés automatiquement par Active Directory lors de la promotion du DC.

---

### Zone inverse — 50.168.192.in-addr.arpa

| Paramètre | Valeur |
|-----------|--------|
| Nom | 50.168.192.in-addr.arpa |
| Réseau | 192.168.50.0/24 |
| Type | Principale intégrée AD |
| Mise à jour dynamique | Sécurisée uniquement |

#### Enregistrements PTR

| Enregistrement | Nom résolu |
|---------------|-----------|
| 10.50.168.192.in-addr.arpa | SRV-DC01.iris.local |
| 150.50.168.192.in-addr.arpa | AP-IRIS.iris.local |
| 253.50.168.192.in-addr.arpa | SW-IRIS.iris.local |
| 254.50.168.192.in-addr.arpa | R1-IRIS.iris.local |

---

## 3. Forwarders (résolution externe)

Quand le DNS interne ne connaît pas un nom (ex: google.com), il transmet la requête aux forwarders :

| Ordre | Forwarder | Fournisseur |
|-------|-----------|------------|
| 1 | 8.8.8.8 | Google Public DNS |
| 2 | 1.1.1.1 | Cloudflare DNS |

> Les clients du VLAN 40 (Guest) utilisent directement 8.8.8.8 sans passer par SRV-DC01.

---

## 4. Configuration DNS des clients

| VLAN | DNS configuré | Raison |
|------|--------------|--------|
| VLAN 10 Etudiants | 192.168.50.10 | Résolution iris.local + AD |
| VLAN 20 Professeurs | 192.168.50.10 | Résolution iris.local + AD |
| VLAN 30 Administration | 192.168.50.10 | Résolution iris.local + AD |
| VLAN 40 Guest | 8.8.8.8 | Pas d'accès AD — résolution internet directe |
| VLAN 50 Management | 192.168.50.10 | IPs fixes configurées manuellement |
| VLAN 99 PreAuth | 192.168.50.10 | Résolution pour authentification 802.1X |

---

## 5. Suffixes UPN

| Suffixe | Type | Usage |
|---------|------|-------|
| iris.local | Défaut (créé avec le domaine) | UPN interne |
| iris-nice.fr | Alternatif (ajouté manuellement) | UPN public/officiel |

Les comptes peuvent se connecter avec :
- `nbelloum@iris.local`
- `nbelloum@iris-nice.fr`

---

## 6. Commandes PowerShell de vérification

```powershell
# Lister toutes les zones DNS
Get-DnsServerZone

# Voir les enregistrements de la zone iris.local
Get-DnsServerResourceRecord -ZoneName "iris.local"

# Voir les forwarders
Get-DnsServerForwarder

# Tester la résolution DNS
Resolve-DnsName SRV-DC01.iris.local
Resolve-DnsName 192.168.50.10

# Vérifier les enregistrements SRV Active Directory
Resolve-DnsName _ldap._tcp.iris.local -Type SRV

# Ajouter un enregistrement A
Add-DnsServerResourceRecordA -ZoneName "iris.local" -Name "NouveauServeur" -IPv4Address "192.168.50.20"

# Ajouter un PTR
Add-DnsServerResourceRecordPtr -ZoneName "50.168.192.in-addr.arpa" -Name "20" -PtrDomainName "NouveauServeur.iris.local"

# Nettoyer le cache DNS
Clear-DnsServerCache
```

---

## 7. Test de validation DNS (effectué lors du projet)

```powershell
# Commandes exécutées depuis SRV-DC01 et SISR-01

# Résolution directe
nslookup SRV-DC01.iris.local 192.168.50.10
# Résultat attendu : 192.168.50.10 ✓

# Résolution inverse
nslookup 192.168.50.10 192.168.50.10
# Résultat attendu : SRV-DC01.iris.local ✓

# Résolution externe (forwarder)
nslookup google.com 192.168.50.10
# Résultat attendu : adresse IP Google ✓

# Test depuis client Windows 11
ipconfig /all
# DNS Servers : 192.168.50.10 ✓
ping SRV-DC01.iris.local
# Résolu et ping OK ✓
```
