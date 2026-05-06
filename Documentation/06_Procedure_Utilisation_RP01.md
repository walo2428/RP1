# 06 — Procédure d'utilisation quotidienne RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Connexion utilisateur

### Sur un poste joint au domaine

A l'écran de connexion Windows 11, cliquer **Autre utilisateur** et saisir :
```
Nom d'utilisateur : IRIS\vandreo
Mot de passe      : (voir credentials)
```

### Lecteurs mappés automatiquement

Après connexion, les lecteurs suivants apparaissent dans l'Explorateur :

| Lecteur | Chemin | Qui y a accès |
|---------|--------|--------------|
| H: | \\SRV-DC01\HomeDir$\%USERNAME% | Tout le monde (répertoire personnel) |
| S: | \\SRV-DC01\SISR | Etudiants SISR uniquement |
| S: | \\SRV-DC01\SLAM | Etudiants SLAM uniquement |
| S: | \\SRV-DC01\Professeurs | Professeurs uniquement |
| A: | \\SRV-DC01\Administration | Administratifs uniquement |
| P: | \\SRV-DC01\Commun | Etudiants + Professeurs |

> Les lecteurs peuvent apparaître "Déconnectés" au premier logon — c'est normal. Ils se connectent au premier accès (clic dessus).

---

## 2. Gestion des comptes utilisateurs

### Créer un nouveau compte

```powershell
# Sur SRV-DC01 - PowerShell Admin
$mdp = ConvertTo-SecureString "Iris@Etudiant2026!" -AsPlainText -Force

New-ADUser `
    -Name              "Prenom Nom" `
    -GivenName         "Prenom" `
    -Surname           "Nom" `
    -SamAccountName    "plogin" `
    -UserPrincipalName "plogin@iris.local" `
    -Path              "OU=SISR,OU=Etudiants,OU=IRIS-Nice,DC=iris,DC=local" `
    -AccountPassword   $mdp `
    -Enabled           $true `
    -ChangePasswordAtLogon $false `
    -PasswordNeverExpires  $true

# Ajouter aux groupes
Add-ADGroupMember -Identity "GRP-Etudiants-SISR" -Members "plogin"
Add-ADGroupMember -Identity "GRP-WiFi-SISR"      -Members "plogin"

# Créer le HomeDir
New-Item -ItemType Directory -Path "C:\HomeDir\plogin" -Force
$acl = Get-Acl "C:\HomeDir\plogin"
$acl.SetAccessRuleProtection($true, $false)
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
    "IRIS\plogin","Modify","ContainerInherit,ObjectInherit","None","Allow")))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule(
    "Administrateur","FullControl","ContainerInherit,ObjectInherit","None","Allow")))
Set-Acl "C:\HomeDir\plogin" $acl
Set-ADUser "plogin" -HomeDirectory "\\SRV-DC01\HomeDir$\plogin" -HomeDrive "H:"

Write-Host "[OK] Compte plogin cree"
```

### Désactiver un compte

```powershell
Disable-ADAccount -Identity "plogin"
```

### Réinitialiser un mot de passe

```powershell
$newMdp = ConvertTo-SecureString "NouveauMdp2026!" -AsPlainText -Force
Set-ADAccountPassword -Identity "plogin" -NewPassword $newMdp -Reset
```

### Déverrouiller un compte bloqué

```powershell
Unlock-ADAccount -Identity "plogin"
```

### Voir les membres d'un groupe

```powershell
Get-ADGroupMember "GRP-Etudiants-SISR" | Select-Object Name, SamAccountName | Format-Table
```

---

## 3. Gestion DHCP

### Voir les baux actifs par VLAN

```powershell
Get-DhcpServerv4Lease -ScopeId "192.168.10.0" |
    Select-Object IPAddress, HostName, ClientId, LeaseExpiryTime | Format-Table
```

### Ajouter une réservation IP fixe (imprimante, équipement réseau)

```powershell
Add-DhcpServerv4Reservation `
    -ScopeId     "192.168.50.0" `
    -IPAddress   "192.168.50.100" `
    -ClientId    "AA-BB-CC-DD-EE-FF" `
    -Description "Imprimante salle TP"
```

