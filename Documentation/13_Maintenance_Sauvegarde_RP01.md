# 13 — Maintenance et Sauvegarde RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Opérations de maintenance périodiques

### Quotidien

```powershell
# Vérifier l'état des services critiques
@("ADWS","DNS","DHCPServer","IAS","CertSvc","Netlogon","W32Time") | ForEach-Object {
    $s = Get-Service $_ -ErrorAction SilentlyContinue
    $color = if ($s.Status -eq "Running") {"Green"} else {"Red"}
    Write-Host "$($_.PadRight(15)) : $($s.Status)" -ForegroundColor $color
}

# Vérifier les connexions échouées (tentatives de brute force)
$echecs = (Get-EventLog -LogName Security -InstanceId 4625 -After (Get-Date).AddHours(-24)).Count
Write-Host "Echecs de connexion (24h) : $echecs"
if ($echecs -gt 20) { Write-Warning "Nombre eleve d'echecs - verifier les logs !" }
```

### Hebdomadaire

```powershell
# Comptes bloqués
Search-ADAccount -LockedOut | Select-Object Name, SamAccountName, LockedOut | Format-Table

# Comptes inactifs depuis 30 jours
$seuil = (Get-Date).AddDays(-30)
Search-ADAccount -AccountInactive -TimeSpan (New-TimeSpan -Days 30) |
    Where-Object {$_.ObjectClass -eq "User"} |
    Select-Object Name, SamAccountName, LastLogonDate | Format-Table

# Espace disque partages
@("C:\Partages","C:\HomeDir") | ForEach-Object {
    $taille = (Get-ChildItem $_ -Recurse -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum).Sum
    Write-Host "$_ : $([Math]::Round($taille/1GB,2)) Go"
}
```

### Mensuel

```powershell
# Vérifier les certificats expirant dans 60 jours
Get-ChildItem Cert:\LocalMachine\My | Where-Object {
    $_.NotAfter -lt (Get-Date).AddDays(60)
} | Select-Object Subject, NotAfter | Format-Table

# Vérifier les baux DHCP orphelins
Get-DhcpServerv4Lease -AllScope | Where-Object {
    $_.LeaseExpiryTime -lt (Get-Date) -and $_.AddressState -eq "Active"
}

# Synchronisation AD
repadmin /replsummary
```

---

## 2. Sauvegarde Active Directory

### Sauvegarde de l'état du système (System State)

```powershell
# Nécessite Windows Server Backup (installé via Add-WindowsFeature)
Install-WindowsFeature Windows-Server-Backup

# Sauvegarde manuelle de l'état système
wbadmin start systemstatebackup -backupTarget:D: -quiet

# Vérifier la dernière sauvegarde
wbadmin get versions
```

### Sauvegarde exportation AD (LDIF)

```powershell
# Exporter tous les utilisateurs
$base = "OU=IRIS-Nice,DC=iris,DC=local"
Get-ADUser -Filter * -SearchBase $base -Properties * |
    Select-Object Name, SamAccountName, UserPrincipalName, Enabled, 
                  DistinguishedName, HomeDirectory, HomeDrive |
    Export-Csv "C:\Backup\users_backup_$(Get-Date -Format yyyyMMdd).csv" -Encoding UTF8 -NoTypeInformation

# Exporter les groupes et membres
Get-ADGroup -Filter {Name -like "GRP-*"} | ForEach-Object {
    $groupe = $_
    Get-ADGroupMember $groupe | Select-Object @{n="Groupe";e={$groupe.Name}}, Name, SamAccountName
} | Export-Csv "C:\Backup\groups_backup_$(Get-Date -Format yyyyMMdd).csv" -Encoding UTF8 -NoTypeInformation

Write-Host "[OK] Sauvegarde CSV exportee dans C:\Backup\"
```

### Sauvegarde GPO

```powershell
$backupDir = "C:\Backup\GPO_$(Get-Date -Format yyyyMMdd)"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Get-GPO -All | ForEach-Object {
    Backup-GPO -Name $_.DisplayName -Path $backupDir
}
Write-Host "[OK] GPO sauvegardees dans $backupDir"
```

