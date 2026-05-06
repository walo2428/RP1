# 19 — Partages SMB et HomeDirs RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Vue d'ensemble

Tous les partages réseau sont hébergés sur **SRV-DC01** sous `C:\Partages\` et `C:\HomeDir\`.

| Paramètre | Valeur |
|-----------|--------|
| Serveur de fichiers | SRV-DC01 |
| Chemin racine partages communs | C:\Partages\ |
| Chemin racine homeDirs | C:\HomeDir\ |
| Nombre de partages | 6 |
| Nombre de HomeDirs | 21 (un par compte utilisateur) |

---

## 2. Partages communs

### Partage SISR

| Paramètre | Valeur |
|-----------|--------|
| Nom UNC | \\SRV-DC01\SISR |
| Chemin local | C:\Partages\Etudiants-SISR |
| Groupe autorisé SMB | GRP-Etudiants-SISR → Change |
| Droit NTFS | GRP-Etudiants-SISR → Modify |
| Lecteur réseau mappé | S: (via GPO Préférences) |
| Ciblage GPO | Membres de GRP-Etudiants-SISR |

### Partage SLAM

| Paramètre | Valeur |
|-----------|--------|
| Nom UNC | \\SRV-DC01\SLAM |
| Chemin local | C:\Partages\Etudiants-SLAM |
| Groupe autorisé SMB | GRP-Etudiants-SLAM → Change |
| Droit NTFS | GRP-Etudiants-SLAM → Modify |
| Lecteur réseau mappé | S: (via GPO Préférences) |
| Ciblage GPO | Membres de GRP-Etudiants-SLAM |

### Partage Professeurs

| Paramètre | Valeur |
|-----------|--------|
| Nom UNC | \\SRV-DC01\Professeurs |
| Chemin local | C:\Partages\Professeurs |
| Groupe autorisé SMB | GRP-Professeurs → Change |
| Droit NTFS | GRP-Professeurs → Modify |
| Lecteur réseau mappé | S: (via GPO Préférences) |
| Ciblage GPO | Membres de GRP-Professeurs |

### Partage Administration

| Paramètre | Valeur |
|-----------|--------|
| Nom UNC | \\SRV-DC01\Administration |
| Chemin local | C:\Partages\Administration |
| Groupe autorisé SMB | GRP-Administration → Change |
| Droit NTFS | GRP-Administration → Modify |
| Lecteur réseau mappé | A: (via GPO Préférences) |
| Ciblage GPO | Membres de GRP-Administration |

### Partage Commun

| Paramètre | Valeur |
|-----------|--------|
| Nom UNC | \\SRV-DC01\Commun |
| Chemin local | C:\Partages\Commun |
| Groupe SMB Etudiants | GRP-Etudiants-SISR + GRP-Etudiants-SLAM → Read |
| Groupe SMB Professeurs | GRP-Professeurs → Change |
| NTFS Etudiants | Read & Execute |
| NTFS Professeurs | Modify |
| Lecteur réseau mappé | P: (via GPO Préférences) |
| Ciblage GPO | Tous les membres de IRIS-Nice |
| ⚠️ Rôle | Espace partagé : profs déposent les cours, étudiants lisent |

### Partage HomeDir$ (masqué)

| Paramètre | Valeur |
|-----------|--------|
| Nom UNC | \\SRV-DC01\HomeDir$ |
| Chemin local | C:\HomeDir |
| $ (dollar) | Partage masqué — non visible dans l'explorateur réseau |
| Groupe SMB | Utilisateurs du domaine → Change |
| Droit NTFS racine | Administrateurs → Full Control |
| Droit NTFS sous-dossiers | %login% → Modify (sur son dossier uniquement) |
| Lecteur réseau mappé | H: (via GPO Préférences) |
| Chemin utilisateur | \\SRV-DC01\HomeDir$\%username% |
| Nombre de sous-dossiers | 21 (un par compte) |

---

## 3. Structure des dossiers HomeDirs

```
C:\HomeDir\
├── ybourquard\        (ACL: ybourquard → Modify)
├── tferrut\           (ACL: tferrut → Modify)
├── nbelloum\          (ACL: nbelloum → Modify)
├── jmarcucci\         (ACL: jmarcucci → Modify)
├── llavenir\           (ACL: llavenir → Modify)
├── vandreo\           (ACL: vandreo → Modify)
├── rbears\          (ACL: rbears → Modify)
├── tquenette\           (ACL: tquenette → Modify)
├── esaoud\            (ACL: esaoud → Modify)
├── sahmedmoussa\            (ACL: sahmedmoussa → Modify)
├── hthouvenin\          (ACL: hthouvenin → Modify)
├── otalibi\           (ACL: otalibi → Modify)
├── yadidi\            (ACL: yadidi → Modify)
├── ksenasson\         (ACL: ksenasson → Modify)
├── aroux\             (ACL: aroux → Modify)
├── bfaure\            (ACL: bfaure → Modify)
├── dmartin\           (ACL: dmartin → Modify)
├── mdupont\            (ACL: mdupont → Modify)
├── jmartin\          (ACL: jmartin → Modify)
├── sbernard\         (ACL: sbernard → Modify)
└── otalibi\           (ACL: otalibi → Modify)
```

---

## 4. Tableau des droits d'accès complet

| Partage | Groupe | Droit SMB | Droit NTFS | Lecteur |
|---------|--------|-----------|-----------|---------|
| SISR | GRP-Etudiants-SISR | Change | Modify | S: |
| SISR | Administrateurs | Full Control | Full Control | — |
| SLAM | GRP-Etudiants-SLAM | Change | Modify | S: |
| SLAM | Administrateurs | Full Control | Full Control | — |
| Professeurs | GRP-Professeurs | Change | Modify | S: |
| Professeurs | Administrateurs | Full Control | Full Control | — |
| Administration | GRP-Administration | Change | Modify | A: |
| Administration | Administrateurs | Full Control | Full Control | — |
| Commun | GRP-Etudiants-SISR | Read | Read & Execute | P: |
| Commun | GRP-Etudiants-SLAM | Read | Read & Execute | P: |
| Commun | GRP-Professeurs | Change | Modify | P: |
| Commun | Administrateurs | Full Control | Full Control | — |
| HomeDir$ | Utilisateurs du domaine | Change | (héritage désactivé) | H: |
| HomeDir$ | %login% (par sous-dossier) | — | Modify | H: |
| HomeDir$ | Administrateurs | Full Control | Full Control | — |

---

## 5. Drives.xml — GPO Préférences (mappages réseau)

Le fichier `gpo/Drives.xml` contient 6 mappages avec ciblage par SID de groupe :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Drives clsid="{8FDDCC1A-0C3C-43cd-A6B4-8A48251409B1}">
  <!-- H: HomeDir — tous les utilisateurs du domaine -->
  <Drive clsid="..." name="H:" status="H:" image="2" changed="..." uid="...">
    <Properties action="U" thisDrive="SHOW" allDrives="SHOW"
      userName="" path="\\SRV-DC01\HomeDir$\%logonuser%"
      label="Mon Dossier" persistent="1" useLetter="1" letter="H">
      <TargetRange FilterType="Domain Users"/>
    </Properties>
  </Drive>

  <!-- S: SISR — étudiants SISR -->
  <Drive clsid="..." name="S:" status="S:" image="2" ...>
    <Properties action="U" path="\\SRV-DC01\SISR" label="SISR" letter="S">
      <TargetRange FilterType="SecurityGroup" sid="SID-GRP-Etudiants-SISR"/>
    </Properties>
  </Drive>

  <!-- S: SLAM — étudiants SLAM -->
  <Drive clsid="..." name="S:" status="S:" image="2" ...>
    <Properties action="U" path="\\SRV-DC01\SLAM" label="SLAM" letter="S">
      <TargetRange FilterType="SecurityGroup" sid="SID-GRP-Etudiants-SLAM"/>
    </Properties>
  </Drive>

  <!-- S: Professeurs — profs -->
  <Drive clsid="..." name="S:" status="S:" image="2" ...>
    <Properties action="U" path="\\SRV-DC01\Professeurs" label="Professeurs" letter="S">
      <TargetRange FilterType="SecurityGroup" sid="SID-GRP-Professeurs"/>
    </Properties>
  </Drive>

  <!-- P: Commun — tous sauf administration -->
  <Drive clsid="..." name="P:" status="P:" image="2" ...>
    <Properties action="U" path="\\SRV-DC01\Commun" label="Commun" letter="P">
      <TargetRange FilterType="Domain Users"/>
    </Properties>
  </Drive>

  <!-- A: Administration -->
  <Drive clsid="..." name="A:" status="A:" image="2" ...>
    <Properties action="U" path="\\SRV-DC01\Administration" label="Administration" letter="A">
      <TargetRange FilterType="SecurityGroup" sid="SID-GRP-Administration"/>
    </Properties>
  </Drive>
</Drives>
```

