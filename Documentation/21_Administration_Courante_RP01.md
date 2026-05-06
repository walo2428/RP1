# 21 — Procédures d'Administration Courante RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Ajouter un nouvel utilisateur

### Cas : Nouvel étudiant SISR

```powershell
# Se connecter sur SRV-DC01 en tant qu'Administrateur du domaine

$Password = ConvertTo-SecureString "Azerty1!" -AsPlainText -Force

# Créer le compte
New-ADUser `
    -Name "Prénom Nom" `
    -GivenName "Prénom" `
    -Surname "Nom" `
    -SamAccountName "plogin" `
    -UserPrincipalName "plogin@iris.local" `
    -Path "OU=SISR,OU=Etudiants,OU=IRIS-Nice,DC=iris,DC=local" `
    -AccountPassword $Password `
    -Enabled $true `
    -PasswordNeverExpires $false `
    -ChangePasswordAtLogon $false

# Ajouter aux groupes
Add-ADGroupMember -Identity "GRP-Etudiants-SISR" -Members "plogin"
Add-ADGroupMember -Identity "GRP-WiFi-SISR" -Members "plogin"

# Créer le HomeDir
$HomePath = "C:\HomeDir\plogin"
New-Item -ItemType Directory -Path $HomePath -Force

# Attribuer les droits NTFS
$Acl = Get-Acl $HomePath
$Acl.SetAccessRuleProtection($true, $false)
$AdminRule = New-Object Security.AccessControl.FileSystemAccessRule("Administrateurs","FullControl","ContainerInherit,ObjectInherit","None","Allow")
$UserRule = New-Object Security.AccessControl.FileSystemAccessRule("IRIS\plogin","Modify","ContainerInherit,ObjectInherit","None","Allow")
$Acl.AddAccessRule($AdminRule)
$Acl.AddAccessRule($UserRule)
Set-Acl -Path $HomePath -AclObject $Acl

Write-Host "Compte plogin créé avec succès." -ForegroundColor Green
```

### Règle de nommage des logins

| Format | Exemple |
|--------|---------|
| 1ère lettre prénom + nom complet | Nathan Belloum → nbelloum |
| Tout en minuscules | — |
| Sans accents | Théo → rbears |
| Sans espaces ni tirets | Jean-Pierre → jpierre |

### Groupes à affecter selon le profil

| Profil | Groupe AD | Groupe WiFi |
|--------|----------|------------|
| Etudiant SISR | GRP-Etudiants-SISR | GRP-WiFi-SISR |
| Etudiant SLAM | GRP-Etudiants-SLAM | GRP-WiFi-SISR |
| Professeur | GRP-Professeurs | GRP-WiFi-Profs |
| Administration | GRP-Administration | GRP-WiFi-Admin |
| Informatique | GRP-Informatique | GRP-WiFi-Admin |

---

## 2. Désactiver un compte utilisateur

```powershell
# Désactiver sans supprimer (recommandé)
Disable-ADAccount -Identity "plogin"

# Vérifier
Get-ADUser -Identity "plogin" -Properties Enabled | Select-Object SamAccountName, Enabled
```

---

## 3. Réinitialiser un mot de passe

```powershell
# Réinitialiser le mot de passe
$NewPwd = ConvertTo-SecureString "NouveauMdp1!" -AsPlainText -Force
Set-ADAccountPassword -Identity "nbelloum" -NewPassword $NewPwd -Reset

# Forcer le changement au prochain logon (optionnel)
Set-ADUser -Identity "nbelloum" -ChangePasswordAtLogon $true
```

---

## 4. Débloquer un compte verrouillé

```powershell
# Voir si un compte est verrouillé
Get-ADUser -Identity "nbelloum" -Properties LockedOut | Select-Object SamAccountName, LockedOut

# Débloquer
Unlock-ADAccount -Identity "nbelloum"
```

---

## 5. Ajouter un nouveau poste au domaine

### Sur le poste client (PowerShell en Admin)

```powershell
# Prérequis : DNS = 192.168.50.10 configuré sur le poste

# Renommer le poste
Rename-Computer -NewName "SISR-02" -Force

# Joindre le domaine
Add-Computer -DomainName "iris.local" `
    -Credential (Get-Credential IRIS\Administrator) `
    -OUPath "OU=Ordinateurs-IRIS,OU=IRIS-Nice,DC=iris,DC=local" `
    -Restart
