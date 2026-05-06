# ============================================================
# SCRIPT 03 - Configuration post-promotion AD DS
# ORDRE    : Apres redemarrage script 02
# FAIT     : DNS forwarders, NTP, zone inverse, UPN alternatif
# ============================================================

Write-Host "=== [03] Configuration post-promotion ===" -ForegroundColor Cyan

# DNS Forwarders
Set-DnsServerForwarder -IPAddress @() -ErrorAction SilentlyContinue
Add-DnsServerForwarder -IPAddress "8.8.8.8" -ErrorAction SilentlyContinue
Add-DnsServerForwarder -IPAddress "1.1.1.1"  -ErrorAction SilentlyContinue
Write-Host "[OK] Forwarders DNS 8.8.8.8 et 1.1.1.1" -ForegroundColor Green

# UPN alternatif
Get-ADForest | Set-ADForest -UPNSuffixes @{Add="iris-nice.fr"}
Write-Host "[OK] UPN iris-nice.fr ajoute" -ForegroundColor Green

# NTP (peut echouer en VM VirtualBox - non bloquant)
w32tm /config /manualpeerlist:"0.fr.pool.ntp.org 1.fr.pool.ntp.org" /syncfromflags:manual /reliable:YES /update 2>$null
net stop w32tm 2>$null | Out-Null
net start w32tm 2>$null | Out-Null
Write-Host "[OK] NTP configure (erreur normale en VM)" -ForegroundColor Green

# Zone DNS inverse VLAN 50
Add-DnsServerPrimaryZone -NetworkID "192.168.50.0/24" `
    -ReplicationScope "Forest" -ErrorAction SilentlyContinue
Add-DnsServerResourceRecordPtr -ZoneName "50.168.192.in-addr.arpa" `
    -Name "10" -PtrDomainName "SRV-DC01.iris.local." -ErrorAction SilentlyContinue
Write-Host "[OK] Zone inverse + PTR SRV-DC01" -ForegroundColor Green

Write-Host "`n=== VERIFICATIONS ===" -ForegroundColor Cyan
Write-Host "Domaine      : $env:USERDNSDOMAIN"
Write-Host "UPN suffixes : $((Get-ADForest).UPNSuffixes)"
$fwd = Get-DnsServerForwarder | Where-Object {$_.IPAddress -notlike "fec0*"}
Write-Host "Forwarders   : $($fwd.IPAddress -join ', ')"
Write-Host "[OK] Script 03 termine - Lancez le script 04" -ForegroundColor Green
