# ============================================================
# SCRIPT 04 - Creation OUs + Groupes de securite AD
# ORDRE    : Apres script 03
# CREE     : 9 OUs + 9 groupes de securite
# ============================================================

Write-Host "=== [04] Creation OUs et Groupes ===" -ForegroundColor Cyan

$dom  = "DC=iris,DC=local"
$base = "OU=IRIS-Nice,$dom"

# OU racine
New-ADOrganizationalUnit -Name "IRIS-Nice" -Path $dom `
    -ProtectedFromAccidentalDeletion $true -ErrorAction SilentlyContinue
Write-Host "[OK] OU IRIS-Nice" -ForegroundColor Green

# OUs principales
foreach ($ou in @("Etudiants","Professeurs","Administration","Informatique","Groupes","Ordinateurs-IRIS")) {
    New-ADOrganizationalUnit -Name $ou -Path $base `
        -ProtectedFromAccidentalDeletion $true -ErrorAction SilentlyContinue
    Write-Host "[OK] OU $ou" -ForegroundColor Green
}

# Sous-OUs etudiants
New-ADOrganizationalUnit -Name "SISR" -Path "OU=Etudiants,$base" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name "SLAM" -Path "OU=Etudiants,$base" -ErrorAction SilentlyContinue
Write-Host "[OK] OUs SISR et SLAM" -ForegroundColor Green

# 9 groupes de securite
$groupes = @(
    @{Name="GRP-Etudiants-SISR"; Desc="Etudiants filiere SISR - partage SISR"},
    @{Name="GRP-Etudiants-SLAM"; Desc="Etudiants filiere SLAM - partage SLAM"},
    @{Name="GRP-Professeurs";    Desc="Professeurs - partage Professeurs"},
    @{Name="GRP-Administration"; Desc="Personnel administratif - partage Administration"},
    @{Name="GRP-Informatique";   Desc="Equipe IT - acces complet"},
    @{Name="GRP-VPN-Users";      Desc="Utilisateurs VPN autorises"},
    @{Name="GRP-WiFi-SISR";      Desc="Auth WiFi 802.1X -> VLAN 10"},
    @{Name="GRP-WiFi-Profs";     Desc="Auth WiFi 802.1X -> VLAN 20"},
    @{Name="GRP-WiFi-Admin";     Desc="Auth WiFi 802.1X -> VLAN 30"}
)

foreach ($g in $groupes) {
    New-ADGroup -Name $g.Name -GroupScope Global -GroupCategory Security `
        -Path "OU=Groupes,$base" -Description $g.Desc -ErrorAction SilentlyContinue
    Write-Host "[OK] Groupe $($g.Name)" -ForegroundColor Green
}

Write-Host "`n=== VERIFICATIONS ===" -ForegroundColor Cyan
Get-ADOrganizationalUnit -Filter * | Where-Object {$_.DistinguishedName -like "*IRIS-Nice*"} |
    Select-Object Name | Format-Table -AutoSize
Get-ADGroup -Filter {Name -like "GRP-*"} | Select-Object Name | Format-Table -AutoSize
Write-Host "[OK] Script 04 termine - Lancez le script 05" -ForegroundColor Green
