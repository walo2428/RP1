# 15 — Structure Active Directory Complète RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Arborescence complète des OUs

```
iris.local
└── IRIS-Nice                          (OU racine du projet)
    │   Protection contre la suppression : Activée
    │   GPO liées : IRIS-PasswordPolicy, IRIS-Securite-Baseline, IRIS-LecteursReseau
    │
    ├── Etudiants                      (OU conteneur)
    │   ├── SISR                       (OU feuille — 10 comptes)
    │   │   GPO liée : IRIS-Restrictions-Etudiants
    │   │   → nbelloum, jmarcucci, llavenir, vandreo, rbears
    │   │   → tquenette, esaoud, sahmedmoussa, hthouvenin, otalibi
    │   │
    │   └── SLAM                       (OU feuille — 5 comptes)
    │       GPO liée : IRIS-Restrictions-Etudiants (héritage depuis Etudiants)
    │       → yadidi, ksenasson, aroux, bfaure, dmartin
    │
    ├── Professeurs                    (OU feuille — 2 comptes)
    │   GPO liée : IRIS-Profs-Acces
    │   → ybourquard, tferrut
    │
    ├── Administration                 (OU feuille — 3 comptes)
    │   GPO liée : (héritage IRIS-Nice)
    │   → mdupont, jmartin, sbernard
    │
    ├── Informatique                   (OU feuille — 1 compte)
    │   GPO liée : (héritage IRIS-Nice)
    │   → otalibi
    │
    ├── Comptes-Service                (OU feuille — 2 comptes service)
    │   GPO liée : (héritage IRIS-Nice)
    │   → svc-nps, svc-backup
    │
    ├── Groupes                        (OU feuille — 9 groupes)
    │   GPO liée : (héritage IRIS-Nice)
    │   → GRP-Etudiants-SISR, GRP-Etudiants-SLAM
    │   → GRP-Professeurs, GRP-Administration
    │   → GRP-Informatique
    │   → GRP-WiFi-SISR, GRP-WiFi-Profs, GRP-WiFi-Admin
    │   → GRP-VPN-Users
    │
    └── Ordinateurs-IRIS               (OU feuille — postes clients)
        GPO liée : (héritage IRIS-Nice)
        → SISR-01 (Windows 11 joint au domaine)
```

---

## 2. Détail de chaque OU

### OU IRIS-Nice (racine)

| Paramètre | Valeur |
|-----------|--------|
| Distinguished Name | OU=IRIS-Nice,DC=iris,DC=local |
| Protection suppression | Oui |
| GPO liées | IRIS-PasswordPolicy, IRIS-Securite-Baseline, IRIS-LecteursReseau |
| Héritage | Activé vers toutes les sous-OUs |
| Créée par | Script 04_OU_Groupes.ps1 |

### OU Etudiants

| Paramètre | Valeur |
|-----------|--------|
| Distinguished Name | OU=Etudiants,OU=IRIS-Nice,DC=iris,DC=local |
| Protection suppression | Oui |
| GPO liées | IRIS-Restrictions-Etudiants (héritée par SISR et SLAM) |
| Rôle | Conteneur parent SISR et SLAM |

### OU SISR

| Paramètre | Valeur |
|-----------|--------|
| Distinguished Name | OU=SISR,OU=Etudiants,OU=IRIS-Nice,DC=iris,DC=local |
| Protection suppression | Oui |
| Nombre de comptes | 10 |
| Groupes appliqués | GRP-Etudiants-SISR, GRP-WiFi-SISR |
| HomeDir | C:\HomeDir\%login% |
| UPN | %login%@iris.local |

### OU SLAM

| Paramètre | Valeur |
|-----------|--------|
| Distinguished Name | OU=SLAM,OU=Etudiants,OU=IRIS-Nice,DC=iris,DC=local |
| Protection suppression | Oui |
| Nombre de comptes | 5 |
| Groupes appliqués | GRP-Etudiants-SLAM, GRP-WiFi-SISR |
| HomeDir | C:\HomeDir\%login% |
| UPN | %login%@iris.local |

### OU Professeurs

| Paramètre | Valeur |
|-----------|--------|
| Distinguished Name | OU=Professeurs,OU=IRIS-Nice,DC=iris,DC=local |
| Protection suppression | Oui |
| Nombre de comptes | 2 |
| GPO liée | IRIS-Profs-Acces |
| Groupes appliqués | GRP-Professeurs, GRP-WiFi-Profs |

### OU Administration

| Paramètre | Valeur |
|-----------|--------|
| Distinguished Name | OU=Administration,OU=IRIS-Nice,DC=iris,DC=local |
| Protection suppression | Oui |
| Nombre de comptes | 3 |
| Groupes appliqués | GRP-Administration, GRP-WiFi-Admin |

### OU Informatique

| Paramètre | Valeur |
|-----------|--------|
| Distinguished Name | OU=Informatique,OU=IRIS-Nice,DC=iris,DC=local |
| Protection suppression | Oui |
| Nombre de comptes | 1 (otalibi) |
| Groupes appliqués | GRP-Informatique + Domain Admins |

### OU Comptes-Service

| Paramètre | Valeur |
|-----------|--------|
| Distinguished Name | OU=Comptes-Service,OU=IRIS-Nice,DC=iris,DC=local |
| Protection suppression | Oui |
| Nombre de comptes | 2 (svc-nps, svc-backup) |
| Particularité | Mots de passe sans expiration |

### OU Groupes

