# ============================================================
# SCRIPT 11 - Verification complete SRV-DC01
# ORDRE    : Apres tous les scripts + configurations graphiques
# RESULTAT : 0 erreur = infrastructure complete et fonctionnelle
# ============================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   VERIFICATION FINALE - SRV-DC01       " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$erreurs = 0
function OK   { param($m) Write-Host "[OK] $m" -ForegroundColor Green }
function KO   { param($m) Write-Host "[KO] $m" -ForegroundColor Red; $script:erreurs++ }
function INFO { param($m) Write-Host "[--] $m" -ForegroundColor Yellow }

# 1. RESEAU
Write-Host "`n[1] RESEAU" -ForegroundColor Cyan
$ip50 = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -eq "192.168.50.10"}
if ($ip50) { OK "IP 192.168.50.10 sur $($ip50.InterfaceAlias)" } else { KO "IP 192.168.50.10 manquante" }
$nat = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "10.0.2.*"}
if ($nat) { OK "NAT internet : $($nat.IPAddress)" } else { INFO "NAT sans IP (normal hors lab)" }

# 2. AD DS
Write-Host "`n[2] ACTIVE DIRECTORY" -ForegroundColor Cyan
try {
    $dom = Get-ADDomain
    OK "Domaine : $($dom.DNSRoot) | Mode : $($dom.DomainMode)"
} catch { KO "AD DS non accessible" }
$nb = (Get-ADUser -Filter * -SearchBase "OU=IRIS-Nice,DC=iris,DC=local" | Measure-Object).Count
if ($nb -eq 21) { OK "21 comptes utilisateurs" } else { KO "$nb comptes (attendu 21)" }
@("GRP-Etudiants-SISR","GRP-Etudiants-SLAM","GRP-Professeurs","GRP-Administration",
  "GRP-WiFi-SISR","GRP-WiFi-Profs","GRP-WiFi-Admin","GRP-Informatique","GRP-VPN-Users") | ForEach-Object {
    if (Get-ADGroup $_ -ErrorAction SilentlyContinue) { OK "Groupe $_ present" }
    else { KO "Groupe $_ MANQUANT" }
}

# 3. DNS
Write-Host "`n[3] DNS" -ForegroundColor Cyan
if (Get-DnsServerZone -Name "iris.local" -ErrorAction SilentlyContinue) { OK "Zone iris.local" }
else { KO "Zone iris.local ABSENTE" }
if (Get-DnsServerZone | Where-Object {$_.ZoneName -like "*50.168*"}) { OK "Zone inverse 50.168.192" }
else { KO "Zone inverse manquante" }
$fwd = Get-DnsServerForwarder | Where-Object {$_.IPAddress -notlike "fec0*"}
if ($fwd) { OK "Forwarders : $($fwd.IPAddress -join ', ')" } else { KO "Forwarders manquants" }

# 4. DHCP
Write-Host "`n[4] DHCP" -ForegroundColor Cyan
if ((Get-Service DHCPServer).Status -eq "Running") { OK "Service DHCP actif" } else { KO "DHCP arrete" }
$scopes = Get-DhcpServerv4Scope
if ($scopes.Count -eq 5) { OK "5 scopes actifs" } else { KO "$($scopes.Count) scopes (attendu 5)" }
$scopes | ForEach-Object { INFO "  $($_.Name) : $($_.ScopeId) [$($_.State)]" }

# 5. PARTAGES SMB
Write-Host "`n[5] PARTAGES SMB" -ForegroundColor Cyan
@("SISR","SLAM","Professeurs","Administration","Commun","HomeDir$") | ForEach-Object {
    $s = Get-SmbShare -Name $_ -ErrorAction SilentlyContinue
    if ($s) { OK "Partage $_ -> $($s.Path)" } else { KO "Partage $_ ABSENT" }
}
$nbHome = (Get-ChildItem C:\HomeDir).Count
if ($nbHome -eq 21) { OK "21 HomeDirs presents" } else { KO "$nbHome HomeDirs (attendu 21)" }
$smbAccess = Get-SmbShareAccess -Name "HomeDir$"
if ($smbAccess | Where-Object {$_.AccountName -like "*Utilisateurs du domaine*"}) {
    OK "HomeDir$ accessible aux utilisateurs du domaine"
} else { KO "HomeDir$ acces utilisateurs manquant" }

# 6. ACL HOMEDIRS
Write-Host "`n[6] ACL HOMEDIRS" -ForegroundColor Cyan
$aclOK = 0
Get-ADUser -Filter * -SearchBase "OU=IRIS-Nice,DC=iris,DC=local" | ForEach-Object {
    $path = "C:\HomeDir\$($_.SamAccountName)"
    if (Test-Path $path) {
        $acl = (Get-Acl $path).Access
        if ($acl | Where-Object {$_.IdentityReference -like "*$($_.SamAccountName)*"}) { $aclOK++ }
    }
}
if ($aclOK -eq 21) { OK "ACL correctes sur les 21 HomeDirs" }
else { KO "ACL incorrectes sur $($21-$aclOK) HomeDirs" }

