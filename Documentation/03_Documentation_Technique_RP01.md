# 03 — Documentation Technique RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Active Directory

### Domaine

| Paramètre | Valeur |
|-----------|--------|
| Nom DNS | iris.local |
| Nom NetBIOS | IRIS |
| Mode forêt / domaine | Windows Server 2016 |
| Contrôleur de domaine | SRV-DC01.iris.local |
| Adresse IP | 192.168.50.10 |
| Suffixe UPN alternatif | iris-nice.fr |
| Chemin NTDS | C:\Windows\NTDS |
| Chemin SYSVOL | C:\Windows\SYSVOL |

### Arborescence des OUs

```
iris.local
└── IRIS-Nice                    (OU racine - protection suppression activée)
    ├── Etudiants
    │   ├── SISR                 (10 comptes étudiants SISR)
    │   └── SLAM                 (5 comptes étudiants SLAM)
    ├── Professeurs              (2 comptes professeurs)
    ├── Administration           (3 comptes administratifs)
    ├── Informatique             (1 compte IT)
    ├── Groupes                  (9 groupes de sécurité)
    └── Ordinateurs-IRIS         (postes clients joints au domaine)
```

### Comptes utilisateurs — 21 comptes

Format login : 1ère lettre prénom + nom, minuscules, sans accents, sans espaces.

#### Professeurs — OU Professeurs

| Nom complet | Login | Groupes |
|------------|-------|---------|
| Yan Bourquard | ybourquard | GRP-Professeurs, GRP-WiFi-Profs |
| Terrence Ferrut | tferrut | GRP-Professeurs, GRP-WiFi-Profs |

#### Etudiants SISR — OU SISR

| Nom complet | Login | Groupes |
|------------|-------|---------|
| Said Ahmed Moussa | sahmedmoussa | GRP-Etudiants-SISR, GRP-WiFi-SISR |
| Vincent Andreo | vandreo | GRP-Etudiants-SISR, GRP-WiFi-SISR |
| Remi Bears | rbears | GRP-Etudiants-SISR, GRP-WiFi-SISR |
| Nedj Belloum | nbelloum | GRP-Etudiants-SISR, GRP-WiFi-SISR |
| Louka Lavenir | llavenir | GRP-Etudiants-SISR, GRP-WiFi-SISR |
| Julien Marcucci | jmarcucci | GRP-Etudiants-SISR, GRP-WiFi-SISR |
| Tiago Quenette | tquenette | GRP-Etudiants-SISR, GRP-WiFi-SISR |
| Edib Saoud | esaoud | GRP-Etudiants-SISR, GRP-WiFi-SISR |
| Omar Talibi | otalibi | GRP-Etudiants-SISR, GRP-WiFi-SISR |
| Hendrik Thouvenin | hthouvenin | GRP-Etudiants-SISR, GRP-WiFi-SISR |

#### Etudiants SLAM — OU SLAM

| Nom complet | Login | Groupes |
|------------|-------|---------|
| Yanis Adidi | yadidi | GRP-Etudiants-SLAM, GRP-WiFi-SISR |
| Mohamed Boukhatem | mboukhatem | GRP-Etudiants-SLAM, GRP-WiFi-SISR |
| Klaudia Juhasz | kjuhasz | GRP-Etudiants-SLAM, GRP-WiFi-SISR |
| Denys Lyulchak | dlyulchak | GRP-Etudiants-SLAM, GRP-WiFi-SISR |
| Kevin Senasson | ksenasson | GRP-Etudiants-SLAM, GRP-WiFi-SISR |

> Note : Les étudiants SLAM sont dans GRP-WiFi-SISR car ils partagent le VLAN 10 avec les SISR.

#### Administration — OU Administration

| Nom complet | Login | Groupes |
|------------|-------|---------|
| Marie Dupont | mdupont | GRP-Administration, GRP-WiFi-Admin |
| Jean Martin | jmartin | GRP-Administration, GRP-WiFi-Admin |
| Sophie Bernard | sbernard | GRP-Administration, GRP-WiFi-Admin |

#### Informatique — OU Informatique

| Nom complet | Login | Groupes |
|------------|-------|---------|
| Admin IRIS | airis | GRP-Informatique, GRP-VPN-Users |

