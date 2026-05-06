# 01 — Plan de tests RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Tests serveur — script 11_Verification_Serveur.ps1

Résultat global : **0 erreur détectée**

### Réseau

| Test | Valeur attendue | Résultat |
|------|----------------|---------|
| IP fixe sur Ethernet 2 | 192.168.50.10 | OK |
| Carte NAT internet | 10.0.2.15 | OK |

### Active Directory

| Test | Valeur attendue | Résultat |
|------|----------------|---------|
| Domaine DNS | iris.local | OK |
| Mode domaine | Windows2016Domain | OK |
| 21 comptes utilisateurs | Count = 21 | OK |
| GRP-Etudiants-SISR | Présent | OK |
| GRP-Etudiants-SLAM | Présent | OK |
| GRP-Professeurs | Présent | OK |
| GRP-Administration | Présent | OK |
| GRP-WiFi-SISR | Présent | OK |
| GRP-WiFi-Profs | Présent | OK |
| GRP-WiFi-Admin | Présent | OK |
| GRP-Informatique | Présent | OK |
| GRP-VPN-Users | Présent | OK |

### DNS

| Test | Valeur attendue | Résultat |
|------|----------------|---------|
| Zone iris.local | Primaire intégrée AD | OK |
| Zone inverse 50.168.192 | Présente | OK |
| Forwarder 8.8.8.8 | Présent | OK |
| Forwarder 1.1.1.1 | Présent | OK |

### DHCP

| Test | Valeur attendue | Résultat |
|------|----------------|---------|
| Service DHCP | Running, Automatic | OK |
| Scope VLAN10-Etudiants | Active | OK |
| Scope VLAN20-Professeurs | Active | OK |
| Scope VLAN30-Administration | Active | OK |
| Scope VLAN40-Guest | Active | OK |
| Scope VLAN99-PreAuth | Active | OK |

### Partages SMB

| Test | Valeur attendue | Résultat |
|------|----------------|---------|
| Partage SISR | C:\Partages\Etudiants-SISR | OK |
| Partage SLAM | C:\Partages\Etudiants-SLAM | OK |
| Partage Professeurs | C:\Partages\Professeurs | OK |
| Partage Administration | C:\Partages\Administration | OK |
| Partage Commun | C:\Partages\Commun | OK |
| Partage HomeDir$ | C:\HomeDir | OK |
| 21 HomeDirs | Count = 21 | OK |
| ACL HomeDirs | Modify par utilisateur | OK |
| HomeDir$ accès domaine | Utilisateurs du domaine = Change | OK |

### GPO

| Test | Valeur attendue | Résultat |
|------|----------------|---------|
| IRIS-PasswordPolicy | AllSettingsEnabled | OK |
| IRIS-Restrictions-Etudiants | AllSettingsEnabled | OK |
| IRIS-LecteursReseau | AllSettingsEnabled | OK |
| IRIS-Securite-Baseline | AllSettingsEnabled | OK |
| IRIS-Profs-Acces | AllSettingsEnabled | OK |
| Drives.xml GPO Préférences | 6 mappages | OK |

### ADCS

| Test | Valeur attendue | Résultat |
|------|----------------|---------|
| CA IRIS-Nice-CA | Opérationnelle | OK |
| Template RASAndIASServer | Actif | OK |
| Certificat NPS | Valide jusqu'en 2027 | OK |

### NPS RADIUS

| Test | Valeur attendue | Résultat |
|------|----------------|---------|
| Service NPS (IAS) | Running, Automatic | OK |
| Client SW-Cisco2960 | 192.168.50.253 | OK |
| Client AP-C9105AXI | 192.168.50.150 | OK |
| Client R1-Cisco1941W | 192.168.50.254 | OK |
| Politique IRIS-WiFi-Etudiants | VLAN 10 | OK |
| Politique IRIS-WiFi-Professeurs | VLAN 20 | OK |
| Politique IRIS-WiFi-Administration | VLAN 30 | OK |

### Poste client

| Test | Valeur attendue | Résultat |
|------|----------------|---------|
| SISR-01 joint au domaine | Présent dans AD | OK |

---

## 2. Tests clients — script 12_Verification_Client.ps1

Résultat global : **0 erreur sur tous les comptes testés**

### Comptes testés

| Compte | Type | Domaine | H: | S: | P: | GPO Restrictions | Baseline | Résultat |
|--------|------|---------|----|----|-----|-----------------|---------|---------|
| nbelloum | Etudiant SISR | IRIS | OK | SISR OK | OK | CMD/regedit/panneau bloqués | Ecran veille OK | Validé |
| jmarcucci | Etudiant SISR | IRIS | OK | SISR OK | OK | CMD/regedit/panneau bloqués | Ecran veille OK | Validé |
| yadidi | Etudiant SLAM | IRIS | OK | SLAM OK | OK | CMD/regedit/panneau bloqués | Ecran veille OK | Validé |
| ksenasson | Etudiant SLAM | IRIS | OK | SLAM OK | OK | CMD/regedit/panneau bloqués | Ecran veille OK | Validé |
| ybourquard | Professeur | IRIS | OK | Profs OK | OK | Panneau config accessible | Ecran veille OK | Validé |

### Détail GPO étudiants

| Clé registre | Valeur | Description | Résultat |
|-------------|--------|-------------|---------|
| HKCU\...\NoControlPanel | 1 | Panneau config désactivé | OK |
| HKCU\...\DisableCMD | 1 | CMD désactivée | OK |
| HKCU\...\DisableRegistryTools | 1 | Regedit désactivé | OK |
| HKCU\...\ScreenSaveActive | 1 | Ecran de veille actif | OK |
| HKCU\...\ScreenSaverIsSecure | 1 | Protégé par mot de passe | OK |

---

## 3. Remarques

**Lecteurs réseau — connexion différée**
Les lecteurs apparaissent comme "Déconnectés" dans `net use` jusqu'au premier accès réel (dir H:, dir S:...). Après le premier accès ils passent en état "OK". C'est le comportement normal de Windows 11 avec les GPO Préférences — ce n'est pas une erreur.

**NPS — vérification via XML**
La vérification des politiques NPS via PowerShell requiert un parsing XML spécifique de l'export `netsh nps export`. La structure XML NPS est `Root.Children.Microsoft_Internet_Authentication_Service.Children.RadiusProfiles.Children.IRIS_WiFi_*`.

**Script de vérification lancé en Admin**
Si le script 12 est lancé en PowerShell Administrateur, les lecteurs mappés de la session utilisateur ne sont pas visibles. Toujours lancer le script 12 dans une session PowerShell normale (sans clic droit Admin) avec le compte de l'utilisateur à tester.