| Paramètre | Valeur |
|-----------|--------|
| Distinguished Name | OU=Groupes,OU=IRIS-Nice,DC=iris,DC=local |
| Protection suppression | Oui |
| Nombre de groupes | 9 |

### OU Ordinateurs-IRIS

| Paramètre | Valeur |
|-----------|--------|
| Distinguished Name | OU=Ordinateurs-IRIS,OU=IRIS-Nice,DC=iris,DC=local |
| Protection suppression | Oui |
| Postes | SISR-01 |
| Rôle | Reçoit les GPO ordinateur par héritage IRIS-Nice |

---

## 3. Récapitulatif des 21 comptes

| Login | Prénom | Nom | OU | Groupes principaux | HomeDir |
|-------|--------|-----|----|--------------------|---------|
| ybourquard | Yan | Bourquard | Professeurs | GRP-Professeurs, GRP-WiFi-Profs | C:\HomeDir\ybourquard |
| tferrut | Terrence | Ferrut | Professeurs | GRP-Professeurs, GRP-WiFi-Profs | C:\HomeDir\tferrut |
| nbelloum | Nathan | Belloum | SISR | GRP-Etudiants-SISR, GRP-WiFi-SISR | C:\HomeDir\nbelloum |
| jmarcucci | Jethro | Marcucci | SISR | GRP-Etudiants-SISR, GRP-WiFi-SISR | C:\HomeDir\jmarcucci |
| llavenir | Liam | Nguyen | SISR | GRP-Etudiants-SISR, GRP-WiFi-SISR | C:\HomeDir\llavenir |
| vandreo | Mathis | Durand | SISR | GRP-Etudiants-SISR, GRP-WiFi-SISR | C:\HomeDir\vandreo |
| rbears | Théo | Bernard | SISR | GRP-Etudiants-SISR, GRP-WiFi-SISR | C:\HomeDir\rbears |
| tquenette | Axel | Moreau | SISR | GRP-Etudiants-SISR, GRP-WiFi-SISR | C:\HomeDir\tquenette |
| esaoud | Lucas | Petit | SISR | GRP-Etudiants-SISR, GRP-WiFi-SISR | C:\HomeDir\esaoud |
| sahmedmoussa | Hugo | Simon | SISR | GRP-Etudiants-SISR, GRP-WiFi-SISR | C:\HomeDir\sahmedmoussa |
| hthouvenin | Tom | Laurent | SISR | GRP-Etudiants-SISR, GRP-WiFi-SISR | C:\HomeDir\hthouvenin |
| otalibi | Enzo | Garcia | SISR | GRP-Etudiants-SISR, GRP-WiFi-SISR | C:\HomeDir\otalibi |
| yadidi | Yanis | Adidi | SLAM | GRP-Etudiants-SLAM, GRP-WiFi-SISR | C:\HomeDir\yadidi |
| ksenasson | Kylian | Senasson | SLAM | GRP-Etudiants-SLAM, GRP-WiFi-SISR | C:\HomeDir\ksenasson |
| aroux | Alexis | Roux | SLAM | GRP-Etudiants-SLAM, GRP-WiFi-SISR | C:\HomeDir\aroux |
| bfaure | Bryan | Faure | SLAM | GRP-Etudiants-SLAM, GRP-WiFi-SISR | C:\HomeDir\bfaure |
| dmartin | Dylan | Martin | SLAM | GRP-Etudiants-SLAM, GRP-WiFi-SISR | C:\HomeDir\dmartin |
| mdupont | Sophie | Blanc | Administration | GRP-Administration, GRP-WiFi-Admin | C:\HomeDir\mdupont |
| jmartin | Marie | Lemaire | Administration | GRP-Administration, GRP-WiFi-Admin | C:\HomeDir\jmartin |
| sbernard | Julie | Rousseau | Administration | GRP-Administration, GRP-WiFi-Admin | C:\HomeDir\sbernard |
| otalibi | Omar | Talibi | Informatique | GRP-Informatique, Domain Admins | C:\HomeDir\otalibi |

**Total : 21 comptes** — 2 profs, 10 SISR, 5 SLAM, 3 admin, 1 IT

---

## 4. Politique de mot de passe du domaine

| Paramètre | Valeur |
|-----------|--------|
| Longueur minimale | 8 caractères |
| Complexité | Activée (maj, min, chiffre, symbole) |
| Historique | 5 anciens mots de passe |
| Durée maximale | 90 jours |
| Durée minimale | 1 jour |
| Verrouillage | 5 tentatives → 30 min de verrouillage |
| GPO appliquant la politique | IRIS-PasswordPolicy → OU IRIS-Nice |

---

## 5. Commandes ADUC utiles

```powershell
# Lister tous les utilisateurs du domaine
Get-ADUser -Filter * -SearchBase "OU=IRIS-Nice,DC=iris,DC=local" -Properties *

# Voir les membres d'un groupe
Get-ADGroupMember -Identity "GRP-Etudiants-SISR"

# Ajouter un utilisateur à un groupe
Add-ADGroupMember -Identity "GRP-Etudiants-SISR" -Members "nouveaulogin"

# Débloquer un compte verrouillé
Unlock-ADAccount -Identity "nbelloum"

# Réinitialiser un mot de passe
Set-ADAccountPassword -Identity "nbelloum" -NewPassword (ConvertTo-SecureString "NouveauMdp1!" -AsPlainText -Force) -Reset

# Voir les OUs
Get-ADOrganizationalUnit -Filter * -SearchBase "DC=iris,DC=local" | Select-Object Name, DistinguishedName
```