### Groupes de sécurité — OU Groupes

| Groupe | Type | Rôle |
|--------|------|------|
| GRP-Etudiants-SISR | Global / Sécurité | Accès partage SISR, droits SMB |
| GRP-Etudiants-SLAM | Global / Sécurité | Accès partage SLAM, droits SMB |
| GRP-Professeurs | Global / Sécurité | Accès partage Professeurs, droits SMB |
| GRP-Administration | Global / Sécurité | Accès partage Administration, droits SMB |
| GRP-Informatique | Global / Sécurité | Equipe IT, accès complet |
| GRP-VPN-Users | Global / Sécurité | Accès VPN autorisé |
| GRP-WiFi-SISR | Global / Sécurité | Condition NPS → VLAN 10 (SISR + SLAM) |
| GRP-WiFi-Profs | Global / Sécurité | Condition NPS → VLAN 20 |
| GRP-WiFi-Admin | Global / Sécurité | Condition NPS → VLAN 30 |

---

## 2. DNS

### Zones

| Zone | Type | Usage |
|------|------|-------|
| iris.local | Primaire intégrée AD | Résolution interne |
| 50.168.192.in-addr.arpa | Primaire intégrée AD | Zone inverse VLAN 50 |
| _msdcs.iris.local | Primaire intégrée AD | Localisateur services AD (auto) |

### Enregistrements principaux

| Nom | Type | Valeur |
|-----|------|--------|
| SRV-DC01.iris.local | A | 192.168.50.10 |
| 10.50.168.192.in-addr.arpa | PTR | SRV-DC01.iris.local |

### Forwarders

| Forwarder | Usage |
|-----------|-------|
| 8.8.8.8 | Google DNS — résolution internet |
| 1.1.1.1 | Cloudflare DNS — résolution internet |

---

## 3. DHCP

### Scopes

| Nom | ScopeId | Plage | Passerelle | DNS | Domaine | Bail |
|-----|---------|-------|-----------|-----|---------|------|
| VLAN10-Etudiants | 192.168.10.0 | .10 – .250 | 192.168.10.254 | 192.168.50.10 | iris.local | 8 jours |
| VLAN20-Professeurs | 192.168.20.0 | .10 – .250 | 192.168.20.254 | 192.168.50.10 | iris.local | 8 jours |
| VLAN30-Administration | 192.168.30.0 | .10 – .250 | 192.168.30.254 | 192.168.50.10 | iris.local | 8 jours |
| VLAN40-Guest | 192.168.40.0 | .10 – .250 | 192.168.40.254 | 8.8.8.8 / 8.8.4.4 | — | 1 jour |
| VLAN99-PreAuth | 192.168.99.0 | .10 – .250 | 192.168.99.254 | 192.168.50.10 | iris.local | 1 jour |

Le VLAN 50 Management n'a pas de scope DHCP — les équipements ont des IPs fixes.

Le VLAN 40 Guest utilise le DNS public 8.8.8.8 pour interdire l'accès aux services internes iris.local.

---

## 4. Partages SMB

### Matrice des droits

| Partage | Chemin | GRP-SISR | GRP-SLAM | GRP-Profs | GRP-Admin | Administrateur |
|---------|--------|----------|----------|----------|---------|---------------|
| SISR | C:\Partages\Etudiants-SISR | Modify | — | — | — | FullControl |
| SLAM | C:\Partages\Etudiants-SLAM | — | Modify | — | — | FullControl |
| Professeurs | C:\Partages\Professeurs | — | — | Modify | — | FullControl |
| Administration | C:\Partages\Administration | — | — | — | Modify | FullControl |
| Commun | C:\Partages\Commun | Read | Read | Modify | — | FullControl |
| HomeDir$ | C:\HomeDir\%user% | Perso | Perso | Perso | Perso | FullControl |

### Mappage lecteurs — GPO Préférences (Drives.xml)

