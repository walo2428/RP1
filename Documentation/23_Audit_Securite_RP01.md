# 23 — Politique d'Audit et Sécurité RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Vue d'ensemble de la politique de sécurité

La politique de sécurité du domaine iris.local repose sur 5 GPO :

| GPO | Portée | Priorité |
|-----|--------|---------|
| IRIS-PasswordPolicy | OU IRIS-Nice (tous) | Haute |
| IRIS-Securite-Baseline | OU IRIS-Nice (tous) | Haute |
| IRIS-Restrictions-Etudiants | OU Etudiants (SISR + SLAM) | Normale |
| IRIS-Profs-Acces | OU Professeurs | Normale |
| IRIS-LecteursReseau | OU IRIS-Nice (tous) | Normale |

---

## 2. GPO IRIS-PasswordPolicy

### Paramètres appliqués

| Paramètre | Valeur | Chemin GPO |
|-----------|--------|-----------|
| Longueur minimale du mot de passe | 8 caractères | Config ordinateur → Paramètres Windows → Paramètres de sécurité → Stratégies de compte |
| Complexité obligatoire | Activée | Idem |
| Historique des mots de passe | 5 | Idem |
| Durée maximale | 90 jours | Idem |
| Durée minimale | 1 jour | Idem |
| Seuil de verrouillage | 5 tentatives | Config ordinateur → ... → Stratégie de verrouillage |
| Durée de verrouillage | 30 minutes | Idem |
| Réinitialisation compteur verrouillage | 30 minutes | Idem |

### Script PowerShell utilisé

```powershell
Set-ADDefaultDomainPasswordPolicy -Identity iris.local `
    -MinPasswordLength 8 `
    -PasswordHistoryCount 5 `
    -MaxPasswordAge (New-TimeSpan -Days 90) `
    -MinPasswordAge (New-TimeSpan -Days 1) `
    -ComplexityEnabled $true `
    -LockoutThreshold 5 `
    -LockoutDuration (New-TimeSpan -Minutes 30) `
    -LockoutObservationWindow (New-TimeSpan -Minutes 30)
```

---

## 3. GPO IRIS-Securite-Baseline

### Paramètres appliqués (tous les utilisateurs du domaine)

| Paramètre | Valeur | Description |
|-----------|--------|-------------|
| Écran de veille | Activé | Après 10 minutes d'inactivité |
| Écran de veille sécurisé | Activé | Mot de passe requis au réveil |
| Délai écran de veille | 600 secondes | 10 minutes |
| Exécution automatique (AutoRun) | Désactivée | Protection contre les clés USB malveillantes |
| Windows Firewall | Activé tous profils | Domain, Private, Public |
| Message de connexion (titre) | IRIS Nice — Système Informatique Privé | Avertissement légal |
| Message de connexion (texte) | Accès réservé aux personnes autorisées... | Avertissement légal |

### Clés de registre configurées

```
HKCU\Control Panel\Desktop\ScreenSaveActive = 1
HKCU\Control Panel\Desktop\ScreenSaverIsSecure = 1
HKCU\Control Panel\Desktop\ScreenSaveTimeOut = 600
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDriveTypeAutoRun = 255
```

---

## 4. GPO IRIS-Restrictions-Etudiants

### Restrictions appliquées (étudiants SISR + SLAM uniquement)

| Restriction | Clé registre | Valeur | Effet |
|------------|-------------|--------|-------|
| Panneau de configuration désactivé | HKCU\...\NoControlPanel | 1 | Le panneau de config est inaccessible |
| Invite de commandes désactivée | HKCU\...\DisableCMD | 1 | cmd.exe bloquée |
| Editeur de registre désactivé | HKCU\...\DisableRegistryTools | 1 | regedit.exe bloqué |
| Lecteur C: masqué | HKCU\...\NoDrives | 4 | C: n'apparaît pas dans l'Explorateur |

### Chemins registre complets

```
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoControlPanel
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System\DisableCMD
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System\DisableRegistryTools
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDrives
```

---

## 5. GPO IRIS-Profs-Acces

### Paramètres appliqués (professeurs uniquement)

| Paramètre | Valeur | Effet |
|-----------|--------|-------|
| Panneau de configuration | Accessible | Les profs peuvent accéder au panneau de config |
| Invite de commandes | Accessible | cmd.exe disponible |
| Lecteur C: | Visible | C: apparaît dans l'Explorateur |

> Cette GPO est liée sur OU Professeurs avec priorité plus haute que les restrictions étudiants. Les profs héritent de IRIS-Securite-Baseline mais pas de IRIS-Restrictions-Etudiants.

---

## 6. Politique d'audit — 7 catégories

L'audit est configuré via `auditpol` avec les GUIDs des catégories (nécessaire en Windows en français).

| Catégorie | GUID | Sous-catégories auditées | Événements surveillés |
|-----------|------|------------------------|----------------------|
| Ouverture de session | {69979848-...} | Ouverture/fermeture de session | 4624, 4625, 4634 |
| Accès aux objets | {6997984A-...} | Système de fichiers, partages | 4656, 4663, 5140 |
| Gestion des comptes | {6997984C-...} | Utilisateurs, groupes | 4720, 4722, 4732 |
| Utilisation des privilèges | {6997984D-...} | Utilisation droits sensitifs | 4672, 4673 |
| Suivi des processus | {6997984E-...} | Création de processus | 4688 |
| Modifications de politique | {6997984F-...} | Changements GPO, audit | 4719, 4907 |
| Connexion au compte | {69979850-...} | Validation Kerberos | 4768, 4769, 4771 |

### Commandes auditpol utilisées

```powershell
# Audit des connexions
auditpol /set /subcategory:"{0CCE9215-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
# Audit des accès aux objets
auditpol /set /subcategory:"{0CCE921D-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
# Audit de la gestion des comptes
auditpol /set /subcategory:"{0CCE9229-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
```

---

## 7. Événements Windows à surveiller

| Event ID | Canal | Description | Gravité |
|---------|-------|-------------|---------|
| 4624 | Security | Connexion réussie | Info |
| 4625 | Security | Échec de connexion | ⚠️ Avertissement |
| 4634 | Security | Déconnexion | Info |
| 4648 | Security | Connexion avec credentials explicites | ⚠️ |
| 4672 | Security | Droits d'administration accordés | ⚠️ |
| 4720 | Security | Compte utilisateur créé | Info |
| 4722 | Security | Compte utilisateur activé | Info |
| 4725 | Security | Compte utilisateur désactivé | Info |
| 4740 | Security | Compte verrouillé | 🚨 Critique |
| 5140 | Security | Partage réseau accédé | Info |
| 5145 | Security | Vérification accès partage réseau | Info |

---

## 8. Commandes de vérification de la politique de sécurité

```powershell
# Vérifier la politique de mot de passe du domaine
Get-ADDefaultDomainPasswordPolicy

# Vérifier les GPO actives
Get-GPO -All | Select-Object DisplayName, GpoStatus

# Voir les liens GPO sur une OU
Get-GPInheritance -Target "OU=IRIS-Nice,DC=iris,DC=local"

# Vérifier l'audit en place
auditpol /get /category:*

# Rechercher les comptes verrouillés
Search-ADAccount -LockedOut | Select-Object Name, SamAccountName, LockedOut

# Rechercher les comptes inactifs (30 jours)
Search-ADAccount -AccountInactive -TimeSpan 30 | Select-Object Name, LastLogonDate

# Rechercher les mots de passe expirés
Search-ADAccount -PasswordExpired | Select-Object Name, SamAccountName
```
