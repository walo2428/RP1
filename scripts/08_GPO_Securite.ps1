# ============================================================
# SCRIPT 08 - GPO Securite + Politique MDP + Audit
# ORDRE    : Apres script 07
# CREE     : 5 GPO liees aux bonnes OUs + audit 7 categories
# ============================================================

Write-Host "=== [08] GPO + Securite + Audit ===" -ForegroundColor Cyan

$dom  = "iris.local"
$base = "OU=IRIS-Nice,DC=iris,DC=local"

# GPO 1 - Politique mot de passe (OU IRIS-Nice)
New-GPO -Name "IRIS-PasswordPolicy" -Comment "Politique MDP domaine IRIS Nice" -ErrorAction SilentlyContinue
Set-GPRegistryValue -Name "IRIS-PasswordPolicy" `
    -Key "HKLM\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" `
    -ValueName "RequireSignOrSeal" -Type DWord -Value 1
New-GPLink -Name "IRIS-PasswordPolicy" -Target $base -LinkEnabled Yes -ErrorAction SilentlyContinue
Write-Host "[OK] GPO IRIS-PasswordPolicy liee a OU IRIS-Nice" -ForegroundColor Green

# GPO 2 - Restrictions etudiants (OU Etudiants)
New-GPO -Name "IRIS-Restrictions-Etudiants" -Comment "Restrictions postes etudiants" -ErrorAction SilentlyContinue
Set-GPRegistryValue -Name "IRIS-Restrictions-Etudiants" `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoControlPanel" -Type DWord -Value 1
Set-GPRegistryValue -Name "IRIS-Restrictions-Etudiants" `
    -Key "HKCU\Software\Policies\Microsoft\Windows\System" `
    -ValueName "DisableCMD" -Type DWord -Value 1
Set-GPRegistryValue -Name "IRIS-Restrictions-Etudiants" `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "DisableRegistryTools" -Type DWord -Value 1
Set-GPRegistryValue -Name "IRIS-Restrictions-Etudiants" `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoDrives" -Type DWord -Value 4
New-GPLink -Name "IRIS-Restrictions-Etudiants" -Target "OU=Etudiants,$base" -LinkEnabled Yes -ErrorAction SilentlyContinue
Write-Host "[OK] GPO IRIS-Restrictions-Etudiants liee a OU Etudiants" -ForegroundColor Green

# GPO 3 - Lecteurs reseau (OU IRIS-Nice) - contenu genere par script 09
New-GPO -Name "IRIS-LecteursReseau" -Comment "Mappages lecteurs H: S: P: A: via GPO Preferences" -ErrorAction SilentlyContinue
New-GPLink -Name "IRIS-LecteursReseau" -Target $base -LinkEnabled Yes -ErrorAction SilentlyContinue
Write-Host "[OK] GPO IRIS-LecteursReseau creee (Drives.xml genere par script 09)" -ForegroundColor Green

# GPO 4 - Securite baseline (OU IRIS-Nice)
New-GPO -Name "IRIS-Securite-Baseline" -Comment "Securite baseline - ecran veille, autorun, firewall" -ErrorAction SilentlyContinue
# Ecran de veille
Set-GPRegistryValue -Name "IRIS-Securite-Baseline" `
    -Key "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
    -ValueName "ScreenSaveActive" -Type String -Value "1"
Set-GPRegistryValue -Name "IRIS-Securite-Baseline" `
    -Key "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
    -ValueName "ScreenSaverIsSecure" -Type String -Value "1"
Set-GPRegistryValue -Name "IRIS-Securite-Baseline" `
    -Key "HKCU\Software\Policies\Microsoft\Windows\Control Panel\Desktop" `
    -ValueName "ScreenSaveTimeOut" -Type String -Value "600"
# Autorun desactive
Set-GPRegistryValue -Name "IRIS-Securite-Baseline" `
    -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoDriveTypeAutoRun" -Type DWord -Value 255
# Firewall
Set-GPRegistryValue -Name "IRIS-Securite-Baseline" `
    -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile" `
    -ValueName "EnableFirewall" -Type DWord -Value 1
# Message legal
Set-GPRegistryValue -Name "IRIS-Securite-Baseline" `
    -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "LegalNoticeCaption" -Type String -Value "IRIS Nice - Acces reglemente"
Set-GPRegistryValue -Name "IRIS-Securite-Baseline" `
    -Key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -ValueName "LegalNoticeText" -Type String -Value "Acces reserve aux utilisateurs autorises. Toute utilisation non autorisee est interdite et tracee."
New-GPLink -Name "IRIS-Securite-Baseline" -Target $base -LinkEnabled Yes -ErrorAction SilentlyContinue
Write-Host "[OK] GPO IRIS-Securite-Baseline liee a OU IRIS-Nice" -ForegroundColor Green

# GPO 5 - Acces etendu profs (OU Professeurs)
New-GPO -Name "IRIS-Profs-Acces" -Comment "Acces etendu professeurs - panneau config accessible" -ErrorAction SilentlyContinue
Set-GPRegistryValue -Name "IRIS-Profs-Acces" `
    -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
    -ValueName "NoControlPanel" -Type DWord -Value 0
New-GPLink -Name "IRIS-Profs-Acces" -Target "OU=Professeurs,$base" -LinkEnabled Yes -ErrorAction SilentlyContinue
Write-Host "[OK] GPO IRIS-Profs-Acces liee a OU Professeurs" -ForegroundColor Green

# Politique MDP domaine
Set-ADDefaultDomainPasswordPolicy -Identity $dom `
    -MinPasswordLength 8 `
    -PasswordHistoryCount 5 `
    -MaxPasswordAge "90.00:00:00" `
    -MinPasswordAge "1.00:00:00" `
    -ComplexityEnabled $true `
    -ReversibleEncryptionEnabled $false
Write-Host "[OK] Politique MDP domaine : 8 car., complexite, 90 jours, historique 5" -ForegroundColor Green

# Audit via GUIDs (independant de la langue OS)
$audits = @(
    "{0CCE9215-69AE-11D9-BED3-505054503030}", # Ouverture/Fermeture session
    "{0CCE9242-69AE-11D9-BED3-505054503030}", # Authentification de compte
    "{0CCE9236-69AE-11D9-BED3-505054503030}", # Gestion des comptes
    "{0CCE9227-69AE-11D9-BED3-505054503030}", # Acces aux objets
    "{0CCE922F-69AE-11D9-BED3-505054503030}", # Modification de politique
    "{0CCE9228-69AE-11D9-BED3-505054503030}", # Utilisation des privileges
    "{0CCE9213-69AE-11D9-BED3-505054503030}"  # Evenements systeme
)
foreach ($guid in $audits) {
    auditpol /set /subcategory:$guid /success:enable /failure:enable | Out-Null
}
Write-Host "[OK] Audit 7 categories (succes + echecs)" -ForegroundColor Green

Write-Host "`n=== VERIFICATIONS ===" -ForegroundColor Cyan
Get-GPO -All | Where-Object {$_.DisplayName -like "IRIS-*"} |
    Select-Object DisplayName, GpoStatus | Format-Table -AutoSize
Write-Host "[OK] Script 08 termine - Lancez le script 09" -ForegroundColor Green
