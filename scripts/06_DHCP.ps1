# ============================================================
# SCRIPT 06 - Installation DHCP + 5 Scopes VLANs
# ORDRE    : Apres script 05
# IMPORTANT: Relais DHCP a configurer sur le routeur Cisco :
#            ip helper-address 192.168.50.10 sur chaque sous-interface VLAN
# ============================================================

Write-Host "=== [06] Installation DHCP + Scopes ===" -ForegroundColor Cyan

Install-WindowsFeature -Name DHCP -IncludeManagementTools
Write-Host "[OK] Role DHCP installe" -ForegroundColor Green

Add-DhcpServerInDC -DnsName "SRV-DC01.iris.local" -IPAddress "192.168.50.10"
Write-Host "[OK] Serveur DHCP autorise dans AD" -ForegroundColor Green

# Supprimer la notification post-installation
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12" `
    -Name "ConfigurationState" -Value 2 -ErrorAction SilentlyContinue

function New-Scope {
    param($Nom, $Start, $End, $ScopeId, $GW, $DNS, $Domaine, $Bail = 8)
    Add-DhcpServerv4Scope -Name $Nom -StartRange $Start -EndRange $End `
        -SubnetMask "255.255.255.0" -State Active
    if ($DNS -like "*.*.*.* *") {
        # Plusieurs DNS
        $dnsArr = $DNS -split " "
        Set-DhcpServerv4OptionValue -ScopeId $ScopeId -Router $GW `
            -OptionId 6 -Value $dnsArr -DnsDomain $Domaine
    } else {
        Set-DhcpServerv4OptionValue -ScopeId $ScopeId -Router $GW `
            -DnsServer $DNS -DnsDomain $Domaine
    }
    Set-DhcpServerv4Scope -ScopeId $ScopeId -LeaseDuration ([TimeSpan]::FromDays($Bail))
}

New-Scope "VLAN10-Etudiants"      "192.168.10.10" "192.168.10.250" "192.168.10.0" "192.168.10.254" "192.168.50.10" "iris.local"
Write-Host "[OK] Scope VLAN 10 Etudiants" -ForegroundColor Green

New-Scope "VLAN20-Professeurs"    "192.168.20.10" "192.168.20.250" "192.168.20.0" "192.168.20.254" "192.168.50.10" "iris.local"
Write-Host "[OK] Scope VLAN 20 Professeurs" -ForegroundColor Green

New-Scope "VLAN30-Administration" "192.168.30.10" "192.168.30.250" "192.168.30.0" "192.168.30.254" "192.168.50.10" "iris.local"
Write-Host "[OK] Scope VLAN 30 Administration" -ForegroundColor Green

# VLAN 40 Guest - DNS public uniquement (pas acces services internes)
Add-DhcpServerv4Scope -Name "VLAN40-Guest" -StartRange "192.168.40.10" -EndRange "192.168.40.250" `
    -SubnetMask "255.255.255.0" -State Active
Set-DhcpServerv4OptionValue -ScopeId "192.168.40.0" -Router "192.168.40.254" `
    -OptionId 6 -Value "8.8.8.8","8.8.4.4"
Set-DhcpServerv4Scope -ScopeId "192.168.40.0" -LeaseDuration ([TimeSpan]::FromDays(1))
Write-Host "[OK] Scope VLAN 40 Guest (DNS public 8.8.8.8)" -ForegroundColor Green

New-Scope "VLAN99-PreAuth"        "192.168.99.10" "192.168.99.250" "192.168.99.0" "192.168.99.254" "192.168.50.10" "iris.local" -Bail 1
Write-Host "[OK] Scope VLAN 99 PreAuth (bail 1 jour)" -ForegroundColor Green

Restart-Service DHCPServer
Write-Host "[OK] Service DHCP redemarre" -ForegroundColor Green

Write-Host "`n=== VERIFICATIONS ===" -ForegroundColor Cyan
Get-DhcpServerv4Scope | Select-Object Name, ScopeId, StartRange, EndRange, State | Format-Table -AutoSize
Write-Host "[OK] Script 06 termine - Lancez le script 07" -ForegroundColor Green
