# ============================================================
# SCRIPT 10b - NPS Post-Reboot - Certificat + verification
# ORDRE    : Apres redemarrage suivant script 10
#            ET apres configuration certtmpl.msc
# ============================================================

Write-Host "=== [10b] NPS Post-Reboot ===" -ForegroundColor Cyan

# Verifier template
$templates = Get-CATemplate | Select-Object -ExpandProperty Name
if ($templates -contains "RASAndIASServer") {
    Write-Host "[OK] Template RASAndIASServer present sur la CA" -ForegroundColor Green
} else {
    Write-Host "[WARN] Template manquant - re-activation..." -ForegroundColor Yellow
    certutil -SetCATemplates +RASAndIASServer | Out-Null
    Write-Host "[OK] Template rajoute - attendez 1 minute puis relancez ce script" -ForegroundColor Yellow
}

# Tenter d'obtenir le certificat automatiquement
Write-Host "`n-- Demande certificat NPS --" -ForegroundColor Yellow
$cert = Get-Certificate -Template "RASAndIASServer" `
    -CertStoreLocation "Cert:\LocalMachine\My" -ErrorAction SilentlyContinue

if ($cert) {
    Write-Host "[OK] Certificat NPS obtenu automatiquement !" -ForegroundColor Green
    Write-Host "     Subject    : $($cert.Certificate.Subject)"
    Write-Host "     Thumbprint : $($cert.Certificate.Thumbprint)"
    Write-Host "     Expire le  : $($cert.Certificate.NotAfter)"
} else {
    Write-Host "[WARN] Certificat non obtenu automatiquement." -ForegroundColor Yellow
    Write-Host "       Suivre la procedure manuelle dans 02_Procedure_Installation_RP01.md" -ForegroundColor Yellow
    Write-Host "       mmc -> Certificats Ordinateur -> Personnel -> Demander nouveau certificat -> RAS and IAS Server" -ForegroundColor Yellow
}

# Etat NPS
Write-Host "`n-- Etat NPS --" -ForegroundColor Yellow
Get-Service IAS | Select-Object Name, Status, StartType | Format-Table -AutoSize
Get-NpsRadiusClient | Select-Object Name, Address, Enabled | Format-Table -AutoSize

Write-Host "`n-- Certificats machine (Personal store) --" -ForegroundColor Yellow
Get-ChildItem Cert:\LocalMachine\My | Select-Object Subject, NotAfter | Format-Table -AutoSize

Write-Host "`n[IMPORTANT] Configurer maintenant dans nps.msc :" -ForegroundColor Red
Write-Host "  Strategies reseau -> Nouveau (3 politiques) :" -ForegroundColor Yellow
Write-Host "  1. IRIS-WiFi-Etudiants   | Condition: GRP-WiFi-SISR  | Acces: Accorde | PEAP+MSCHAPv2 | VLAN 10" -ForegroundColor Yellow
Write-Host "  2. IRIS-WiFi-Professeurs  | Condition: GRP-WiFi-Profs | Acces: Accorde | PEAP+MSCHAPv2 | VLAN 20" -ForegroundColor Yellow
Write-Host "  3. IRIS-WiFi-Administration | Condition: GRP-WiFi-Admin | Acces: Accorde | PEAP+MSCHAPv2 | VLAN 30" -ForegroundColor Yellow
Write-Host "  Pour chaque politique -> onglet Parametres -> Standard -> Ajouter :" -ForegroundColor Yellow
Write-Host "    Tunnel-Type         = Virtual LANs (valeur 13)" -ForegroundColor Yellow
Write-Host "    Tunnel-Medium-Type  = 802 (valeur 6)" -ForegroundColor Yellow
Write-Host "    Tunnel-Pvt-Group-ID = 10 / 20 / 30" -ForegroundColor Yellow
Write-Host "[OK] Script 10b termine - Lancez le script 11 apres configuration nps.msc" -ForegroundColor Green
