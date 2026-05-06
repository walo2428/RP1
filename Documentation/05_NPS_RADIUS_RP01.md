# 05 — NPS RADIUS 802.1X — Documentation détaillée RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Flux d'authentification complet

```
Client WiFi se connecte au SSID IRIS-WiFi
    |
    | Saisit login/mot de passe AD
    v
Borne Cisco C9105AXI (AP-IRIS — 192.168.50.150)
    | NE vérifie PAS les credentials elle-même
    | Encapsule dans RADIUS Access-Request
    | Secret partagé pour s'authentifier auprès de NPS
    v
SRV-DC01 — NPS (port 1812 UDP)
    |
    | Vérifie que la borne est un client RADIUS autorisé (IP + secret)
    | Si non autorisé → RADIUS Reject immédiat
    |
    | Authentifie le compte dans Active Directory (MS-CHAPv2)
    | Si credentials incorrects → RADIUS Reject
    |
    | Parcourt les politiques réseau dans l'ordre :
    |   Politique 1 : membre de GRP-WiFi-SISR ?
    |       Oui → RADIUS Accept + Tunnel-Pvt-Group-ID = 10
    |   Politique 2 : membre de GRP-WiFi-Profs ?
    |       Oui → RADIUS Accept + Tunnel-Pvt-Group-ID = 20
    |   Politique 3 : membre de GRP-WiFi-Admin ?
    |       Oui → RADIUS Accept + Tunnel-Pvt-Group-ID = 30
    |   Aucune politique → RADIUS Reject
    v
Borne reçoit RADIUS Accept + attributs VLAN
    | Place le client dans le VLAN indiqué
    v
Client dans VLAN 10, 20 ou 30
    | Envoie une requête DHCP (broadcast dans son VLAN)
    v
Routeur Cisco (ip helper-address 192.168.50.10)
    | Relaie la requête vers SRV-DC01
    v
SRV-DC01 — DHCP
    | Répond avec une IP du scope correspondant
    v
Client obtient son IP et accède aux ressources
```

---

## 2. Clients RADIUS enregistrés

| Nom | Adresse IP | Fabricant | Usage |
|-----|-----------|----------|-------|
| SW-Cisco2960 | 192.168.50.253 | RADIUS Standard | Authentification filaire 802.1X |
| AP-C9105AXI | 192.168.50.150 | Cisco | Authentification WiFi WPA3-Enterprise |
| R1-Cisco1941W | 192.168.50.254 | Cisco | Authentification VPN |

Le secret RADIUS partagé est identique sur les 3 équipements et sur SRV-DC01. Il n'est pas publié dans ce dépôt.

---

## 3. Politiques réseau NPS

### IRIS-WiFi-Etudiants (ordre 1)

| Paramètre | Valeur |
|-----------|--------|
| Condition | Membre de IRIS\GRP-WiFi-SISR |
| Accès | Accordé |
| Authentification | PEAP + MS-CHAPv2 |
| Tunnel-Type | 13 — Virtual LANs (VLAN) |
| Tunnel-Medium-Type | 6 — IEEE 802 |
| Tunnel-Pvt-Group-ID | **10** |

### IRIS-WiFi-Professeurs (ordre 2)

| Paramètre | Valeur |
|-----------|--------|
| Condition | Membre de IRIS\GRP-WiFi-Profs |
| Accès | Accordé |
| Authentification | PEAP + MS-CHAPv2 |
| Tunnel-Pvt-Group-ID | **20** |

### IRIS-WiFi-Administration (ordre 3)

| Paramètre | Valeur |
|-----------|--------|
| Condition | Membre de IRIS\GRP-WiFi-Admin |
| Accès | Accordé |
| Authentification | PEAP + MS-CHAPv2 |
| Tunnel-Pvt-Group-ID | **30** |

---

## 4. Association utilisateurs → VLAN

| Utilisateur | Groupe WiFi | Politique NPS | VLAN |
|------------|------------|--------------|------|
| vandreo (SISR) | GRP-WiFi-SISR | IRIS-WiFi-Etudiants | 10 |
| ksenasson (SLAM) | GRP-WiFi-SISR | IRIS-WiFi-Etudiants | 10 |
| ybourquard (prof) | GRP-WiFi-Profs | IRIS-WiFi-Professeurs | 20 |
| mdupont (admin) | GRP-WiFi-Admin | IRIS-WiFi-Administration | 30 |

Les étudiants SLAM sont dans GRP-WiFi-SISR (même VLAN 10 que les SISR).

---

## 5. WiFi Guest — VLAN 40

Le VLAN 40 Guest ne passe pas par NPS. La borne est configurée avec un second SSID ouvert :

| Paramètre | Valeur |
|-----------|--------|
| SSID | IRIS-Guest |
| Sécurité | Ouverte (pas d'authentification) |
| VLAN | 40 (fixe, non dynamique) |
| DNS | 8.8.8.8 (pas d'accès aux services internes) |
| Isolation clients | Activée |

---

## 6. Certificat NPS

| Paramètre | Valeur |
|-----------|--------|
| Subject | CN=SRV-DC01.iris.local |
| Issuer | CN=IRIS-Nice-CA |
| Template | RASAndIASServer |
| Validité | 18/04/2027 |
| Usage | Authentification serveur NPS (PEAP) |

Ce certificat permet aux clients WiFi de valider l'identité du serveur NPS avant d'envoyer leurs credentials (protection contre les AP rogues). En production, ce certificat devrait être signé par une CA publique pour éviter l'avertissement de sécurité.

---

## 7. Vérification NPS en PowerShell

```powershell
# Vérifier les clients RADIUS
Get-NpsRadiusClient | Select-Object Name, Address, Enabled | Format-Table

# Vérifier les politiques et attributs VLAN
netsh nps export filename="C:\NPS_verify.xml" exportPSK=YES 2>$null
$xml = [xml](Get-Content "C:\NPS_verify.xml")
$profiles = $xml.Root.Children.Microsoft_Internet_Authentication_Service.Children.RadiusProfiles.Children

@("IRIS_WiFi_Etudiants","IRIS_WiFi_Professeurs","IRIS_WiFi_Administration") | ForEach-Object {
    $p = $profiles.$_
    if ($p) {
        $vlan = $p.Properties.msRADIUSTunnelPrivateGroupId."#text"
        Write-Host "$_ -> VLAN $vlan"
    } else {
        Write-Host "$_ : ABSENT" -ForegroundColor Red
    }
}
Remove-Item "C:\NPS_verify.xml" -Force

# Résultat attendu :
# IRIS_WiFi_Etudiants -> VLAN 10
# IRIS_WiFi_Professeurs -> VLAN 20
# IRIS_WiFi_Administration -> VLAN 30
```

---

## 8. Logs d'authentification NPS

Les événements RADIUS sont enregistrés dans l'Observateur d'événements :

```
Journaux Windows → Sécurité
  ID 6272 : Accès réseau accordé (RADIUS Accept)
  ID 6273 : Accès réseau refusé (RADIUS Reject)
```

```powershell
# Voir les dernières authentifications acceptées
Get-EventLog -LogName Security -InstanceId 6272 -Newest 10 | Format-List TimeGenerated, Message

# Voir les refus
Get-EventLog -LogName Security -InstanceId 6273 -Newest 10 | Format-List TimeGenerated, Message
```
