# ============================================================
# SCRIPT 12 - Verification complete poste client
# LANCE    : Sur le POSTE CLIENT, connecte en compte domaine
# RESULTAT : 0 erreur = compte fonctionnel
# ============================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   TEST CLIENT - $env:USERNAME         " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$erreurs = 0
function OK   { param($m) Write-Host "[OK] $m" -ForegroundColor Green }
function KO   { param($m) Write-Host "[KO] $m" -ForegroundColor Red; $script:erreurs++ }
function INFO { param($m) Write-Host "[--] $m" -ForegroundColor Yellow }

# 1. IDENTITE
Write-Host "`n[1] IDENTITE" -ForegroundColor Cyan
OK "Utilisateur : $env:USERNAME"
OK "Domaine     : $env:USERDOMAIN"
if ($env:USERDOMAIN -eq "IRIS") { OK "Connecte au domaine IRIS" } else { KO "Pas sur le domaine IRIS" }

# 2. GROUPES AD
Write-Host "`n[2] GROUPES AD" -ForegroundColor Cyan
$groupes = @()
try {
    $searcher = New-Object DirectoryServices.DirectorySearcher
    $searcher.Filter = "(samaccountname=$env:USERNAME)"
    $searcher.PropertiesToLoad.Add("memberof") | Out-Null
    $result = $searcher.FindOne()
    if ($result) {
        $groupes = $result.Properties["memberof"] | ForEach-Object {
            if ($_ -match "CN=([^,]+)") { $matches[1] }
        }
    }
} catch {}
if ($groupes.Count -gt 0) {
    OK "Groupes AD de l'utilisateur :"
    $groupes | ForEach-Object { INFO "  -> $_" }
} else { KO "Aucun groupe AD trouve" }

# 3. CONNECTIVITE SRV-DC01
Write-Host "`n[3] CONNECTIVITE SRV-DC01" -ForegroundColor Cyan
$smb = Test-NetConnection -ComputerName "192.168.50.10" -Port 445 -ErrorAction SilentlyContinue
if ($smb.TcpTestSucceeded) { OK "SRV-DC01 accessible (SMB port 445)" } else { KO "SRV-DC01 inaccessible" }
$dns = Resolve-DnsName "SRV-DC01.iris.local" -ErrorAction SilentlyContinue
if ($dns) { OK "DNS resout SRV-DC01.iris.local" } else { KO "DNS echec pour SRV-DC01.iris.local" }

# 4. LECTEURS RESEAU
Write-Host "`n[4] LECTEURS RESEAU" -ForegroundColor Cyan
# Forcer la connexion (lazy connection Windows 11)
@("H","S","P","A") | ForEach-Object {
    if (Test-Path "${_}:") { Get-ChildItem "${_}:" -ErrorAction SilentlyContinue | Out-Null }
}
$netUse = net use 2>$null

# H: pour tous
if ($netUse -match "H:.*SRV-DC01") { OK "H: mappe -> \\SRV-DC01\HomeDir`$\$env:USERNAME" }
else { KO "H: non mappe" }

# S: selon groupe
if ($groupes -contains "GRP-Etudiants-SISR") {
    if ($netUse -match "S:.*SISR") { OK "S: mappe -> SISR" } else { KO "S: SISR non mappe" }
}
if ($groupes -contains "GRP-Etudiants-SLAM") {
    if ($netUse -match "S:.*SLAM") { OK "S: mappe -> SLAM" } else { KO "S: SLAM non mappe" }
}
if ($groupes -contains "GRP-Professeurs") {
    if ($netUse -match "S:.*Professeurs") { OK "S: mappe -> Professeurs" } else { KO "S: Professeurs non mappe" }
}
if ($groupes -contains "GRP-Administration") {
    if ($netUse -match "A:.*Administration") { OK "A: mappe -> Administration" } else { KO "A: Administration non mappe" }
}
if ($groupes -contains "GRP-Etudiants-SISR" -or
    $groupes -contains "GRP-Etudiants-SLAM" -or
    $groupes -contains "GRP-Professeurs") {
    if ($netUse -match "P:.*Commun") { OK "P: mappe -> Commun" } else { KO "P: Commun non mappe" }
}

# 5. ACCES AUX PARTAGES
Write-Host "`n[5] ACCES AUX PARTAGES" -ForegroundColor Cyan
try {
    "test_$env:USERNAME" | Out-File "H:\test_iris_acces.txt" -ErrorAction Stop
    Remove-Item "H:\test_iris_acces.txt" -Force
    OK "H: lecture/ecriture OK"
} catch { KO "H: acces refuse en ecriture" }
if (Test-Path "S:") { if (Test-Path "S:\") { OK "S: accessible en lecture" } else { KO "S: inaccessible" } }
if (Test-Path "P:") { if (Test-Path "P:\") { OK "P: accessible en lecture" } else { KO "P: inaccessible" } }

# 6. GPO RESTRICTIONS
Write-Host "`n[6] GPO RESTRICTIONS" -ForegroundColor Cyan
if ($groupes -contains "GRP-Etudiants-SISR" -or $groupes -contains "GRP-Etudiants-SLAM") {
    $noCP  = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoControlPanel" -ErrorAction SilentlyContinue).NoControlPanel
    $noCmd = (Get-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\System" -Name "DisableCMD" -ErrorAction SilentlyContinue).DisableCMD
    $noReg = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "DisableRegistryTools" -ErrorAction SilentlyContinue).DisableRegistryTools
    if ($noCP  -eq 1) { OK "Panneau config bloque (GPO Restrictions)" } else { KO "Panneau config NON bloque" }
    if ($noCmd -eq 1) { OK "CMD bloquee (GPO Restrictions)" }           else { KO "CMD NON bloquee" }
    if ($noReg -eq 1) { OK "Regedit bloque (GPO Restrictions)" }        else { KO "Regedit NON bloque" }
} elseif ($groupes -contains "GRP-Professeurs") {
    $noCP = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoControlPanel" -ErrorAction SilentlyContinue).NoControlPanel
    if ($noCP -ne 1) { OK "Panneau config accessible (prof - GPO Profs-Acces)" }
    else { KO "Panneau config bloque pour un professeur" }
    INFO "Restrictions etudiants non appliquees (normal pour un prof)"
} else {
    INFO "Compte non etudiant/prof - restrictions non verifiees"
}

# 7. SECURITE BASELINE
Write-Host "`n[7] SECURITE BASELINE" -ForegroundColor Cyan
$scr    = (Get-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop" -Name "ScreenSaveActive" -ErrorAction SilentlyContinue).ScreenSaveActive
$scrPwd = (Get-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop" -Name "ScreenSaverIsSecure" -ErrorAction SilentlyContinue).ScreenSaverIsSecure
if ($scr    -eq "1") { OK "Ecran de veille active (GPO Baseline)" }           else { KO "Ecran de veille NON active" }
if ($scrPwd -eq "1") { OK "Ecran de veille protege par mot de passe" }        else { KO "Ecran de veille sans mot de passe" }

# BILAN
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   BILAN - $env:USERNAME" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
if ($erreurs -eq 0) {
    Write-Host "TOUT EST OK POUR $($env:USERNAME.ToUpper()) !" -ForegroundColor Green
} else {
    Write-Host "$erreurs ERREUR(S) DETECTEE(S)" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
