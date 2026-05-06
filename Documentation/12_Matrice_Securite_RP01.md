# 12 — Matrice de sécurité et droits d'accès RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Matrice d'accès aux partages SMB / NTFS

| Ressource | GRP-SISR | GRP-SLAM | GRP-Profs | GRP-Admin | GRP-Info | Administrateur |
|-----------|---------|---------|---------|---------|---------|---------------|
| \\SRV-DC01\SISR | **Modify** | ✗ | ✗ | ✗ | FullControl | FullControl |
| \\SRV-DC01\SLAM | ✗ | **Modify** | ✗ | ✗ | FullControl | FullControl |
| \\SRV-DC01\Professeurs | ✗ | ✗ | **Modify** | ✗ | FullControl | FullControl |
| \\SRV-DC01\Administration | ✗ | ✗ | ✗ | **Modify** | FullControl | FullControl |
| \\SRV-DC01\Commun | **Read** | **Read** | **Modify** | ✗ | FullControl | FullControl |
| \\SRV-DC01\HomeDir$\[login] | **Modify** (perso) | **Modify** (perso) | **Modify** (perso) | **Modify** (perso) | FullControl | FullControl |

Légende : Modify = Lire + Écrire + Supprimer ses propres fichiers / Read = Lecture seule / ✗ = Accès interdit

---

## 2. Matrice d'accès WiFi / VLAN

| Utilisateur | Groupe WiFi | VLAN attribué | Réseau | Accès services |
|------------|------------|--------------|--------|---------------|
| Etudiants SISR | GRP-WiFi-SISR | **10** | 192.168.10.0/24 | AD, DNS, DHCP, SMB (SISR, Commun, HomeDir) |
| Etudiants SLAM | GRP-WiFi-SISR | **10** | 192.168.10.0/24 | AD, DNS, DHCP, SMB (SLAM, Commun, HomeDir) |
| Professeurs | GRP-WiFi-Profs | **20** | 192.168.20.0/24 | AD, DNS, DHCP, SMB (Profs, Commun, HomeDir) |
| Administration | GRP-WiFi-Admin | **30** | 192.168.30.0/24 | AD, DNS, DHCP, SMB (Admin, HomeDir) |
| Invités | (pas de groupe) | **40** | 192.168.40.0/24 | Internet uniquement — DNS 8.8.8.8 |
| Equipe IT | GRP-WiFi-Admin | **30** ou **50** | 192.168.30.0/24 | Tout |

---

## 3. Matrice GPO par profil

| Restriction / Paramètre | Etudiants SISR | Etudiants SLAM | Professeurs | Administration | Informatique |
|------------------------|---------------|---------------|------------|---------------|-------------|
| Panneau de configuration | ❌ Bloqué | ❌ Bloqué | ✅ Accessible | ✅ Accessible | ✅ Accessible |
| Invite de commande CMD | ❌ Bloquée | ❌ Bloquée | ✅ Accessible | ✅ Accessible | ✅ Accessible |
| Regedit | ❌ Bloqué | ❌ Bloqué | ✅ Accessible | ✅ Accessible | ✅ Accessible |
| Lecteur C: visible | ❌ Masqué | ❌ Masqué | ✅ Visible | ✅ Visible | ✅ Visible |
| Ecran de veille (10 min) | ✅ Oui | ✅ Oui | ✅ Oui | ✅ Oui | ✅ Oui |
| MDP ecran de veille | ✅ Oui | ✅ Oui | ✅ Oui | ✅ Oui | ✅ Oui |
| Autorun USB/CD désactivé | ✅ Oui | ✅ Oui | ✅ Oui | ✅ Oui | ✅ Oui |
| Firewall Windows | ✅ Forcé | ✅ Forcé | ✅ Forcé | ✅ Forcé | ✅ Forcé |
| Message légal | ✅ Oui | ✅ Oui | ✅ Oui | ✅ Oui | ✅ Oui |
| H: HomeDir | ✅ Modify | ✅ Modify | ✅ Modify | ✅ Modify | ✅ Modify |
| S: Filière | ✅ SISR | ✅ SLAM | ✅ Profs | ✗ | ✗ |
| A: Administration | ✗ | ✗ | ✗ | ✅ Modify | ✗ |
| P: Commun | ✅ Read | ✅ Read | ✅ Modify | ✗ | ✗ |

---

## 4. Politique de mot de passe

| Paramètre | Valeur |
|-----------|--------|
| Longueur minimale | 8 caractères |
| Complexité | Requise (majuscule + minuscule + chiffre/symbole) |
| Historique | 5 anciens mots de passe mémorisés |
| Durée maximale | 90 jours |
| Durée minimale | 1 jour |
| Chiffrement réversible | Désactivé |
| Mot de passe par défaut déploiement | `Iris@Etudiant2026!` |

---

## 5. Audit de sécurité

### Catégories auditées

