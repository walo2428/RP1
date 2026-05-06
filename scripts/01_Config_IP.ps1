# ============================================================
# SCRIPT 01 - Configuration IP fixe + Renommage SRV-DC01
# ORDRE    : Lancer EN PREMIER sur Windows Server 2022 vierge
# PREREQ   : VirtualBox - Carte1=NAT, Carte2=Host-Only 192.168.50.x
# LANCE    : PowerShell en Administrateur
# RESULTAT : IP 192.168.50.10 configuree + reboot automatique
# ============================================================

Set-ExecutionPolicy Unrestricted -Force
Write-Host "=== [01] Configuration IP + Renommage ===" -ForegroundColor Cyan

# Afficher les cartes disponibles
Get-NetAdapter | Format-Table Name, InterfaceDescription, Status -AutoSize

# Detecter la carte Host-Only (pas NAT = pas 10.0.2.x)
$carteHO = $null
foreach ($carte in (Get-NetAdapter | Where-Object { $_.Status -eq "Up" })) {
    $ip = (Get-NetIPAddress -InterfaceIndex $carte.InterfaceIndex `
        -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    if ($ip -notlike "10.0.2.*" -and $ip -notlike "169.254.*") {
        $carteHO = $carte; break
    }
}
if ($null -eq $carteHO) {
    $carteHO = Get-NetAdapter | Where-Object { $_.Name -like "Ethernet*" } | Select-Object -Last 1
}
if ($null -eq $carteHO) {
    Write-Warning "Carte Host-Only non trouvee ! Verifiez la configuration VirtualBox."
    exit 1
}
Write-Host "Carte Host-Only detectee : $($carteHO.Name)" -ForegroundColor Green

# Supprimer IPs existantes sur la carte Host-Only
Get-NetIPAddress -InterfaceIndex $carteHO.InterfaceIndex `
    -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceIndex $carteHO.InterfaceIndex `
    -Confirm:$false -ErrorAction SilentlyContinue

# Appliquer IP fixe + DNS
New-NetIPAddress -InterfaceIndex $carteHO.InterfaceIndex `
    -IPAddress "192.168.50.10" -PrefixLength 24
Set-DnsClientServerAddress -InterfaceIndex $carteHO.InterfaceIndex `
    -ServerAddresses "192.168.50.10"

# Remettre la carte NAT en DHCP automatique
$carteNAT = Get-NetAdapter | Where-Object { $_.Name -ne $carteHO.Name } | Select-Object -First 1
if ($carteNAT) {
    Set-NetIPInterface -InterfaceIndex $carteNAT.InterfaceIndex `
        -Dhcp Enabled -ErrorAction SilentlyContinue
}

Write-Host "[OK] IP 192.168.50.10/24 configuree sur $($carteHO.Name)" -ForegroundColor Green

# Verification
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127*"} |
    Select-Object InterfaceAlias, IPAddress | Format-Table -AutoSize

# Renommage et reboot
if ($env:COMPUTERNAME -ne "SRV-DC01") {
    Write-Host "Renommage en SRV-DC01 et redemarrage..." -ForegroundColor Yellow
    Rename-Computer -NewName "SRV-DC01" -Restart -Force
} else {
    Write-Host "[OK] Deja nomme SRV-DC01 - Lancez le script 02" -ForegroundColor Green
}
