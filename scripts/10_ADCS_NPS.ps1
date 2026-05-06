# ============================================================
# SCRIPT 10 - ADCS (CA interne) + NPS (RADIUS 802.1X)
# ORDRE    : Apres script 09
# APRES    : Redemarrer la VM, puis lancer 10b
# ============================================================

Write-Host "=== [10] ADCS + NPS RADIUS ===" -ForegroundColor Cyan

# Installation roles
Install-WindowsFeature -Name ADCS-Cert-Authority, ADCS-Web-Enrollment, NPAS `
    -IncludeManagementTools -IncludeAllSubFeature
Write-Host "[OK] Roles ADCS et NPS installes" -ForegroundColor Green

# CA Enterprise Root
Install-AdcsCertificationAuthority `
    -CAType                    EnterpriseRootCa `
    -CACommonName              "IRIS-Nice-CA" `
    -CADistinguishedNameSuffix "DC=iris,DC=local" `
    -CryptoProviderName        "RSA#Microsoft Software Key Storage Provider" `
    -KeyLength                 2048 `
    -HashAlgorithmName         SHA256 `
    -ValidityPeriod            Years `
    -ValidityPeriodUnits       10 `
    -Force
Write-Host "[OK] CA IRIS-Nice-CA creee (RSA 2048, SHA256, 10 ans)" -ForegroundColor Green

# Ajouter SRV-DC01 au groupe Serveurs RAS et IAS (nom variable selon langue OS)
$grpRAS = Get-ADGroup -Filter {Name -like "*Serveurs RAS*" -or Name -like "*RAS and IAS*"} | Select-Object -First 1
if ($grpRAS) {
    Add-ADGroupMember -Identity $grpRAS -Members "SRV-DC01$" -ErrorAction SilentlyContinue
    Write-Host "[OK] SRV-DC01 ajoute au groupe $($grpRAS.Name)" -ForegroundColor Green
}

# Activer template RASAndIASServer sur la CA
certutil -SetCATemplates +RASAndIASServer | Out-Null
Write-Host "[OK] Template RASAndIASServer active sur la CA" -ForegroundColor Green

# Enregistrer NPS dans AD
netsh nps add registeredserver 2>$null | Out-Null
Write-Host "[OK] NPS enregistre dans AD" -ForegroundColor Green

# Clients RADIUS (secret partagé a fournir)
Write-Host "`n-- Ajout clients RADIUS --" -ForegroundColor Yellow
Write-Host "Entrez le secret RADIUS partage (identique sur routeur, switch et borne) :" -ForegroundColor Yellow
$secret = Read-Host -AsSecureString
$secretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret))

@(
    @{Name="SW-Cisco2960";  Addr="192.168.50.253"; Vendor="RADIUS Standard"},
    @{Name="AP-C9105AXI";   Addr="192.168.50.150"; Vendor="Cisco"},
    @{Name="R1-Cisco1941W"; Addr="192.168.50.254"; Vendor="Cisco"}
) | ForEach-Object {
    New-NpsRadiusClient -Name $_.Name -Address $_.Addr -SharedSecret $secretPlain `
        -AuthAttributeRequired $false -VendorName $_.Vendor -ErrorAction SilentlyContinue
    Write-Host "[OK] Client RADIUS $($_.Name) ($($_.Addr))" -ForegroundColor Green
}

Restart-Service IAS -ErrorAction SilentlyContinue
Write-Host "[OK] Service NPS redemarre" -ForegroundColor Green

Write-Host "`n[IMPORTANT] Etapes suivantes obligatoires :" -ForegroundColor Red
Write-Host "  1. REDEMARRER la VM maintenant" -ForegroundColor Yellow
Write-Host "  2. Lancer 10b_NPS_PostReboot.ps1" -ForegroundColor Yellow
Write-Host "  3. Configurer certtmpl.msc (voir 02_Procedure_Installation_RP01.md)" -ForegroundColor Yellow
Write-Host "  4. Configurer nps.msc - 3 politiques + attributs VLAN" -ForegroundColor Yellow
