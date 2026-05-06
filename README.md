# RP-01 — Infrastructure Active Directory IRIS Nice — Windows Server 2022

> BTS SIO option SISR — Session 2026  
> **Talibi Omar** — Mediaschool IRIS Nice  
> Période : 09/03/2026 au 20/03/2026  
> Résultat : **0 erreur validée ✅**

---

## Contexte

Dans le cadre du BTS SIO SISR, déploiement d'une infrastructure Active Directory complète pour le campus IRIS Nice sur infrastructure Cisco existante (routeur 1941W, switch 2960-S, borne WiFi C9105AXI). L'école ne disposait d'aucune gestion centralisée des utilisateurs, d'aucune authentification individuelle et d'aucun partage de fichiers sécurisé.

**Besoins couverts :**
- Gestion centralisée des utilisateurs et groupes via Active Directory
- Attribution dynamique des adresses IP par VLAN via DHCP centralisé sur Windows Server
- Partages de fichiers SMB/NTFS avec matrice de droits par groupe et répertoires personnels
- Lecteurs réseau H: S: P: A: mappés automatiquement via GPO Préférences
- Authentification WiFi 802.1X via NPS RADIUS avec attribution dynamique du VLAN
- Politiques de sécurité via GPO (restrictions étudiants, écran de veille, firewall, audit)
- Autorité de certification interne ADCS pour le service NPS

---

## Architecture

### Composants

| Composant | Technologie | IP |
|-----------|-------------|-----|
| **SRV-DC01** | Windows Server 2022 Standard — AD DS, DNS, DHCP, NPS, ADCS | 192.168.50.10 |
| **SW-IRIS** | Cisco Catalyst 2960-S — 802.1Q trunk, 802.1X ports | 192.168.50.253 |
| **R1-IRIS** | Cisco 1941W — Router-on-stick, NAT, DHCP relay | 192.168.50.254 |
| **AP-IRIS** | Cisco C9105AXI — WiFi 6, WPA3-Enterprise, 802.1X | 192.168.50.150 |
| **SISR-01** | Windows 11 Pro — Poste client joint au domaine | 192.168.50.x |

### Segmentation réseau — 6 VLANs

| VLAN | Nom | Réseau | Passerelle | DNS | Usage |
|------|-----|--------|-----------|-----|-------|
| 10 | IRIS-Etudiants | 192.168.10.0/24 | 192.168.10.1 | 192.168.50.10 | SISR + SLAM + WiFi |
| 20 | Professeurs | 192.168.20.0/24 | 192.168.20.1 | 192.168.50.10 | Enseignants + WiFi |
| 30 | Administration | 192.168.30.0/24 | 192.168.30.1 | 192.168.50.10 | Personnel administratif |
| 40 | Guest | 192.168.40.0/24 | 192.168.40.1 | 8.8.8.8 | Invités WiFi — Internet uniquement |
| **50** | **Management** | **192.168.50.0/24** | **192.168.50.254** | **127.0.0.1** | **Serveurs + équipements réseau** |
| **99** | **PRE-AUTH** | **192.168.99.0/24** | **192.168.99.1** | **192.168.50.10** | **VLAN transit avant 802.1X** |

### Flux d'authentification 802.1X

```
Client WiFi/filaire
  --> VLAN 99 par défaut (PRE-AUTH)
  --> Requête EAP vers Switch/Borne
  --> Requête RADIUS vers SRV-DC01:1812 (NPS)
  --> NPS vérifie credentials dans Active Directory
  --> NPS retourne VLAN via Tunnel-Pvt-Group-ID (RFC 3580)
  --> Switch/Borne place le client dans VLAN 10, 20 ou 30
  --> Client obtient IP DHCP via ip helper-address 192.168.50.10
```

---

## Active Directory

| Paramètre | Valeur |
|-----------|--------|
| Domaine DNS | iris.local |
| Nom NetBIOS | IRIS |
| Mode domaine | Windows Server 2016 |
| Contrôleur | SRV-DC01.iris.local — 192.168.50.10 |
| UPN alternatif | iris-nice.fr |
| Comptes | 21 utilisateurs (2 profs, 10 SISR, 5 SLAM, 3 admin, 1 IT) |
| Groupes | 9 groupes de sécurité |
| OUs | 9 OUs sous IRIS-Nice |
| GPO | 5 GPO déployées |