### Sauvegarde DHCP

```powershell
Export-DhcpServer -File "C:\Backup\dhcp_backup_$(Get-Date -Format yyyyMMdd).xml" -Leases -Force
Write-Host "[OK] Config DHCP + baux sauvegardes"
```

### Sauvegarde configuration NPS

```powershell
$npsFile = "C:\Backup\NPS_backup_$(Get-Date -Format yyyyMMdd).xml"
netsh nps export filename=$npsFile exportPSK=NO
Write-Host "[OK] Config NPS sauvegardee (sans secrets)"
```

---

## 3. Restauration

### Restaurer AD depuis System State

```powershell
# ATTENTION : necessite le mode restauration de services d'annuaire (DSRM)
# Redemarrer en DSRM : bcdedit /set safeboot dsrepair
# Apres reboot :
wbadmin start systemstaterecovery -version:[VERSION_DE_SAUVEGARDE] -quiet
```

### Restaurer les GPO

```powershell
$backupDir = "C:\Backup\GPO_20260409"
Get-GPOBackup -All -Path $backupDir | Restore-GPO -Path $backupDir
Write-Host "[OK] GPO restaurees depuis $backupDir"
```

### Restaurer le DHCP

```powershell
Import-DhcpServer -File "C:\Backup\dhcp_backup_20260409.xml" -BackupPath "C:\Backup\" -Leases -Force
Restart-Service DHCPServer
Write-Host "[OK] DHCP restaure"
```

### Restaurer la configuration NPS

```powershell
netsh nps import filename="C:\Backup\NPS_backup_20260409.xml"
Restart-Service IAS
Write-Host "[OK] NPS restaure (resaisir les secrets RADIUS)"
```

---

## 4. Supervision des événements importants

### Script de supervision rapide

```powershell
# ============================================================
# Supervision quotidienne SRV-DC01
# ============================================================
Write-Host "=== SUPERVISION $(Get-Date -Format 'dd/MM/yyyy HH:mm') ===" -ForegroundColor Cyan

# Services
$services = @("ADWS","DNS","DHCPServer","IAS","CertSvc","Netlogon")
$services | ForEach-Object {
    $s = Get-Service $_ -ErrorAction SilentlyContinue
    if ($s.Status -ne "Running") {
        Write-Host "[ALERTE] Service $_ : $($s.Status)" -ForegroundColor Red
    }
}

# Comptes bloqués
$bloques = Search-ADAccount -LockedOut
if ($bloques) {
    Write-Host "[ALERTE] Comptes bloques :" -ForegroundColor Yellow
    $bloques | ForEach-Object { Write-Host "  - $($_.SamAccountName)" -ForegroundColor Yellow }
}

# Espace disque
$disque = Get-PSDrive C | Select-Object @{n="UsedGB";e={[Math]::Round(($_.Used/1GB),1)}}, @{n="FreeGB";e={[Math]::Round(($_.Free/1GB),1)}}
if ($disque.FreeGB -lt 10) {
    Write-Host "[ALERTE] Espace disque faible : $($disque.FreeGB) Go libres" -ForegroundColor Red
}

Write-Host "=== FIN SUPERVISION ===" -ForegroundColor Cyan
```

---

## 5. Procédure de réinitialisation complète

En cas de besoin de repartir de zéro (exercice BTS) :

```powershell
# 1. Supprimer la VM SRV-DC01 dans VirtualBox (ou snapshot avant)
# 2. Créer une nouvelle VM Windows Server 2022
# 3. Exécuter les scripts dans l'ordre :
#    01 → reboot → 02 → reboot → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → reboot → 10b
# 4. Configuration manuelle certtmpl.msc + nps.msc
# 5. Script 11 (vérification)
# 6. Jonction SISR-01 via script 13
# 7. Script 12 (test client)
# Durée estimée : 2-3 heures
```
