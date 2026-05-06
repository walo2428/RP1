# 14 — Comptes et Accès RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

> ⚠️ **Attention** — Ce fichier contient des informations sensibles. Ne pas versionner sur un dépôt public.  
> Mot de passe commun en environnement de LAB : `Azerty1!` — À changer impérativement en production.

---

## 1. Serveur SRV-DC01

| Accès | Valeur |
|-------|--------|
| Nom de la machine | SRV-DC01 |
| Adresse IP (Host-Only) | 192.168.50.10 |
| Adresse IP (NAT internet) | 10.0.2.15 |
| Administrateur local | Administrator |
| Mot de passe admin local | Azerty1! |
| Domaine | iris.local |
| Administrateur domaine | IRIS\Administrator |
| Mot de passe admin domaine | Azerty1! |

---

## 2. Comptes utilisateurs du domaine iris.local

### Professeurs — OU Professeurs

| Nom complet | Login | UPN | Groupes | Lecteurs |
|------------|-------|-----|---------|----------|
| Yan Bourquard | ybourquard | ybourquard@iris.local | GRP-Professeurs, GRP-WiFi-Profs | H:, S: (Profs), P: (Commun) |
| Terrence Ferrut | tferrut | tferrut@iris.local | GRP-Professeurs, GRP-WiFi-Profs | H:, S: (Profs), P: (Commun) |

### Etudiants SISR — OU SISR

| Nom complet | Login | UPN | Groupes | Lecteurs |
|------------|-------|-----|---------|----------|
| Nathan Belloum | nbelloum | nbelloum@iris.local | GRP-Etudiants-SISR, GRP-WiFi-SISR | H:, S: (SISR), P: (Commun) |
| Jethro Marcucci | jmarcucci | jmarcucci@iris.local | GRP-Etudiants-SISR, GRP-WiFi-SISR | H:, S: (SISR), P: (Commun) |
| Louka Lavenir | llavenir | llavenir@iris.local | GRP-Etudiants-SISR, GRP-WiFi-SISR | H:, S: (SISR), P: (Commun) |
| Vincent Andreo | vandreo | vandreo@iris.local | GRP-Etudiants-SISR, GRP-WiFi-SISR | H:, S: (SISR), P: (Commun) |
| Remi Bears | rbears | rbears@iris.local | GRP-Etudiants-SISR, GRP-WiFi-SISR | H:, S: (SISR), P: (Commun) |
| Tiago Quenette | tquenette | tquenette@iris.local | GRP-Etudiants-SISR, GRP-WiFi-SISR | H:, S: (SISR), P: (Commun) |
| Edib Saoud | esaoud | esaoud@iris.local | GRP-Etudiants-SISR, GRP-WiFi-SISR | H:, S: (SISR), P: (Commun) |
| Said Ahmed Moussa | sahmedmoussa | sahmedmoussa@iris.local | GRP-Etudiants-SISR, GRP-WiFi-SISR | H:, S: (SISR), P: (Commun) |
| Hendrik Thouvenin | hthouvenin | hthouvenin@iris.local | GRP-Etudiants-SISR, GRP-WiFi-SISR | H:, S: (SISR), P: (Commun) |
| Omar Talibi | otalibi | otalibi@iris.local | GRP-Etudiants-SISR, GRP-WiFi-SISR | H:, S: (SISR), P: (Commun) |

### Etudiants SLAM — OU SLAM

| Nom complet | Login | UPN | Groupes | Lecteurs |
|------------|-------|-----|---------|----------|
| Yanis Adidi | yadidi | yadidi@iris.local | GRP-Etudiants-SLAM, GRP-WiFi-SISR | H:, S: (SLAM), P: (Commun) |
| Kylian Senasson | ksenasson | ksenasson@iris.local | GRP-Etudiants-SLAM, GRP-WiFi-SISR | H:, S: (SLAM), P: (Commun) |
| Alexis Roux | aroux | aroux@iris.local | GRP-Etudiants-SLAM, GRP-WiFi-SISR | H:, S: (SLAM), P: (Commun) |
| Bryan Faure | bfaure | bfaure@iris.local | GRP-Etudiants-SLAM, GRP-WiFi-SISR | H:, S: (SLAM), P: (Commun) |
| Dylan Martin | dmartin | dmartin@iris.local | GRP-Etudiants-SLAM, GRP-WiFi-SISR | H:, S: (SLAM), P: (Commun) |

### Administration — OU Administration

| Nom complet | Login | UPN | Groupes | Lecteurs |
|------------|-------|-----|---------|----------|
| Marie Dupont | mdupont | mdupont@iris.local | GRP-Administration, GRP-WiFi-Admin | H:, A: (Administration) |
| Jean Martin | jmartin | jmartin@iris.local | GRP-Administration, GRP-WiFi-Admin | H:, A: (Administration) |
| Sophie Bernard | sbernard | sbernard@iris.local | GRP-Administration, GRP-WiFi-Admin | H:, A: (Administration) |