# 7. GPO
Write-Host "`n[7] GPO" -ForegroundColor Cyan
@("IRIS-PasswordPolicy","IRIS-Restrictions-Etudiants","IRIS-LecteursReseau",
  "IRIS-Securite-Baseline","IRIS-Profs-Acces") | ForEach-Object {
    if (Get-GPO -Name $_ -ErrorAction SilentlyContinue) { OK "GPO $_ active" }
    else { KO "GPO $_ ABSENTE" }
}
$gpoId  = (Get-GPO -Name "IRIS-LecteursReseau").Id
$drvXml = "C:\Windows\SYSVOL\sysvol\iris.local\Policies\{$gpoId}\User\Preferences\Drives\Drives.xml"
if (Test-Path $drvXml) {
    $drives = [xml](Get-Content $drvXml)
    if ($drives.Drives.Drive.Count -ge 6) { OK "$($drives.Drives.Drive.Count) mappages lecteurs dans GPO Preferences" }
    else { KO "Seulement $($drives.Drives.Drive.Count) mappages (attendu 6)" }
} else { KO "Drives.xml manquant dans GPO Preferences" }

# 8. ADCS
Write-Host "`n[8] ADCS - CA" -ForegroundColor Cyan
if ((certutil -cainfo name 2>&1) -match "IRIS-Nice-CA") { OK "CA IRIS-Nice-CA operationnelle" }
else { KO "CA non trouvee" }
if (Get-CATemplate | Where-Object {$_.Name -eq "RASAndIASServer"}) { OK "Template RASAndIASServer actif" }
else { KO "Template RASAndIASServer manquant" }

# 9. CERTIFICATS
Write-Host "`n[9] CERTIFICATS" -ForegroundColor Cyan
$certNPS = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*SRV-DC01*"}
if ($certNPS) { OK "Certificat NPS valide jusqu'au $($certNPS[0].NotAfter.ToString('dd/MM/yyyy'))" }
else { KO "Certificat NPS absent - voir procedure certtmpl.msc" }

# 10. NPS RADIUS
Write-Host "`n[10] NPS RADIUS" -ForegroundColor Cyan
if ((Get-Service IAS).Status -eq "Running") { OK "Service NPS actif" } else { KO "NPS arrete" }
$clients = Get-NpsRadiusClient
if ($clients.Count -eq 3) { OK "3 clients RADIUS (SW, AP, Routeur)" }
else { KO "$($clients.Count) clients RADIUS (attendu 3)" }

# Verifier politiques NPS et VLANs via export XML
netsh nps export filename="C:\NPS_verify_tmp.xml" exportPSK=YES 2>$null
try {
    $xml = [xml](Get-Content "C:\NPS_verify_tmp.xml")
    $profiles = $xml.Root.Children.Microsoft_Internet_Authentication_Service.Children.RadiusProfiles.Children
    @("IRIS_WiFi_Etudiants","IRIS_WiFi_Professeurs","IRIS_WiFi_Administration") | ForEach-Object {
        $p = $profiles.$_
        if ($p) {
            $vlan = $p.Properties.msRADIUSTunnelPrivateGroupId."#text"
            if (-not $vlan) { $vlan = $p.Properties.msRADIUSTunnelPrivateGroupId.InnerText }
            OK "Politique NPS $_ -> VLAN $vlan"
        } else { KO "Politique NPS $_ ABSENTE - configurer nps.msc" }
    }
} catch { KO "Erreur lecture export NPS XML" }
Remove-Item "C:\NPS_verify_tmp.xml" -Force -ErrorAction SilentlyContinue

# 11. POSTE CLIENT
Write-Host "`n[11] POSTES CLIENTS" -ForegroundColor Cyan
$pcs = Get-ADComputer -Filter {Name -ne "SRV-DC01"}
if ($pcs) { $pcs | ForEach-Object { OK "Poste $($_.Name) joint au domaine" } }
else { KO "Aucun poste client joint au domaine" }

# BILAN FINAL
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   BILAN FINAL SRV-DC01" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
if ($erreurs -eq 0) {
    Write-Host "INFRASTRUCTURE IRIS NICE - COMPLETE !" -ForegroundColor Green
    Write-Host "0 erreur detectee." -ForegroundColor Green
} else {
    Write-Host "$erreurs ERREUR(S) - Voir les [KO] ci-dessus" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
