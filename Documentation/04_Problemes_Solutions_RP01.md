# 04 — Problèmes rencontrés et solutions RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## Problème 1 — IP configurée sur la mauvaise carte réseau

**Symptôme :** Ethernet (NAT) reçoit 192.168.50.10 au lieu d'Ethernet 2 (Host-Only).

**Cause :** Le script prenait la première carte "Up" sans vérifier son adresse IP.

**Solution :** Filtrage par adresse — la carte NAT a toujours une IP en 10.0.2.x, la carte Host-Only a une IP APIPA ou aucune IP. On cible la carte qui n'a pas d'IP en 10.0.2.x.

```powershell
foreach ($carte in (Get-NetAdapter | Where-Object { $_.Status -eq "Up" })) {
    $ip = (Get-NetIPAddress -InterfaceIndex $carte.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    if ($ip -notlike "10.0.2.*" -and $ip -notlike "169.254.*") {
        $carteHO = $carte; break
    }
}
```

---

## Problème 2 — Groupe GRP-WiFi-Admin manquant après script 04

**Symptôme :** `Add-ADGroupMember : Impossible de trouver GRP-WiFi-Admin`

**Cause :** Erreur silencieuse lors de la création du groupe dans le script 04.

**Solution :**
```powershell
New-ADGroup -Name "GRP-WiFi-Admin" -GroupScope Global -GroupCategory Security `
    -Path "OU=Groupes,OU=IRIS-Nice,DC=iris,DC=local" `
    -Description "Auth WiFi 802.1X -> VLAN 30"
Add-ADGroupMember -Identity "GRP-WiFi-Admin" -Members "mdupont","jmartin","sbernard"
```

---

## Problème 3 — DNS VLAN 40 Guest — "8.8.8.8 n'est pas un serveur DNS valide"

**Symptôme :** `Set-DhcpServerv4OptionValue : 8.8.8.8 n'est pas un serveur DNS valide`

**Cause :** La cmdlet refuse une IP publique sans préciser l'OptionId explicitement.

**Solution :** Utiliser `-OptionId 6` pour forcer l'option DNS.
```powershell
Set-DhcpServerv4OptionValue -ScopeId "192.168.40.0" -OptionId 6 -Value "8.8.8.8","8.8.4.4"
```

---

## Problème 4 — Groupe "RAS and IAS Servers" introuvable

**Symptôme :** `Add-ADGroupMember : Impossible de trouver "RAS and IAS Servers"`

**Cause :** Sur Windows Server en français, le groupe s'appelle "Serveurs RAS et IAS".

**Solution :** Recherche par wildcard indépendante de la langue.
```powershell
$grp = Get-ADGroup -Filter {Name -like "*Serveurs RAS*" -or Name -like "*RAS and IAS*"} | Select-Object -First 1
Add-ADGroupMember -Identity $grp -Members "SRV-DC01$"
```

---

## Problème 5 — New-NpsNetworkPolicy inexistante sur Windows Server 2022

**Symptôme :** `New-NpsNetworkPolicy : Le terme n'est pas reconnu comme applet de commande`

**Cause :** La cmdlet n'existe pas sur Windows Server 2022.

**Solution :** Création manuelle des politiques dans `nps.msc` — voir procédure dans `02_Procedure_Installation_RP01.md`.

---

## Problème 6 — Certificat NPS refusé — autorisations insuffisantes

**Symptôme :** `CERTSRV_E_TEMPLATE_DENIED : Les autorisations ne permettent pas l'inscription`

**Cause :** Deux problèmes cumulés : template non activé sur la CA + SRV-DC01 non membre du groupe Serveurs RAS et IAS.

**Solution en 4 étapes :**
```powershell
# 1. Ajouter SRV-DC01 au groupe
$grp = Get-ADGroup -Filter {Name -like "*Serveurs RAS*"}
Add-ADGroupMember -Identity $grp -Members "SRV-DC01$"

# 2. Activer le template sur la CA
certutil -SetCATemplates +RASAndIASServer
```
3. Redémarrer la VM (obligatoire — nouveau token Kerberos pour SRV-DC01$)
4. Configurer `certtmpl.msc` — ajouter SRV-DC01$ avec droit Inscrire sur le template
5. Demander le certificat dans `mmc` → Certificats Ordinateur → Personnel → Demander nouveau certificat → RAS and IAS Server

---

## Problème 7 — auditpol — erreur de catégorie

**Symptôme :** `auditpol /set /category:"Logon/Logoff" → Erreur`

**Cause :** OS en français — les noms de catégories sont traduits.

**Solution :** Utiliser les GUIDs universels indépendants de la langue.
```powershell
auditpol /set /subcategory:"{0CCE9215-69AE-11D9-BED3-505054503030}" /success:enable /failure:enable
```

---

## Problème 8 — Lecteurs réseau non mappés au logon

**Symptôme :** Seul H: apparaissait, S: et P: absents malgré le script logon.bat.

**Cause :** Le script logon s'exécutait avant que le token Kerberos avec les groupes AD soit chargé (timing insuffisant).

**Solutions tentées et abandonnées :**
- `net use` dans logon script → token Kerberos incomplet
- `schtasks` avec contexte SYSTEM → pas accès aux groupes utilisateur
- `New-PSDrive -Persist` → erreur "Accès refusé" au logon

**Solution finale :** GPO Préférences → Mappages de lecteurs avec ciblage par SID de groupe AD. Cette méthode est native Windows, gérée par le moteur GPO, sans dépendance de timing.

---

## Problème 9 — Lecteur H: — "Accès refusé" depuis le poste client

**Symptôme :** `Test-Path H:\ → Accès refusé`

**Cause :** Le partage SMB `HomeDir$` n'autorisait que l'Administrateur — les utilisateurs du domaine n'avaient aucun droit sur le partage lui-même (seulement sur leurs sous-dossiers via ACL NTFS).

**Solution :**
```powershell
Grant-SmbShareAccess -Name "HomeDir$" `
    -AccountName "IRIS\Utilisateurs du domaine" `
    -AccessRight Change -Force
```

---

## Problème 10 — Script de vérification NPS — faux négatifs

**Symptôme :** Le script 11 signalait les politiques NPS comme absentes alors qu'elles étaient bien configurées dans nps.msc.

**Cause :** La structure XML de l'export `netsh nps export` est différente de `$npsXml.Server.Policies.NetworkPolicy` utilisé dans la première version du script. La vraie structure est `Root.Children.Microsoft_Internet_Authentication_Service.Children.RadiusProfiles.Children.IRIS_WiFi_*`.

**Solution :**
```powershell
netsh nps export filename="C:\NPS_verify.xml" exportPSK=YES
$xml = [xml](Get-Content "C:\NPS_verify.xml")
$profiles = $xml.Root.Children.Microsoft_Internet_Authentication_Service.Children.RadiusProfiles.Children
$profil = $profiles.IRIS_WiFi_Etudiants
$vlan = $profil.Properties.msRADIUSTunnelPrivateGroupId."#text"
```
