# ============================================================
# SCRIPT 07 - Partages SMB + ACL NTFS + 21 Home Directories
# ORDRE    : Apres script 05 (comptes necessaires)
# CREE     : 6 partages + 21 HomeDirs + lecteur H: dans AD
# ============================================================

Write-Host "=== [07] Partages SMB + HomeDirs ===" -ForegroundColor Cyan

$base = "OU=IRIS-Nice,DC=iris,DC=local"

# Creer les dossiers
foreach ($d in @(
    "C:\Partages\Etudiants-SISR",
    "C:\Partages\Etudiants-SLAM",
    "C:\Partages\Professeurs",
    "C:\Partages\Administration",
    "C:\Partages\Commun",
    "C:\HomeDir"
)) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}
Write-Host "[OK] Dossiers partages crees" -ForegroundColor Green

function New-PartageSecurise {
    param($Nom, $Chemin, $Groupe, $Droit = "Change")
    # Creer le partage
    New-SmbShare -Name $Nom -Path $Chemin -FullAccess "Administrateur" -ErrorAction SilentlyContinue
    Grant-SmbShareAccess -Name $Nom -AccountName "IRIS\$Groupe" -AccessRight $Droit -Force
    Revoke-SmbShareAccess -Name $Nom -AccountName "Tout le monde" -Force -ErrorAction SilentlyContinue
    # ACL NTFS
    $acl = Get-Acl $Chemin
    $acl.SetAccessRuleProtection($true, $false)
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
        "IRIS\$Groupe","Modify","ContainerInherit,ObjectInherit","None","Allow")))
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Administrateur","FullControl","ContainerInherit,ObjectInherit","None","Allow")))
    Set-Acl $Chemin $acl
}

New-PartageSecurise "SISR"           "C:\Partages\Etudiants-SISR" "GRP-Etudiants-SISR"
Write-Host "[OK] Partage SISR (S: - etudiants SISR)" -ForegroundColor Green

New-PartageSecurise "SLAM"           "C:\Partages\Etudiants-SLAM" "GRP-Etudiants-SLAM"
Write-Host "[OK] Partage SLAM (S: - etudiants SLAM)" -ForegroundColor Green

New-PartageSecurise "Professeurs"    "C:\Partages\Professeurs"    "GRP-Professeurs"
Write-Host "[OK] Partage Professeurs (S: - profs)" -ForegroundColor Green

New-PartageSecurise "Administration" "C:\Partages\Administration" "GRP-Administration"
Write-Host "[OK] Partage Administration (A:)" -ForegroundColor Green

# Partage Commun : etudiants=lecture, profs=modification
New-SmbShare -Name "Commun" -Path "C:\Partages\Commun" -FullAccess "Administrateur" -ErrorAction SilentlyContinue
Grant-SmbShareAccess -Name "Commun" -AccountName "IRIS\GRP-Etudiants-SISR" -AccessRight Read   -Force
Grant-SmbShareAccess -Name "Commun" -AccountName "IRIS\GRP-Etudiants-SLAM" -AccessRight Read   -Force
Grant-SmbShareAccess -Name "Commun" -AccountName "IRIS\GRP-Professeurs"    -AccessRight Change -Force
Revoke-SmbShareAccess -Name "Commun" -AccountName "Tout le monde" -Force -ErrorAction SilentlyContinue
$acl = Get-Acl "C:\Partages\Commun"
$acl.SetAccessRuleProtection($true, $false)
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("IRIS\GRP-Etudiants-SISR","Read","ContainerInherit,ObjectInherit","None","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("IRIS\GRP-Etudiants-SLAM","Read","ContainerInherit,ObjectInherit","None","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("IRIS\GRP-Professeurs","Modify","ContainerInherit,ObjectInherit","None","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("Administrateur","FullControl","ContainerInherit,ObjectInherit","None","Allow")))
Set-Acl "C:\Partages\Commun" $acl
Write-Host "[OK] Partage Commun (P: - etu lecture / profs modif)" -ForegroundColor Green

# HomeDir$ (cache - $ rend invisible dans explorateur)
New-SmbShare -Name "HomeDir$" -Path "C:\HomeDir" -FullAccess "Administrateur" -ErrorAction SilentlyContinue
Grant-SmbShareAccess -Name "HomeDir$" -AccountName "IRIS\Utilisateurs du domaine" -AccessRight Change -Force
Write-Host "[OK] Partage HomeDir$ cree et accessible aux utilisateurs du domaine" -ForegroundColor Green

# Creer les 21 repertoires personnels
Write-Host "`n-- Creation des 21 HomeDirs --" -ForegroundColor Yellow
$utilisateurs = Get-ADUser -Filter * -SearchBase $base

foreach ($user in $utilisateurs) {
    $homeDir = "C:\HomeDir\$($user.SamAccountName)"
    New-Item -ItemType Directory -Path $homeDir -Force | Out-Null

    $acl = Get-Acl $homeDir
    $acl.SetAccessRuleProtection($true, $false)
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
        "IRIS\$($user.SamAccountName)","Modify","ContainerInherit,ObjectInherit","None","Allow")))
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Administrateur","FullControl","ContainerInherit,ObjectInherit","None","Allow")))
    Set-Acl $homeDir $acl

    # Associer H: au compte AD
    Set-ADUser $user.SamAccountName `
        -HomeDirectory "\\SRV-DC01\HomeDir$\$($user.SamAccountName)" `
        -HomeDrive "H:"
    Write-Host "[OK] HomeDir $($user.SamAccountName)" -ForegroundColor Green
}

Write-Host "`n=== VERIFICATIONS ===" -ForegroundColor Cyan
Get-SmbShare | Where-Object {$_.Name -notin @("ADMIN$","C$","IPC$")} | Select-Object Name, Path | Format-Table -AutoSize
Write-Host "HomeDirs presents : $((Get-ChildItem C:\HomeDir).Count) (attendu 21)"
Write-Host "[OK] Script 07 termine - Lancez le script 08" -ForegroundColor Green
