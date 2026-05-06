# ============================================================
# SCRIPT 02 - Installation AD DS + Promotion DC iris.local
# ORDRE    : Apres redemarrage script 01
# NOTE     : Reboot automatique apres promotion
# MOT DE PASSE DSRM : stocker hors depot
# ============================================================

Write-Host "=== [02] Installation AD DS + Promotion DC ===" -ForegroundColor Cyan

Install-WindowsFeature -Name AD-Domain-Services, DNS, GPMC `
    -IncludeManagementTools -IncludeAllSubFeature
Write-Host "[OK] Roles AD DS, DNS, GPMC installes" -ForegroundColor Green

$passwordDSRM = ConvertTo-SecureString "Azerty123!" -AsPlainText -Force
Import-Module ADDSDeployment

Install-ADDSForest `
    -DomainName                    "iris.local" `
    -DomainNetbiosName             "IRIS" `
    -DomainMode                    "WinThreshold" `
    -ForestMode                    "WinThreshold" `
    -DatabasePath                  "C:\Windows\NTDS" `
    -LogPath                       "C:\Windows\NTDS" `
    -SysvolPath                    "C:\Windows\SYSVOL" `
    -SafeModeAdministratorPassword $passwordDSRM `
    -InstallDns:$true `
    -Force:$true
