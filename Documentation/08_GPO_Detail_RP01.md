# 08 — GPO — Détail complet RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Vue d'ensemble

| GPO | Cible | Etat |
|-----|-------|------|
| IRIS-PasswordPolicy | OU IRIS-Nice | AllSettingsEnabled |
| IRIS-LecteursReseau | OU IRIS-Nice | AllSettingsEnabled |
| IRIS-Securite-Baseline | OU IRIS-Nice | AllSettingsEnabled |
| IRIS-Restrictions-Etudiants | OU Etudiants | AllSettingsEnabled |
| IRIS-Profs-Acces | OU Professeurs | AllSettingsEnabled |

---

## 2. IRIS-PasswordPolicy

Cible : OU IRIS-Nice (tous les utilisateurs)

| Clé registre | Valeur | Description |
|-------------|--------|-------------|
| HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters\RequireSignOrSeal | 1 | Signature Netlogon requise |

Politique de mot de passe du domaine (configurée séparément) :

| Paramètre | Valeur |
|-----------|--------|
| MinPasswordLength | 8 |
| ComplexityEnabled | True |
| PasswordHistoryCount | 5 |
| MaxPasswordAge | 90 jours |
| MinPasswordAge | 1 jour |
| ReversibleEncryptionEnabled | False |

---

## 3. IRIS-Restrictions-Etudiants

Cible : OU Etudiants (SISR + SLAM uniquement)

| Clé HKCU | Valeur | Effet |
|----------|--------|-------|
| Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoControlPanel | 1 | Panneau de configuration désactivé |
| Software\Policies\Microsoft\Windows\System\DisableCMD | 1 | cmd.exe désactivé |
| Software\Microsoft\Windows\CurrentVersion\Policies\System\DisableRegistryTools | 1 | regedit.exe désactivé |
| Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDrives | 4 | Lecteur C: masqué dans l'explorateur |

---

## 4. IRIS-LecteursReseau

Cible : OU IRIS-Nice (tous)

Contenu : GPO Préférences — Mappages de lecteurs (Drives.xml dans SYSVOL)

Emplacement du fichier :
```
C:\Windows\SYSVOL\sysvol\iris.local\Policies\{GUID-GPO}\User\Preferences\Drives\Drives.xml
```

| Lecteur | Chemin | Ciblage | Filtre |
|---------|--------|---------|----|
| H: | \\SRV-DC01\HomeDir$\%USERNAME% | Tous | Aucun |
| S: | \\SRV-DC01\SISR | SID de GRP-Etudiants-SISR | FilterGroup AND |
| S: | \\SRV-DC01\SLAM | SID de GRP-Etudiants-SLAM | FilterGroup AND |
| S: | \\SRV-DC01\Professeurs | SID de GRP-Professeurs | FilterGroup AND |
| A: | \\SRV-DC01\Administration | SID de GRP-Administration | FilterGroup AND |
| P: | \\SRV-DC01\Commun | SISR OU SLAM OU Profs | FilterGroup OR |

Comportement : connexion différée (lazy connection) — les lecteurs s'affichent "Déconnectés" jusqu'au premier accès réel, puis passent en état "OK". Normal sous Windows 11.

---

## 5. IRIS-Securite-Baseline

Cible : OU IRIS-Nice (tous)

Paramètres HKCU (utilisateur) :

| Clé | Valeur | Effet |
|-----|--------|-------|
| Software\Policies\Microsoft\Windows\Control Panel\Desktop\ScreenSaveActive | "1" | Ecran de veille activé |
| Software\Policies\Microsoft\Windows\Control Panel\Desktop\ScreenSaverIsSecure | "1" | Mot de passe requis |
| Software\Policies\Microsoft\Windows\Control Panel\Desktop\ScreenSaveTimeOut | "600" | 10 minutes d'inactivité |

Paramètres HKLM (ordinateur) :

| Clé | Valeur | Effet |
|-----|--------|-------|
| SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDriveTypeAutoRun | 255 | Autorun désactivé sur tous supports |
| SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\EnableFirewall | 1 | Firewall Windows activé |
| SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeCaption | texte | Titre message légal à la connexion |
| SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\LegalNoticeText | texte | Corps du message légal |

---

## 6. IRIS-Profs-Acces

Cible : OU Professeurs

Appliquée après IRIS-Securite-Baseline et écrase certains paramètres.

| Clé HKCU | Valeur | Effet |
|----------|--------|-------|
| Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoControlPanel | 0 | Panneau de configuration accessible |

---

## 7. Audit — 7 catégories

Configuré via GUIDs (indépendants de la langue OS). Succes + Echecs pour chaque catégorie.

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

## 8. Héritage GPO

```
Domaine iris.local
    └── Default Domain Policy

OU IRIS-Nice
    ├── IRIS-PasswordPolicy
    ├── IRIS-LecteursReseau
    └── IRIS-Securite-Baseline

    OU Etudiants (hérite de IRIS-Nice + ajoute restrictions)
        └── IRIS-Restrictions-Etudiants
        OU SISR (hérite de Etudiants)
        OU SLAM (hérite de Etudiants)

    OU Professeurs (hérite de IRIS-Nice + lève certaines restrictions)
        └── IRIS-Profs-Acces
```

---

## 9. Vérification des GPO

```powershell
# Sur SRV-DC01 - Voir les liens GPO
Get-GPInheritance -Target "OU=IRIS-Nice,DC=iris,DC=local" |
    Select-Object -ExpandProperty GpoLinks | Format-Table DisplayName, Enabled, Order

# Sur le poste client - Voir les GPO appliquées
gpresult /r

# Rapport HTML détaillé
gpresult /h C:\rapport_gpo.html && Start-Process C:\rapport_gpo.html
```