### Arborescence OUs

```
iris.local
└── IRIS-Nice
    ├── Etudiants
    │   ├── SISR        (10 comptes — GPO Restrictions)
    │   └── SLAM        (5 comptes — GPO Restrictions)
    ├── Professeurs     (2 comptes — GPO Profs-Acces)
    ├── Administration  (3 comptes)
    ├── Informatique    (1 compte)
    ├── Comptes-Service (2 comptes service)
    ├── Groupes         (9 groupes)
    └── Ordinateurs-IRIS (SISR-01)
```

---

## GPO déployées

| GPO | OU liée | Effet |
|-----|---------|-------|
| IRIS-PasswordPolicy | IRIS-Nice | Complexité 8 car., historique 5, 90j, verrouillage 5 tentatives |
| IRIS-Securite-Baseline | IRIS-Nice | Écran de veille 10min, autorun off, firewall, message légal |
| IRIS-Restrictions-Etudiants | Etudiants | Panneau config, CMD, regedit, lecteur C: bloqués |
| IRIS-LecteursReseau | IRIS-Nice | Mappages H: S: P: A: via GPO Préférences + Drives.xml |
| IRIS-Profs-Acces | Professeurs | Panneau config accessible, CMD disponible |

---

## Partages SMB

| Partage | Chemin | Accès | Lecteur |
|---------|--------|-------|---------|
| SISR | C:\Partages\Etudiants-SISR | GRP-Etudiants-SISR → Modify | S: |
| SLAM | C:\Partages\Etudiants-SLAM | GRP-Etudiants-SLAM → Modify | S: |
| Professeurs | C:\Partages\Professeurs | GRP-Professeurs → Modify | S: |
| Administration | C:\Partages\Administration | GRP-Administration → Modify | A: |
| Commun | C:\Partages\Commun | Etudiants Read / Profs Modify | P: |
| HomeDir$ | C:\HomeDir | Personnel → Modify (par sous-dossier) | H: |

---

## Scripts PowerShell — Ordre d'exécution

| # | Script | Rôle | Reboot |
|---|--------|------|--------|
| 01 | `01_Config_IP.ps1` | IP fixe 192.168.50.10 + renommage SRV-DC01 | Oui |
| 02 | `02_Install_ADDS.ps1` | Installation AD DS + promotion DC iris.local | Oui |
| 03 | `03_Post_Promo.ps1` | DNS forwarders + NTP + zone inverse + UPN | Non |
| 04 | `04_OU_Groupes.ps1` | Création 9 OUs + 9 groupes de sécurité | Non |
| 05 | `05_Comptes.ps1` | Création 21 comptes utilisateurs | Non |
| 06 | `06_DHCP.ps1` | DHCP + 5 scopes VLANs 10/20/30/40/99 | Non |
| 07 | `07_Partages_SMB.ps1` | Partages SMB + ACL NTFS + 21 HomeDirs | Non |
| 08 | `08_GPO_Securite.ps1` | 5 GPO + audit 7 catégories + politique MDP | Non |
| 09 | `09_GPO_Lecteurs.ps1` | GPO Préférences + Drives.xml (H: S: P: A:) | Non |
| 10 | `10_ADCS_NPS.ps1` | CA IRIS-Nice-CA + NPS + 3 clients RADIUS | Oui |
| 10b | `10b_NPS_PostReboot.ps1` | Certificat NPS après redémarrage | Non |
| 11 | `11_Verification_Serveur.ps1` | Vérification complète SRV-DC01 | Non |
| 12 | `12_Verification_Client.ps1` | Test complet poste client | Non |
| 13 | `13_Client_JoinDomain.ps1` | Jonction SISR-01 au domaine iris.local | Oui |

### Démarrage rapide

