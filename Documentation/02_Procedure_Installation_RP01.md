# 02 — Procédure d'installation complète RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## Prérequis

### Logiciels

- VirtualBox 7.x ou supérieur
- ISO Windows Server 2022 Standard (licence nécessaire)
- ISO Windows 11 Pro (poste client)

### Configuration réseau VirtualBox

Avant de créer la VM serveur, configurer le réseau Host-Only dans VirtualBox :

1. Menu **Fichier → Gestionnaire de réseau hôte** (Ctrl+H)
2. Créer ou modifier le réseau Host-Only :
   - Adresse IPv4 : `192.168.50.1`
   - Masque : `255.255.255.0`
   - Serveur DHCP VirtualBox : **Désactivé obligatoirement**

### Configuration VM Windows Server 2022

| Paramètre | Valeur minimale |
|-----------|----------------|
| RAM | 4 Go |
| Disque | 60 Go |
| Processeurs | 2 vCPU |
| Carte réseau 1 | NAT |
| Carte réseau 2 | Réseau hôte uniquement (Host-Only 192.168.50.x) |

---

## Etape 1 — Installation Windows Server 2022

1. Démarrer la VM avec l'ISO Windows Server 2022
2. Choisir **Windows Server 2022 Standard (expérience de bureau)**
3. Partition : tout le disque
4. Définir le mot de passe Administrateur (stocker hors dépôt)
5. Attendre la fin de l'installation

---

## Etape 2 — Script 01 — IP fixe + Renommage

```powershell
Set-ExecutionPolicy Unrestricted -Force
.\scripts\01_Config_IP.ps1
```

Ce script détecte automatiquement la carte Host-Only, configure l'IP fixe `192.168.50.10/24` et redémarre.

**Vérification après redémarrage :**
```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127*"}
# Ethernet 2 : 192.168.50.10
# Ethernet   : 10.0.2.15 (NAT)
```

---

## Etape 3 — Script 02 — Active Directory

```powershell
.\scripts\02_Install_ADDS.ps1
```

Installe AD DS + DNS + GPMC, crée la forêt `iris.local`, redémarre.

**Vérification après redémarrage :**
```powershell
$env:USERDNSDOMAIN  # IRIS.LOCAL
$env:COMPUTERNAME   # SRV-DC01
```

---

## Etape 4 — Scripts 03 à 09 — Services et GPO

Lancer dans l'ordre sans redémarrage entre chaque :

```powershell
.\scripts\03_Post_Promo.ps1       # DNS forwarders + NTP + zone inverse + UPN
.\scripts\04_OU_Groupes.ps1       # 9 OUs + 9 groupes AD
.\scripts\05_Comptes.ps1          # 21 comptes utilisateurs
.\scripts\06_DHCP.ps1             # DHCP + 5 scopes
.\scripts\07_Partages_SMB.ps1     # Partages + ACL + 21 HomeDirs
.\scripts\08_GPO_Securite.ps1     # 5 GPO + audit + MDP
.\scripts\09_GPO_Lecteurs.ps1     # Drives.xml dans SYSVOL
```

---

## Etape 5 — Script 10 — ADCS + NPS

```powershell
.\scripts\10_ADCS_NPS.ps1
```

Installe ADCS et NPS, crée la CA `IRIS-Nice-CA`, ajoute les 3 clients RADIUS. Le script demande le secret RADIUS partagé à saisir interactivement.

**Redémarrer la VM manuellement après ce script.**

---

## Etape 6 — Configuration certtmpl.msc (manuelle)

Après le redémarrage :

1. Ouvrir `certtmpl.msc`
2. Chercher **RAS and IAS Server** dans la liste
3. Clic droit → **Propriétés** → onglet **Sécurité**
4. Cliquer **Ajouter** → **Types d'objets** → cocher **Ordinateurs** → OK
5. Saisir `SRV-DC01$` → **Vérifier les noms** → OK
6. Cocher **Inscrire** dans les autorisations → **Appliquer** → OK

---

## Etape 7 — Script 10b — Certificat NPS

```powershell
.\scripts\10b_NPS_PostReboot.ps1
```

Tente d'obtenir le certificat NPS automatiquement. Si non obtenu, procédure manuelle :

1. Ouvrir `mmc`
2. Fichier → **Ajouter/Supprimer un composant logiciel enfichable**
3. Ajouter **Certificats** → **Compte d'ordinateur** → Ordinateur local → OK
4. Dans la console : **Certificats (Ordinateur local)** → **Personnel**
5. Clic droit sur Personal → **Toutes les tâches** → **Demander un nouveau certificat**
6. Cliquer **Suivant** deux fois
7. Cocher **Serveur RAS et IAS** (ou RASAndIASServer)
8. Cliquer **Inscrire** → **Terminer**

---

## Etape 8 — Configuration nps.msc (manuelle)

Ouvrir **nps.msc** → **Stratégies réseau** → clic droit → **Nouveau**

### Politique 1 — IRIS-WiFi-Etudiants

| Paramètre | Valeur |
|-----------|--------|
| Nom | IRIS-WiFi-Etudiants |
| Ordre | 1 |
| Condition | Groupes Windows = IRIS\GRP-WiFi-SISR |
| Accès | Accorder l'accès |
| Méthode auth | PEAP → MS-CHAPv2 |
| Tunnel-Type | Virtual LANs (VLAN) |
| Tunnel-Medium-Type | 802 |
| Tunnel-Pvt-Group-ID | 10 |

### Politique 2 — IRIS-WiFi-Professeurs

| Paramètre | Valeur |
|-----------|--------|
| Nom | IRIS-WiFi-Professeurs |
| Ordre | 2 |
| Condition | Groupes Windows = IRIS\GRP-WiFi-Profs |
| Accès | Accorder l'accès |
| Tunnel-Pvt-Group-ID | 20 |

### Politique 3 — IRIS-WiFi-Administration

| Paramètre | Valeur |
|-----------|--------|
| Nom | IRIS-WiFi-Administration |
| Ordre | 3 |
| Condition | Groupes Windows = IRIS\GRP-WiFi-Admin |
| Accès | Accorder l'accès |
| Tunnel-Pvt-Group-ID | 30 |

Pour ajouter les attributs VLAN dans chaque politique :
- Onglet **Paramètres** → **Attributs RADIUS** → **Standard** → **Ajouter**
- Sélectionner `Tunnel-Type` → valeur **Virtual LANs (VLAN)**
- Sélectionner `Tunnel-Medium-Type` → valeur **802 (includes all 802 media...)**
- Sélectionner `Tunnel-Pvt-Group-ID` → saisir **10**, **20** ou **30**

---

## Etape 9 — Vérification serveur

```powershell
.\scripts\11_Verification_Serveur.ps1
# Résultat attendu : 0 erreur
```

---

## Etape 10 — Jonction poste client

Sur le **poste client Windows 11**, en PowerShell Admin :

```powershell
Set-ExecutionPolicy Unrestricted -Force
.\scripts\13_Client_JoinDomain.ps1
```

Après redémarrage, se connecter avec un compte du domaine :
```
IRIS\nbelloum
```

```powershell
# Tester le compte
.\scripts\12_Verification_Client.ps1
# Résultat attendu : TOUT EST OK POUR NBELLOUM !
```

---

## Récapitulatif des redémarrages

| Moment | Type |
|--------|------|
| Après script 01 | Automatique |
| Après script 02 | Automatique |
| Après script 10 | Manuel obligatoire |
| Après script 13 (poste client) | Automatique |