### Informatique — OU Informatique

| Nom complet | Login | UPN | Groupes | Lecteurs |
|------------|-------|-----|---------|----------|
| Omar Talibi | otalibi | otalibi@iris.local | GRP-Informatique, Domain Admins | H:, tous |

### Comptes de service — OU IRIS-Nice

| Nom complet | Login | UPN | Usage |
|------------|-------|-----|-------|
| Compte Service NPS | svc-nps | svc-nps@iris.local | Authentification NPS RADIUS |
| Compte Service Backup | svc-backup | svc-backup@iris.local | Sauvegardes planifiées |

---

## 3. Groupes de sécurité AD

| Groupe | Scope | Type | Membres | Rôle |
|--------|-------|------|---------|------|
| GRP-Etudiants-SISR | Global | Sécurité | 10 étudiants SISR | Accès partage SISR |
| GRP-Etudiants-SLAM | Global | Sécurité | 5 étudiants SLAM | Accès partage SLAM |
| GRP-Professeurs | Global | Sécurité | ybourquard, tferrut | Accès partage Professeurs |
| GRP-Administration | Global | Sécurité | mdupont, jmartin, sbernard | Accès partage Administration |
| GRP-Informatique | Global | Sécurité | otalibi | Accès total + admin |
| GRP-WiFi-SISR | Global | Sécurité | 15 étudiants SISR+SLAM | Auth RADIUS VLAN 10 |
| GRP-WiFi-Profs | Global | Sécurité | ybourquard, tferrut | Auth RADIUS VLAN 20 |
| GRP-WiFi-Admin | Global | Sécurité | mdupont, jmartin, sbernard | Auth RADIUS VLAN 30 |
| GRP-VPN-Users | Global | Sécurité | (vide) | Réservé VPN futur |

---

## 4. Partages SMB et droits d'accès

### Tableau des droits SMB + NTFS

| Partage | Chemin | Groupe SMB | Droit SMB | Droit NTFS |
|---------|--------|-----------|-----------|------------|
| SISR | C:\Partages\Etudiants-SISR | GRP-Etudiants-SISR | Change | Modify |
| SLAM | C:\Partages\Etudiants-SLAM | GRP-Etudiants-SLAM | Change | Modify |
| Professeurs | C:\Partages\Professeurs | GRP-Professeurs | Change | Modify |
| Administration | C:\Partages\Administration | GRP-Administration | Change | Modify |
| Commun | C:\Partages\Commun | GRP-Etudiants-SISR + GRP-Etudiants-SLAM | Read | Read |
| Commun | C:\Partages\Commun | GRP-Professeurs | Change | Modify |
| HomeDir$ | C:\HomeDir | Utilisateurs du domaine | Change | Modify (par sous-dossier) |

### Lecteurs réseau par profil

| Profil | H: | S: | P: | A: |
|--------|----|----|----|----|
| Etudiant SISR | \\SRV-DC01\HomeDir$\%username% | \\SRV-DC01\SISR | \\SRV-DC01\Commun | — |
| Etudiant SLAM | \\SRV-DC01\HomeDir$\%username% | \\SRV-DC01\SLAM | \\SRV-DC01\Commun | — |
| Professeur | \\SRV-DC01\HomeDir$\%username% | \\SRV-DC01\Professeurs | \\SRV-DC01\Commun | — |
| Administration | \\SRV-DC01\HomeDir$\%username% | — | — | \\SRV-DC01\Administration |

---

## 5. Accès équipements réseau Cisco

| Equipement | Adresse IP | Accès console | Enable | Login SSH |
|-----------|-----------|--------------|--------|-----------|
| SW-IRIS (Cisco 2960-S) | 192.168.50.253 | Console RS-232 | iris@cisco | iris / Azerty1! |
| R1-IRIS (Cisco 1941W) | 192.168.50.254 | Console RS-232 | iris@cisco | iris / Azerty1! |
| AP-IRIS (Cisco C9105AXI) | 192.168.50.150 | Console + HTTP | iris@cisco | iris / Azerty1! |

---

## 6. Accès console de la CA (ADCS)

| Paramètre | Valeur |
|-----------|--------|
| Nom de la CA | IRIS-Nice-CA |
| Type | Enterprise Root CA |
| Console MMC | certsrv.msc sur SRV-DC01 |
| Accès Web (CRL) | http://SRV-DC01.iris.local/CertEnroll |
| Durée validité CA | 10 ans (2026–2036) |
| Template activé | RASAndIASServer |

---

## 7. Accès NPS

| Paramètre | Valeur |
|-----------|--------|
| Console MMC | nps.msc sur SRV-DC01 |
| Secret RADIUS (SW) | iris@radius123 |
| Secret RADIUS (AP) | iris@radius123 |
| Secret RADIUS (R1) | iris@radius123 |
| Méthode auth | EAP-TLS (certificats ADCS) |