> Le fichier Drives.xml réel avec les vrais SIDs est généré par le script `09_GPO_Lecteurs.ps1` et se trouve dans `gpo/Drives.xml`.

---

## 6. Comportement des lecteurs réseau

**Connexion différée (Lazy Connection) — Windows 11 :**
Les lecteurs apparaissent comme `Déconnectés` dans `net use` jusqu'au premier accès réel. Ce comportement est normal sous Windows 11 avec les GPO Préférences. Pour forcer la connexion : `dir H:` ou double-clic sur le lecteur dans l'Explorateur.

**Pourquoi GPO Préférences plutôt que logon scripts ?**
Les logon scripts s'exécutent avant que l'authentification Kerberos soit complète → lecteurs inaccessibles. Les GPO Préférences utilisent un mécanisme asynchrone qui attend la disponibilité des tickets Kerberos.

---

## 7. Commandes PowerShell de vérification

```powershell
# Lister tous les partages
Get-SmbShare

# Vérifier les droits SMB d'un partage
Get-SmbShareAccess -Name "SISR"

# Vérifier les ACL NTFS
Get-Acl "C:\Partages\Etudiants-SISR" | Format-List

# Vérifier les HomeDirs (count)
(Get-ChildItem "C:\HomeDir").Count

# Vérifier les droits NTFS d'un HomeDir
Get-Acl "C:\HomeDir\nbelloum" | Format-List

# Tester l'accès depuis un client (en session utilisateur)
net use
dir H:
dir S:
dir P:
```
