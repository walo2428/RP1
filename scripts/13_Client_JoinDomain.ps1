# ============================================================
# SCRIPT 13 - Jonction poste client au domaine iris.local
# IMPORTANT : Executer sur le POSTE CLIENT (pas le serveur !)
# PREREQ   : SRV-DC01 accessible sur 192.168.50.10
# ============================================================

Write-Host "=== [13] Jonction domaine iris.local ===" -ForegroundColor Cyan

# Configurer DNS vers SRV-DC01
Write-Host "`n-- Configuration DNS --" -ForegroundColor Yellow
Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | ForEach-Object {
    $ip = (Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    if ($ip -notlike "127*") {
        Set-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -ServerAddresses "192.168.50.10"
        Write-Host "[OK] DNS 192.168.50.10 sur $($_.Name)" -ForegroundColor Green
    }
}
ipconfig /flushdns | Out-Null

# Tester connectivite
Write-Host "`n-- Test connectivite --" -ForegroundColor Yellow
$test = Test-NetConnection -ComputerName "192.168.50.10" -Port 389 -ErrorAction SilentlyContinue
if ($test.TcpTestSucceeded) {
    Write-Host "[OK] SRV-DC01 accessible (LDAP port 389)" -ForegroundColor Green
} else {
    Write-Warning "SRV-DC01 (192.168.50.10) non accessible !"
    Write-Warning "Verifiez que la VM SRV-DC01 est demarree et sur le meme reseau Host-Only."
    exit 1
}

$dns = Resolve-DnsName "iris.local" -ErrorAction SilentlyContinue
if ($dns) { Write-Host "[OK] DNS resout iris.local" -ForegroundColor Green }
else { Write-Warning "DNS ne resout pas iris.local - verifiez le DNS du poste"; exit 1 }

# Credentials administrateur domaine
Write-Host "`n-- Jonction au domaine --" -ForegroundColor Yellow
$creds = Get-Credential -Message "Compte administrateur du domaine (ex: IRIS\Administrateur)"

Add-Computer `
    -DomainName "iris.local" `
    -Credential $creds `
    -OUPath     "OU=Ordinateurs-IRIS,OU=IRIS-Nice,DC=iris,DC=local" `
    -Restart `
    -Force

Write-Host "[INFO] Redemarrage en cours pour finaliser la jonction..." -ForegroundColor Yellow