| Catégorie | Succès | Echecs | ID Evénements clés |
|-----------|--------|--------|-------------------|
| Ouverture/Fermeture de session | ✅ | ✅ | 4624 (connexion), 4625 (échec), 4634 (déconnexion) |
| Authentification de compte | ✅ | ✅ | 4776 (NTLM), 4768 (Kerberos TGT), 4769 (Kerberos TGS) |
| Gestion des comptes | ✅ | ✅ | 4720 (création), 4725 (désactivation), 4726 (suppression) |
| Accès aux objets | ✅ | ✅ | 4663 (accès fichier), 5145 (accès réseau) |
| Modification de politique | ✅ | ✅ | 4719 (changement audit), 4739 (changement MDP) |
| Utilisation des privilèges | ✅ | ✅ | 4672 (privilèges sensibles attribués) |
| Evénements système | ✅ | ✅ | 1102 (log effacé), 4608 (démarrage Windows) |

### Consulter les logs

```powershell
# Connexions échouées (mauvais MDP, compte bloqué)
Get-EventLog -LogName Security -InstanceId 4625 -Newest 50 |
    Select-Object TimeGenerated, @{n='Compte';e={$_.ReplacementStrings[5]}} |
    Format-Table -AutoSize

# Connexions réussies
Get-EventLog -LogName Security -InstanceId 4624 -Newest 20 |
    Select-Object TimeGenerated, @{n='Compte';e={$_.ReplacementStrings[5]}} |
    Format-Table -AutoSize

# Modifications de comptes AD
Get-EventLog -LogName Security -InstanceId 4720,4722,4724,4725,4726 -Newest 20 |
    Format-List TimeGenerated, Message
```

---

## 6. Politique de segmentation réseau

### Accès inter-VLAN autorisés

| Source | Destination | Autorisé | Condition |
|--------|------------|---------|----------|
| VLAN 10 | SRV-DC01 (50) | ✅ | AD, DNS, DHCP, SMB |
| VLAN 10 | Internet | ✅ | NAT sur R1-IRIS |
| VLAN 10 | VLAN 20, 30, 40 | ❌ | ACL sur R1-IRIS |
| VLAN 20 | SRV-DC01 (50) | ✅ | AD, DNS, DHCP, SMB |
| VLAN 20 | Internet | ✅ | NAT sur R1-IRIS |
| VLAN 30 | SRV-DC01 (50) | ✅ | AD, DNS, DHCP, SMB |
| VLAN 30 | Internet | ✅ | NAT sur R1-IRIS |
| VLAN 40 | Internet | ✅ | NAT sur R1-IRIS (DNS 8.8.8.8) |
| VLAN 40 | SRV-DC01 (50) | ❌ | Bloqué — Guest isolé |
| VLAN 50 | Tout | ✅ | Management — accès complet |
| VLAN 99 | DHCP uniquement | ✅ | En attente auth 802.1X |

### Isolation des invités (VLAN 40)

- DNS configuré sur 8.8.8.8 (pas de résolution iris.local)
- ACL sur R1-IRIS bloque l'accès à 192.168.10-30-50.0/24
- Isolation clients WiFi activée sur la borne (pas de communication entre invités)

---

## 7. Comptes à droits élevés

| Compte | Type | Droits | Localisation |
|--------|------|--------|-------------|
| Administrateur | Compte intégré | Admin du domaine | CN=Administrator,CN=Users,DC=iris,DC=local |
| airis | Compte IT | GRP-Informatique + GRP-VPN-Users | OU=Informatique |
| Compte DSRM | Mode restauration AD | Admin local uniquement | Local SRV-DC01 |

> Les mots de passe des comptes admin ne sont pas dans ce dépôt.

---

## 8. Points de conformité ANSSI

| Recommandation ANSSI | Implémenté | Méthode |
|---------------------|-----------|---------|
| Comptes nominatifs (pas de comptes partagés) | ✅ | 21 comptes individuels |
| Mots de passe complexes (8 car. min) | ✅ | GPO PasswordPolicy |
| Historique des mots de passe (5) | ✅ | GPO PasswordPolicy |
| Durée de vie maximale (90 jours) | ✅ | GPO PasswordPolicy |
| Écran de veille avec mot de passe | ✅ | GPO Securite-Baseline |
| Autorun désactivé | ✅ | GPO Securite-Baseline |
| Firewall activé en domaine | ✅ | GPO Securite-Baseline |
| Audit des événements de sécurité | ✅ | auditpol — 7 catégories |
| Principe du moindre privilège | ✅ | ACL NTFS par groupe |
| Segmentation réseau | ✅ | VLANs + ACL routeur |
| Authentification réseau 802.1X | ✅ | NPS + Switch + AP |
| Certificats pour l'authentification | ✅ | ADCS IRIS-Nice-CA |
| Chiffrement des mots de passe AD | ✅ | Chiffrement réversible = Off |
