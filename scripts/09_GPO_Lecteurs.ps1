# ============================================================
# SCRIPT 09 - GPO Preferences - Mappages lecteurs reseau
# ORDRE    : Apres script 08
# GENERE   : Drives.xml directement dans SYSVOL
# LECTEURS : H: tous / S: selon filiere / P: Commun / A: Admin
# CIBLAGE  : par SID groupe AD (robuste, independant du nom)
# ============================================================

Write-Host "=== [09] GPO Preferences - Lecteurs reseau ===" -ForegroundColor Cyan

$gpoId   = (Get-GPO -Name "IRIS-LecteursReseau").Id.ToString()
$gpoPath = "C:\Windows\SYSVOL\sysvol\iris.local\Policies\{$gpoId}\User\Preferences\Drives"
New-Item -ItemType Directory -Path $gpoPath -Force | Out-Null

# Recuperer les SIDs des groupes
$sidSISR  = (Get-ADGroup "GRP-Etudiants-SISR").SID.Value
$sidSLAM  = (Get-ADGroup "GRP-Etudiants-SLAM").SID.Value
$sidProfs = (Get-ADGroup "GRP-Professeurs").SID.Value
$sidAdmin = (Get-ADGroup "GRP-Administration").SID.Value

function New-DriveGuid { return [System.Guid]::NewGuid().ToString().ToUpper() }

$guidH      = New-DriveGuid
$guidSISR   = New-DriveGuid
$guidSLAM   = New-DriveGuid
$guidProfs  = New-DriveGuid
$guidAdmin  = New-DriveGuid
$guidCommun = New-DriveGuid

$xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<Drives clsid="{8FDDCC1A-0C3C-43cd-A6B4-71A6DF20DA8C}">

  <!-- H: HomeDir personnel pour tous les utilisateurs -->
  <Drive clsid="{935D1B74-9CB8-4e3c-9914-7DD559B7A417}"
         name="H:" status="H:" image="2" changed="2026-04-24 10:00:00"
         uid="{$guidH}" bypassErrors="1">
    <Properties action="U" thisDrive="SHOW" allDrives="SHOW"
                userName="" path="\\SRV-DC01\HomeDir`$\%USERNAME%"
                label="HomeDir" persistent="1" useLetter="1" letter="H"/>
  </Drive>

  <!-- S: SISR - uniquement GRP-Etudiants-SISR -->
  <Drive clsid="{935D1B74-9CB8-4e3c-9914-7DD559B7A417}"
         name="S:" status="S:" image="2" changed="2026-04-24 10:00:00"
         uid="{$guidSISR}" bypassErrors="1">
    <Properties action="U" thisDrive="SHOW" allDrives="SHOW"
                userName="" path="\\SRV-DC01\SISR"
                label="SISR" persistent="1" useLetter="1" letter="S"/>
    <Filters>
      <FilterGroup bool="AND" not="0" name="IRIS\GRP-Etudiants-SISR"
                   sid="$sidSISR" userContext="1" primaryGroup="0" localGroup="0"/>
    </Filters>
  </Drive>

  <!-- S: SLAM - uniquement GRP-Etudiants-SLAM -->
  <Drive clsid="{935D1B74-9CB8-4e3c-9914-7DD559B7A417}"
         name="S:" status="S:" image="2" changed="2026-04-24 10:00:00"
         uid="{$guidSLAM}" bypassErrors="1">
    <Properties action="U" thisDrive="SHOW" allDrives="SHOW"
                userName="" path="\\SRV-DC01\SLAM"
                label="SLAM" persistent="1" useLetter="1" letter="S"/>
    <Filters>
      <FilterGroup bool="AND" not="0" name="IRIS\GRP-Etudiants-SLAM"
                   sid="$sidSLAM" userContext="1" primaryGroup="0" localGroup="0"/>
    </Filters>
  </Drive>

  <!-- S: Professeurs - uniquement GRP-Professeurs -->
  <Drive clsid="{935D1B74-9CB8-4e3c-9914-7DD559B7A417}"
         name="S:" status="S:" image="2" changed="2026-04-24 10:00:00"
         uid="{$guidProfs}" bypassErrors="1">
    <Properties action="U" thisDrive="SHOW" allDrives="SHOW"
                userName="" path="\\SRV-DC01\Professeurs"
                label="Professeurs" persistent="1" useLetter="1" letter="S"/>
    <Filters>
      <FilterGroup bool="AND" not="0" name="IRIS\GRP-Professeurs"
                   sid="$sidProfs" userContext="1" primaryGroup="0" localGroup="0"/>
    </Filters>
  </Drive>

  <!-- A: Administration - uniquement GRP-Administration -->
  <Drive clsid="{935D1B74-9CB8-4e3c-9914-7DD559B7A417}"
         name="A:" status="A:" image="2" changed="2026-04-24 10:00:00"
         uid="{$guidAdmin}" bypassErrors="1">
    <Properties action="U" thisDrive="SHOW" allDrives="SHOW"
                userName="" path="\\SRV-DC01\Administration"
                label="Administration" persistent="1" useLetter="1" letter="A"/>
    <Filters>
      <FilterGroup bool="AND" not="0" name="IRIS\GRP-Administration"
                   sid="$sidAdmin" userContext="1" primaryGroup="0" localGroup="0"/>
    </Filters>
  </Drive>

  <!-- P: Commun - SISR OU SLAM OU Professeurs -->
  <Drive clsid="{935D1B74-9CB8-4e3c-9914-7DD559B7A417}"
         name="P:" status="P:" image="2" changed="2026-04-24 10:00:00"
         uid="{$guidCommun}" bypassErrors="1">
    <Properties action="U" thisDrive="SHOW" allDrives="SHOW"
                userName="" path="\\SRV-DC01\Commun"
                label="Commun" persistent="1" useLetter="1" letter="P"/>
    <Filters>
      <FilterGroup bool="AND" not="0" name="IRIS\GRP-Etudiants-SISR"
                   sid="$sidSISR" userContext="1" primaryGroup="0" localGroup="0"/>
      <FilterGroup bool="OR" not="0" name="IRIS\GRP-Etudiants-SLAM"
                   sid="$sidSLAM" userContext="1" primaryGroup="0" localGroup="0"/>
      <FilterGroup bool="OR" not="0" name="IRIS\GRP-Professeurs"
                   sid="$sidProfs" userContext="1" primaryGroup="0" localGroup="0"/>
    </Filters>
  </Drive>

</Drives>
"@

$xml | Out-File -FilePath "$gpoPath\Drives.xml" -Encoding UTF8 -Force
Write-Host "[OK] Drives.xml cree dans SYSVOL GPO IRIS-LecteursReseau" -ForegroundColor Green

# Copier dans /gpo/ pour archivage
Copy-Item "$gpoPath\Drives.xml" "C:\Temp\Drives_backup.xml" -ErrorAction SilentlyContinue

gpupdate /force | Out-Null
Write-Host "[OK] GPO appliquees (gpupdate /force)" -ForegroundColor Green

Write-Host "`n=== VERIFICATIONS ===" -ForegroundColor Cyan
$drives = [xml](Get-Content "$gpoPath\Drives.xml")
Write-Host "Mappages configures : $($drives.Drives.Drive.Count)"
$drives.Drives.Drive | ForEach-Object {
    Write-Host "  $($_.name) -> $($_.Properties.path)" -ForegroundColor Cyan
}
Write-Host "[OK] Script 09 termine - Lancez le script 10" -ForegroundColor Green
