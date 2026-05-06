# ============================================================
# SCRIPT 05 - Creation des 21 comptes utilisateurs
# ORDRE    : Apres script 04
# FORMAT   : login = 1ere lettre prenom + nom (minuscules, sans accents)
# MDP      : Iris@Etudiant2026! (sans expiration)
# ============================================================

Write-Host "=== [05] Creation des 21 comptes utilisateurs ===" -ForegroundColor Cyan

$base = "OU=IRIS-Nice,DC=iris,DC=local"
$mdp  = ConvertTo-SecureString "Iris@Etudiant2026!" -AsPlainText -Force

function New-IRISUser {
    param($Prenom, $Nom, $OU, $Groupe)
    # Generer le login : 1ere lettre prenom + nom, minuscules, sans accents
    $sansAccents = ($Prenom.Substring(0,1) + $Nom).ToLower() `
        -replace '[éèêë]','e' -replace '[àâä]','a' -replace '[îï]','i' `
        -replace '[ôö]','o'   -replace '[ùûü]','u' -replace '[ç]','c' `
        -replace '[\s\-]',''
    $login    = $sansAccents
    $fullname = "$Prenom $Nom"

    if (Get-ADUser -Filter {SamAccountName -eq $login} -ErrorAction SilentlyContinue) {
        Write-Host "[SKIP] $fullname ($login) existe deja" -ForegroundColor Yellow
        return
    }
    New-ADUser `
        -Name                  $fullname `
        -GivenName             $Prenom `
        -Surname               $Nom `
        -SamAccountName        $login `
        -UserPrincipalName     "$login@iris.local" `
        -Path                  $OU `
        -AccountPassword       $mdp `
        -Enabled               $true `
        -ChangePasswordAtLogon $false `
        -PasswordNeverExpires  $true
    Add-ADGroupMember -Identity $Groupe -Members $login -ErrorAction SilentlyContinue
    Write-Host "[OK] $fullname ($login) --> $Groupe" -ForegroundColor Green
}

# PROFESSEURS (2)
Write-Host "`n-- Professeurs --" -ForegroundColor Yellow
$ouProfs = "OU=Professeurs,$base"
New-IRISUser "Yan"      "Bourquard" $ouProfs "GRP-Professeurs"
New-IRISUser "Terrence" "Ferrut"    $ouProfs "GRP-Professeurs"
Add-ADGroupMember -Identity "GRP-WiFi-Profs" -Members "ybourquard","tferrut" -ErrorAction SilentlyContinue

# ETUDIANTS SISR (10)
Write-Host "`n-- Etudiants SISR --" -ForegroundColor Yellow
$ouSISR = "OU=SISR,OU=Etudiants,$base"
New-IRISUser "Said"    "Ahmed Moussa" $ouSISR "GRP-Etudiants-SISR"
New-IRISUser "Vincent" "Andreo"       $ouSISR "GRP-Etudiants-SISR"
New-IRISUser "Remi"    "Bears"        $ouSISR "GRP-Etudiants-SISR"
New-IRISUser "Nedj"    "Belloum"      $ouSISR "GRP-Etudiants-SISR"
New-IRISUser "Louka"   "Lavenir"      $ouSISR "GRP-Etudiants-SISR"
New-IRISUser "Julien"  "Marcucci"     $ouSISR "GRP-Etudiants-SISR"
New-IRISUser "Tiago"   "Quenette"     $ouSISR "GRP-Etudiants-SISR"
New-IRISUser "Edib"    "Saoud"        $ouSISR "GRP-Etudiants-SISR"
New-IRISUser "Omar"    "Talibi"       $ouSISR "GRP-Etudiants-SISR"
New-IRISUser "Hendrik" "Thouvenin"    $ouSISR "GRP-Etudiants-SISR"
# Ajouter SISR dans groupe WiFi
Get-ADGroupMember "GRP-Etudiants-SISR" | ForEach-Object {
    Add-ADGroupMember -Identity "GRP-WiFi-SISR" -Members $_.SamAccountName -ErrorAction SilentlyContinue
}

# ETUDIANTS SLAM (5)
Write-Host "`n-- Etudiants SLAM --" -ForegroundColor Yellow
$ouSLAM = "OU=SLAM,OU=Etudiants,$base"
New-IRISUser "Yanis"   "Adidi"     $ouSLAM "GRP-Etudiants-SLAM"
New-IRISUser "Mohamed" "Boukhatem" $ouSLAM "GRP-Etudiants-SLAM"
New-IRISUser "Klaudia" "Juhasz"    $ouSLAM "GRP-Etudiants-SLAM"
New-IRISUser "Denys"   "Lyulchak"  $ouSLAM "GRP-Etudiants-SLAM"
New-IRISUser "Kevin"   "Senasson"  $ouSLAM "GRP-Etudiants-SLAM"
# Ajouter SLAM dans groupe WiFi SISR (meme VLAN 10)
Get-ADGroupMember "GRP-Etudiants-SLAM" | ForEach-Object {
    Add-ADGroupMember -Identity "GRP-WiFi-SISR" -Members $_.SamAccountName -ErrorAction SilentlyContinue
}

# ADMINISTRATION (3)
Write-Host "`n-- Administration --" -ForegroundColor Yellow
$ouAdmin = "OU=Administration,$base"
New-IRISUser "Marie"  "Dupont"  $ouAdmin "GRP-Administration"
New-IRISUser "Jean"   "Martin"  $ouAdmin "GRP-Administration"
New-IRISUser "Sophie" "Bernard" $ouAdmin "GRP-Administration"
Add-ADGroupMember -Identity "GRP-WiFi-Admin" -Members "mdupont","jmartin","sbernard" -ErrorAction SilentlyContinue

# INFORMATIQUE (1)
Write-Host "`n-- Informatique --" -ForegroundColor Yellow
$ouIT = "OU=Informatique,$base"
New-IRISUser "Admin" "IRIS" $ouIT "GRP-Informatique"
Add-ADGroupMember -Identity "GRP-VPN-Users" -Members "airis" -ErrorAction SilentlyContinue

Write-Host "`n=== VERIFICATIONS ===" -ForegroundColor Cyan
$total = (Get-ADUser -Filter * -SearchBase $base | Measure-Object).Count
Write-Host "Total comptes crees : $total (attendu 21)"
Write-Host "[OK] Script 05 termine - Lancez le script 06" -ForegroundColor Green