### Voir l'état des scopes

```powershell
Get-DhcpServerv4Scope | Select-Object Name, ScopeId, StartRange, EndRange, State | Format-Table
```

---

## 4. Gestion DNS

### Ajouter un enregistrement A

```powershell
Add-DnsServerResourceRecordA -ZoneName "iris.local" `
    -Name "nouveau-poste" -IPv4Address "192.168.10.55"
```

### Vider le cache DNS du serveur

```powershell
Clear-DnsServerCache -Force
```

### Vérifier la résolution d'un nom

```powershell
Resolve-DnsName "SRV-DC01.iris.local"
nslookup SRV-DC01.iris.local 192.168.50.10
```

---

## 5. Gestion des partages SMB

### Voir les connexions actives aux partages

```powershell
Get-SmbSession | Select-Object ClientComputerName, ClientUserName, NumOpens | Format-Table
```

### Voir les fichiers ouverts

```powershell
Get-SmbOpenFile | Select-Object Path, ClientUserName | Format-Table
```

### Forcer la déconnexion d'un utilisateur

```powershell
Get-SmbSession | Where-Object {$_.ClientUserName -like "*nbelloum*"} | Close-SmbSession -Force
```

---

## 6. Gestion des GPO

### Forcer l'application des GPO sur le serveur

```powershell
gpupdate /force
```

### Voir les GPO appliquées à un utilisateur (sur le poste client)

```powershell
gpresult /r
# Rapport HTML détaillé
gpresult /h C:\rapport_gpo.html && Start-Process C:\rapport_gpo.html
```

### Voir les liens GPO d'une OU

```powershell
Get-GPInheritance -Target "OU=IRIS-Nice,DC=iris,DC=local" |
    Select-Object -ExpandProperty GpoLinks | Format-Table DisplayName, Enabled, Order
```

---

## 7. Surveillance et logs

### Connexions réussies / échouées

```powershell
# Echecs de connexion (mauvais mot de passe, compte bloqué)
Get-EventLog -LogName Security -InstanceId 4625 -Newest 20 |
    Select-Object TimeGenerated, Message | Format-List

# Connexions réussies
Get-EventLog -LogName Security -InstanceId 4624 -Newest 20 |
    Select-Object TimeGenerated | Format-Table
```

### Dernière connexion d'un compte

```powershell
Get-ADUser nbelloum -Properties LastLogonDate, BadLogonCount, LockedOut |
    Select-Object Name, LastLogonDate, BadLogonCount, LockedOut
```

### Etat de tous les services

```powershell
@("ADWS","DNS","DHCPServer","IAS","CertSvc","Netlogon","W32Time") | ForEach-Object {
    $s = Get-Service $_ -ErrorAction SilentlyContinue
    if ($s) {
        $color = if ($s.Status -eq "Running") {"Green"} else {"Red"}
        Write-Host "$_ : $($s.Status)" -ForegroundColor $color
    }
}
```

---

## 8. Dépannage courant

### Lecteur réseau non mappé après connexion

```powershell
# Sur le poste client - forcer le mappage
gpupdate /force
net use H: \\SRV-DC01\HomeDir$\%USERNAME% /persistent:yes
net use S: \\SRV-DC01\SISR /persistent:yes
```

### Poste client ne trouve pas le domaine iris.local

```powershell
# Vérifier DNS du poste
Get-DnsClientServerAddress
# Si pas 192.168.50.10 :
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.50.10"
ipconfig /flushdns
nslookup iris.local
```

### GPO non appliquées

```powershell
# Serveur
gpupdate /force
# Poste client
gpupdate /force /boot   # Si paramètres ordinateur
gpupdate /force /logoff # Si paramètres utilisateur
```

### Service NPS ne répond pas

```powershell
Restart-Service IAS
Get-Service IAS | Select-Object Name, Status
# Vérifier le certificat
Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*SRV-DC01*"}
```

### Vérifier la CA

```powershell
certutil -ping
certutil -cainfo
Get-CATemplate | Select-Object Name | Format-Table
```