| Lecteur | Chemin UNC | Groupe ciblé | Ciblage SID |
|---------|-----------|-------------|------------|
| H: | \\SRV-DC01\HomeDir$\%USERNAME% | Tous | Non (pas de filtre) |
| S: | \\SRV-DC01\SISR | GRP-Etudiants-SISR | Oui |
| S: | \\SRV-DC01\SLAM | GRP-Etudiants-SLAM | Oui |
| S: | \\SRV-DC01\Professeurs | GRP-Professeurs | Oui |
| A: | \\SRV-DC01\Administration | GRP-Administration | Oui |
| P: | \\SRV-DC01\Commun | SISR OU SLAM OU Profs | Oui (FilterGroup OR) |

---

## 5. GPO — Stratégies de groupe

### Vue d'ensemble

| GPO | Liée à | Etat |
|-----|--------|------|
| IRIS-PasswordPolicy | OU IRIS-Nice | AllSettingsEnabled |
| IRIS-LecteursReseau | OU IRIS-Nice | AllSettingsEnabled |
| IRIS-Securite-Baseline | OU IRIS-Nice | AllSettingsEnabled |
| IRIS-Restrictions-Etudiants | OU Etudiants | AllSettingsEnabled |
| IRIS-Profs-Acces | OU Professeurs | AllSettingsEnabled |

### Politique de mot de passe domaine

| Paramètre | Valeur |
|-----------|--------|
| Longueur minimale | 8 caractères |
| Complexité | Activée |
| Historique | 5 anciens mots de passe |
| Durée maximale | 90 jours |
| Durée minimale | 1 jour |
| Chiffrement réversible | Désactivé |

### Audit — 7 catégories (succès + échecs)

| GUID | Catégorie |
|------|-----------|
| {0CCE9215-69AE-11D9-BED3-505054503030} | Ouverture/Fermeture de session |
| {0CCE9242-69AE-11D9-BED3-505054503030} | Authentification de compte |
| {0CCE9236-69AE-11D9-BED3-505054503030} | Gestion des comptes |
| {0CCE9227-69AE-11D9-BED3-505054503030} | Accès aux objets |
| {0CCE922F-69AE-11D9-BED3-505054503030} | Modification de politique |
| {0CCE9228-69AE-11D9-BED3-505054503030} | Utilisation des privilèges |
| {0CCE9213-69AE-11D9-BED3-505054503030} | Evénements système |

---

## 6. ADCS

| Paramètre | Valeur |
|-----------|--------|
| Nom | IRIS-Nice-CA |
| Type | Enterprise Root CA |
| CryptoProvider | RSA#Microsoft Software Key Storage Provider |
| KeyLength | 2048 bits |
| HashAlgorithm | SHA256 |
| Validité | 10 ans |
| Template actif | RASAndIASServer |

### Certificats délivrés

| Subject | Issuer | Usage | Expiration |
|---------|--------|-------|-----------|
| CN=IRIS-Nice-CA | CN=IRIS-Nice-CA | CA Racine | 2036 |
| CN=SRV-DC01.iris.local | CN=IRIS-Nice-CA | NPS RADIUS (RASAndIASServer) | 2027 |

---

## 7. NPS RADIUS

### Clients RADIUS

| Nom | Adresse IP | Fabricant | Usage |
|-----|-----------|----------|-------|
| SW-Cisco2960 | 192.168.50.253 | RADIUS Standard | 802.1X filaire |
| AP-C9105AXI | 192.168.50.150 | Cisco | WiFi WPA3-Enterprise |
| R1-Cisco1941W | 192.168.50.254 | Cisco | VPN |

### Politiques réseau

| Politique | Ordre | Condition | VLAN | Auth |
|-----------|-------|-----------|------|------|
| IRIS-WiFi-Etudiants | 1 | GRP-WiFi-SISR | 10 | PEAP + MS-CHAPv2 |
| IRIS-WiFi-Professeurs | 2 | GRP-WiFi-Profs | 20 | PEAP + MS-CHAPv2 |
| IRIS-WiFi-Administration | 3 | GRP-WiFi-Admin | 30 | PEAP + MS-CHAPv2 |

### Attributs RADIUS (RFC 3580)

| Attribut | Valeur | Description |
|---------|--------|-------------|
| Tunnel-Type | 13 | Virtual LANs (VLAN) |
| Tunnel-Medium-Type | 6 | IEEE 802 |
| Tunnel-Pvt-Group-ID | 10 / 20 / 30 | ID VLAN attribué |