```powershell
# Exécuter sur SRV-DC01 en PowerShell Administrateur
Set-ExecutionPolicy Unrestricted -Force

.\scripts\01_Config_IP.ps1
.\scripts\02_Install_ADDS.ps1
.\scripts\03_Post_Promo.ps1
.\scripts\04_OU_Groupes.ps1
.\scripts\05_Comptes.ps1
.\scripts\06_DHCP.ps1
.\scripts\07_Partages_SMB.ps1
.\scripts\08_GPO_Securite.ps1
.\scripts\09_GPO_Lecteurs.ps1
.\scripts\10_ADCS_NPS.ps1         # redémarrer ensuite
.\scripts\10b_NPS_PostReboot.ps1  # puis certtmpl.msc + nps.msc manuellement
.\scripts\11_Verification_Serveur.ps1  # résultat attendu : 0 erreur
```

---

## Résultats de déploiement

`11_Verification_Serveur.ps1` — **0 erreur détectée ✅**

`12_Verification_Client.ps1` — **0 erreur sur tous les comptes testés ✅**

| Compte | Type | H: | S: | P: | GPO | Résultat |
|--------|------|----|-----|-----|-----|---------|
| nbelloum | Etudiant SISR | OK | SISR | OK | Restrictions OK | ✅ |
| jmarcucci | Etudiant SISR | OK | SISR | OK | Restrictions OK | ✅ |
| yadidi | Etudiant SLAM | OK | SLAM | OK | Restrictions OK | ✅ |
| ksenasson | Etudiant SLAM | OK | SLAM | OK | Restrictions OK | ✅ |
| ybourquard | Professeur | OK | Profs | OK | Panneau OK | ✅ |

---

## Structure du projet

```
.
├── README.md
├── .gitignore
├── schema/
│   └── schema-reseau-RP1.png               <- à placer manuellement
├── scripts/                                 <- 14 scripts PowerShell
│   ├── 01_Config_IP.ps1
│   ├── 02_Install_ADDS.ps1
│   ├── 03_Post_Promo.ps1
│   ├── 04_OU_Groupes.ps1
│   ├── 05_Comptes.ps1
│   ├── 06_DHCP.ps1
│   ├── 07_Partages_SMB.ps1
│   ├── 08_GPO_Securite.ps1
│   ├── 09_GPO_Lecteurs.ps1
│   ├── 10_ADCS_NPS.ps1
│   ├── 10b_NPS_PostReboot.ps1
│   ├── 11_Verification_Serveur.ps1
│   ├── 12_Verification_Client.ps1
│   └── 13_Client_JoinDomain.ps1
├── cisco/                                   <- 3 configurations Cisco
│   ├── R1-Cisco1941W_config.txt
│   ├── SW-Cisco2960S_config.txt
│   └── AP-Cisco-C9105AXI_config.txt
├── gpo/
│   └── Drives.xml                           <- GPO Préférences lecteurs réseau
├── verification/
│   ├── resultats_serveur.txt
│   └── resultats_clients.txt
└── Documentation/                           <- 24 fichiers de documentation
    ├── 01_Plan_Tests_RP01.md
    ├── 02_Procedure_Installation_RP01.md
    ├── 03_Documentation_Technique_RP01.md
    ├── 04_Problemes_Solutions_RP01.md
    ├── 05_NPS_RADIUS_RP01.md
    ├── 06_Procedure_Utilisation_RP01.md
    ├── 07_Architecture_Schema_RP01.md
    ├── 08_GPO_Detail_RP01.md
    ├── 09_ADCS_Certificats_RP01.md
    ├── 10_Cisco_Config_RP01.md
    ├── 11_PosteClient_SISR01_RP01.md
    ├── 12_Matrice_Securite_RP01.md
    ├── 13_Maintenance_Sauvegarde_RP01.md
    ├── 14_Comptes_Acces_RP01.md
    ├── 15_AD_OUs_Complet_RP01.md
    ├── 16_DHCP_Complet_RP01.md
    ├── 17_DNS_Complet_RP01.md
    ├── 18_Adressage_VLAN_RP01.md
    ├── 19_SMB_HomeDirs_RP01.md
    ├── 20_VirtualBox_LAB_RP01.md
    ├── 21_Administration_Courante_RP01.md
    ├── 22_Glossaire_RP01.md
    ├── 23_Audit_Securite_RP01.md
    └── 24_Tableau_Bord_RP01.md
```

---

## Auteur

**Talibi Omar** — BTS SIO option SISR — Session 2026  
Mediaschool IRIS Nice
