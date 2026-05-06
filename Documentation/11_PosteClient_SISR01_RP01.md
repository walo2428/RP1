# 11 — Poste client SISR-01 — Configuration et jonction domaine RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Configuration du poste client

### Spécifications VirtualBox

| Paramètre | Valeur |
|-----------|--------|
| Nom VM | SISR-01 |
| OS | Windows 11 Pro (22H2 ou supérieur) |
| RAM | 4 Go |
| Disque | 50 Go |
| Processeurs | 2 vCPU |
| Carte réseau | Réseau hôte uniquement (Host-Only — même réseau que SRV-DC01) |

### Adressage réseau (DHCP — VLAN 50 Management)

| Paramètre | Valeur |
|-----------|--------|
| IP (DHCP) | 192.168.50.x (scope VLAN Management, ou IP fixe si nécessaire) |
| DNS | 192.168.50.10 (SRV-DC01) |
| Passerelle | 192.168.50.254 (R1-IRIS) |

> En lab VirtualBox sans switch Cisco, le poste est directement sur le réseau Host-Only 192.168.50.0/24 et reçoit une IP du scope VLAN 50 (pas de DHCP — IP fixe configurée manuellement).

### Prérequis avant jonction

1. Le DNS du poste doit pointer vers **192.168.50.10**
2. SRV-DC01 doit être démarré et accessible
3. `ping 192.168.50.10` doit répondre depuis le poste
4. `nslookup iris.local` doit résoudre

---

## 2. Jonction au domaine

### Via script (recommandé)

```powershell
# Sur SISR-01 — PowerShell Admin
Set-ExecutionPolicy Unrestricted -Force
.\scripts\13_Client_JoinDomain.ps1
```

### Via interface graphique

1. Clic droit sur **Ce PC** → **Propriétés**
2. **Paramètres système avancés** → onglet **Nom de l'ordinateur**
3. Cliquer **Modifier** → sélectionner **Domaine** → saisir `iris.local`
4. Entrer les credentials de l'administrateur du domaine
5. Redémarrer

### OU via PowerShell direct

```powershell
# Configurer le DNS d'abord
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.50.10"
ipconfig /flushdns

# Joindre le domaine
$creds = Get-Credential "IRIS\Administrateur"
Add-Computer -DomainName "iris.local" -Credential $creds `
    -OUPath "OU=Ordinateurs-IRIS,OU=IRIS-Nice,DC=iris,DC=local" `
    -Restart -Force
```

---

## 3. Première connexion

Après redémarrage, à l'écran de connexion Windows 11 :

1. Cliquer **Autre utilisateur**
2. Saisir `IRIS\nbelloum` (ou tout autre compte du domaine)
3. Saisir le mot de passe
4. Les GPO et lecteurs réseau s'appliquent automatiquement

---

## 4. Vérifications après connexion

### Vérifier la jonction au domaine

```powershell
# Sur SRV-DC01
Get-ADComputer -Filter {Name -eq "SISR-01"} | Select-Object Name, DistinguishedName
```

### Vérifier les GPO appliquées (sur le poste)

```powershell
gpresult /r
```

### Vérifier les lecteurs réseau

```powershell
net use
# Doit afficher H:, S:, P: (ou A:) selon le compte connecté
```

### Lancer le script de test

```powershell
# Toujours en PowerShell NON-Administrateur pour voir les lecteurs de l'utilisateur
.\12_Verification_Client.ps1
```

---

## 5. Comportement des GPO sur SISR-01

### Comptes étudiants (SISR + SLAM)

| Restriction | Activée |
|------------|---------|
| Panneau de configuration | Bloqué |
| Invite de commande (CMD) | Bloquée |
| Regedit | Bloqué |
| Lecteur C: dans l'explorateur | Masqué |
| Ecran de veille | 10 min — protégé par mot de passe |
| Message légal à la connexion | Affiché |
| Autorun USB/CD | Désactivé |

### Comptes professeurs

| Paramètre | Valeur |
|-----------|--------|
| Panneau de configuration | Accessible |
| Ecran de veille | 10 min — protégé par mot de passe |
| Message légal | Affiché |
| Autorun | Désactivé |

---

## 6. Résolution de problèmes poste client

### Le poste ne trouve pas le domaine iris.local

```powershell
# 1. Vérifier que le DNS pointe vers SRV-DC01
Get-DnsClientServerAddress | Format-Table InterfaceAlias, ServerAddresses

# 2. Corriger si besoin
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.50.10"
ipconfig /flushdns

# 3. Tester
nslookup iris.local
ping SRV-DC01.iris.local
```

### Compte bloqué (trop de mauvais mots de passe)

```powershell
# Sur SRV-DC01 Admin
Unlock-ADAccount -Identity "nbelloum"
```

### Lecteurs réseau non visibles

```powershell
# Forcer la mise à jour des GPO
gpupdate /force /logoff

# Ou mapper manuellement
net use H: \\SRV-DC01\HomeDir$\%USERNAME% /persistent:yes
```

### Poste client n'est pas dans la bonne OU

```powershell
# Sur SRV-DC01
Get-ADComputer "SISR-01" | Select-Object DistinguishedName

# Déplacer si besoin
Move-ADObject -Identity "CN=SISR-01,CN=Computers,DC=iris,DC=local" `
    -TargetPath "OU=Ordinateurs-IRIS,OU=IRIS-Nice,DC=iris,DC=local"
```
