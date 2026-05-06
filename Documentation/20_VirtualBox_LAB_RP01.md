# 20 — Environnement VirtualBox LAB RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Présentation du LAB

L'infrastructure IRIS Nice est déployée dans un environnement de virtualisation **Oracle VirtualBox** sur un poste physique unique. Ce LAB simule une infrastructure réseau d'entreprise avec un contrôleur de domaine et un poste client.

| Paramètre | Valeur |
|-----------|--------|
| Hyperviseur | Oracle VirtualBox |
| Version VirtualBox | 7.x |
| Système hôte | Windows 10/11 ou Linux |
| Nombre de VMs | 2 |
| RAM totale conseillée | 8 Go minimum sur l'hôte |

---

## 2. Machine virtuelle SRV-DC01

| Paramètre | Valeur |
|-----------|--------|
| Nom VM | SRV-DC01 |
| OS | Windows Server 2022 Standard |
| RAM | 4 Go (4096 Mo) |
| Processeurs | 2 vCPU |
| Disque | 60 Go (dynamique) |
| Carte réseau 1 (Ethernet) | NAT — accès internet — IP : 10.0.2.15 |
| Carte réseau 2 (Ethernet 2) | Host-Only Adapter (vboxnet0) — IP fixe : 192.168.50.10 |
| Rôles installés | AD DS, DNS, DHCP, NPS (Network Policy Server), ADCS |
| Nom d'hôte | SRV-DC01 |
| Domaine | iris.local |

### Configuration réseau détaillée SRV-DC01

```
Ethernet (Carte 1 — NAT)
  IPv4 : 10.0.2.15 (DHCP VirtualBox)
  Masque : 255.255.255.0
  Passerelle : 10.0.2.2 (VirtualBox NAT Gateway)
  DNS : 10.0.2.3 (VirtualBox DNS)
  Usage : accès internet pour téléchargements, Windows Update

Ethernet 2 (Carte 2 — Host-Only)
  IPv4 : 192.168.50.10 (FIXE)
  Masque : 255.255.255.0
  Passerelle : 192.168.50.254
  DNS : 127.0.0.1 (lui-même)
  Usage : communication avec SISR-01, AD, SMB, DNS interne
```

---

## 3. Machine virtuelle SISR-01 (poste client)

| Paramètre | Valeur |
|-----------|--------|
| Nom VM | SISR-01 |
| OS | Windows 11 Pro |
| RAM | 2 Go (2048 Mo) minimum |
| Processeurs | 2 vCPU |
| Disque | 50 Go (dynamique) |
| Carte réseau 1 | Host-Only Adapter (vboxnet0) — DHCP ou IP dans 192.168.50.x |
| Nom d'hôte | SISR-01 |
| Domaine | iris.local (joint via script 13_Client_JoinDomain.ps1) |

### Configuration réseau SISR-01 avant jonction

```
DNS Serveur : 192.168.50.10 (SRV-DC01) — OBLIGATOIRE avant jonction
IP : 192.168.50.x (obtenue par DHCP ou fixe dans le sous-réseau)
Passerelle : 192.168.50.254
```

---

## 4. Réseau Host-Only VirtualBox

| Paramètre | Valeur |
|-----------|--------|
| Nom de l'adaptateur | vboxnet0 |
| IP de l'hôte VirtualBox | 192.168.50.1 (interface virtuelle sur l'hôte physique) |
| Réseau | 192.168.50.0/24 |
| DHCP VirtualBox | Désactivé (on gère nous-mêmes avec SRV-DC01) |

> L'interface Host-Only permet la communication entre les VMs et entre les VMs et l'hôte physique, sans accès internet direct.

---

## 5. Ordre de démarrage des VMs

```
1. SRV-DC01 (attendre 2-3 min que tous les services AD/DNS/DHCP démarrent)
2. SISR-01 (lancement après SRV-DC01 opérationnel)
```

⚠️ Si SISR-01 démarre avant SRV-DC01 : les tickets Kerberos ne peuvent pas être émis → le logon peut prendre très longtemps ou échouer.

---

## 6. Snapshots VirtualBox recommandés

| Snapshot | Moment | Description |
|---------|--------|-------------|
| 01_OS_Frais | Après installation Windows Server 2022 | OS vierge propre |
| 02_Config_IP | Après script 01 | IP fixe + renommage |
| 03_AD_Promu | Après script 02 + reboot | DC fonctionnel |
| 04_Post_Promo | Après script 03 | DNS/NTP/UPN configurés |
| 05_OUs_Groupes | Après script 04 | Structure AD complète |
| 06_Comptes | Après script 05 | 21 comptes créés |
| 07_DHCP | Après script 06 | 5 scopes DHCP actifs |
| 08_SMB | Après script 07 | Partages + HomeDirs |
| 09_GPO | Après scripts 08+09 | 5 GPO appliquées |
| 10_ADCS_NPS | Après script 10+10b | CA + RADIUS |
| 11_FINAL | Après validation 0 erreur | Etat final validé |

---

## 7. Dépannage courant en LAB VirtualBox

### Problème : SRV-DC01 n'a pas internet

```
Vérifier :
- La carte NAT est bien activée (Mode d'accès réseau = NAT)
- ping 8.8.8.8 depuis cmd sur SRV-DC01
- Si ça ne marche pas → désactiver/réactiver la carte NAT dans les paramètres VM
```

### Problème : SISR-01 ne voit pas SRV-DC01

```
Vérifier :
- Les deux VMs sont sur le même réseau Host-Only (vboxnet0)
- ping 192.168.50.10 depuis SISR-01
- DHCP VirtualBox désactivé sur vboxnet0
- Firewall Windows SRV-DC01 autorise ICMP
```

### Problème : Jonction au domaine échoue

```
Vérifier dans l'ordre :
1. DNS de SISR-01 = 192.168.50.10 (pas 8.8.8.8)
2. ping SRV-DC01.iris.local (résolution DNS)
3. SRV-DC01 démarré et services AD en ligne
4. Heure synchronisée entre les 2 VMs (Kerberos exige < 5min d'écart)
```

### Problème : Logon lent après jonction

```
Normal en LAB VirtualBox — jusqu'à 2 min au premier logon.
Les profils itinérants ne sont pas configurés dans ce projet.
```

---

## 8. Extensions VirtualBox Guest Additions

Installer les Guest Additions sur les deux VMs pour :
- Copier-coller entre hôte et VM
- Glisser-déposer de fichiers
- Résolution d'écran dynamique
- Synchronisation de l'heure avec l'hôte

```
Dans VirtualBox menu VM → Périphériques → Insérer l'image CD des additions invité
Puis dans la VM : exécuter VBoxWindowsAdditions.exe
```