```

---

## 6. Vérifier les GPO appliquées sur un poste

```powershell
# Sur le poste client en session utilisateur
gpresult /r

# Rapport HTML complet
gpresult /H C:\rapport_gpo.html
# Ouvrir C:\rapport_gpo.html dans un navigateur

# Forcer la mise à jour des GPO
gpupdate /force
```

---

## 7. Gérer les partages — ajouter un accès

```powershell
# Donner accès SMB à un groupe sur un partage existant
Grant-SmbShareAccess -Name "SISR" -AccountName "IRIS\NouveauGroupe" -AccessRight Change -Force

# Vérifier les accès SMB
Get-SmbShareAccess -Name "SISR"

# Ajouter un droit NTFS
$Acl = Get-Acl "C:\Partages\Etudiants-SISR"
$Rule = New-Object Security.AccessControl.FileSystemAccessRule("IRIS\NouveauGroupe","Modify","ContainerInherit,ObjectInherit","None","Allow")
$Acl.AddAccessRule($Rule)
Set-Acl "C:\Partages\Etudiants-SISR" $Acl
```

---

## 8. Gérer le DHCP — ajouter une réservation

```powershell
# Réserver une IP fixe par adresse MAC (utile pour une imprimante, un serveur)
Add-DhcpServerv4Reservation `
    -ScopeId 192.168.50.0 `
    -IPAddress 192.168.50.20 `
    -ClientId "AA-BB-CC-DD-EE-FF" `
    -Description "Serveur de fichiers secondaire"

# Vérifier les réservations
Get-DhcpServerv4Reservation -ScopeId 192.168.50.0
```

---

## 9. Consulter les logs d'événements

```powershell
# Connexions réussies (Event 4624)
Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=4624]]" | Select-Object -First 20

# Connexions échouées (Event 4625)
Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=4625]]" | Select-Object -First 20

# Création de compte (Event 4720)
Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=4720]]" | Select-Object -First 10

# Verrouillage de compte (Event 4740)
Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=4740]]" | Select-Object -First 10

# Accès aux partages (Event 5140)
Get-WinEvent -LogName Security -FilterXPath "*[System[EventID=5140]]" | Select-Object -First 20
```

---

## 10. Sauvegarder Active Directory

```powershell
# Prérequis : Windows Server Backup installé
Install-WindowsFeature Windows-Server-Backup

# Sauvegarde System State (AD + DNS + DHCP + GPO)
wbadmin start systemstatebackup -backupTarget:E: -quiet

# Planifier une sauvegarde quotidienne
$Policy = New-WBPolicy
$FileSpec = New-WBFileSpec -FileSpec "C:"
Add-WBVolume -Policy $Policy -Volume (Get-WBVolume -AllVolumes | Where-Object {$_.DriveLetter -eq 'C'})
Set-WBSchedule -Policy $Policy -Schedule 02:00
Set-WBPolicy -Policy $Policy
```

---

## 11. Vérifier l'état des services critiques

```powershell
# Vérifier les services essentiels
$Services = @("ADWS", "DNS", "Netlogon", "DHCPServer", "IAS", "CertSvc")
foreach ($svc in $Services) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        $color = if ($s.Status -eq "Running") {"Green"} else {"Red"}
        Write-Host "$($svc): $($s.Status)" -ForegroundColor $color
    }
}
```

---

## 12. Ajouter un client RADIUS dans NPS

```powershell
# Ajouter un nouveau switch ou AP en client RADIUS
New-NpsRadiusClient -Name "SW-NOUVEAU" `
    -Address "192.168.50.252" `
    -SharedSecret "iris@radius123" `
    -Enabled $true

# Vérifier
Get-NpsRadiusClient
```

---

## 13. Tâches d'administration périodiques

| Fréquence | Tâche | Commande |
|-----------|-------|---------|
| Hebdomadaire | Vérifier comptes verrouillés | `Search-ADAccount -LockedOut` |
| Hebdomadaire | Vérifier baux DHCP | `Get-DhcpServerv4ScopeStatistics` |
| Mensuelle | Nettoyer postes inactifs | `Search-ADAccount -AccountInactive -TimeSpan 30` |
| Mensuelle | Vérifier expiration certificat NPS | `Get-ChildItem Cert:\LocalMachine\My` |
| Semestrielle | Rotation mots de passe de service | Manuellement dans AD |
| Annuelle | Renouveler certificat NPS | `certutil -enroll -machine RASAndIASServer` |
