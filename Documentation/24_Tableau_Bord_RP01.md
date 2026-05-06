# 24 — Tableau de Bord Projet RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Fiche d'identité du projet

| Paramètre | Valeur |
|-----------|--------|
| Intitulé | Déploiement infrastructure Windows Server 2022 — Campus IRIS Nice |
| Référence | RP-01 (Réalisation Professionnelle n°1) |
| Formation | BTS SIO option SISR — Session 2026 |
| Etablissement | Mediaschool — IRIS Nice |
| Auteur | Omar Talibi |
| Période | 09/03/2026 au 20/03/2026 |
| Durée | ~2 semaines |
| Environnement | Oracle VirtualBox — Windows Server 2022 + Windows 11 |
| Statut | ✅ **TERMINÉ — 0 erreur validée** |

---

## 2. Récapitulatif de l'infrastructure déployée

### Serveurs et rôles

| Serveur | OS | Rôles installés | IP |
|---------|----|-----------------|----|
| SRV-DC01 | Windows Server 2022 Standard | AD DS, DNS, DHCP, NPS, ADCS | 192.168.50.10 |

### Postes clients

| Poste | OS | Statut | IP |
|-------|----|---------|----|
| SISR-01 | Windows 11 Pro | Joint au domaine iris.local | 192.168.50.x |

### Equipements réseau (physiques — config fournie)

| Equipement | Modèle | IP | Rôle |
|-----------|--------|-----|------|
| SW-IRIS | Cisco Catalyst 2960-S | 192.168.50.253 | Switch central + 802.1X |
| AP-IRIS | Cisco C9105AXI | 192.168.50.150 | Borne WiFi WPA3-Enterprise |
| R1-IRIS | Cisco 1941W | 192.168.50.254 | Routeur inter-VLAN + DHCP relay |

---

## 3. Compteurs clés

| Indicateur | Valeur |
|-----------|--------|
| VLANs configurés | 6 (VLAN 10, 20, 30, 40, 50, 99) |
| Scopes DHCP | 5 (VLANs 10, 20, 30, 40, 99) |
| OUs Active Directory | 9 |
| Comptes utilisateurs | 21 |
| Groupes de sécurité | 9 |
| Partages SMB | 6 (SISR, SLAM, Professeurs, Administration, Commun, HomeDir$) |
| HomeDirs créés | 21 |
| GPO créées | 5 |
| Scripts PowerShell | 14 |
| Clients RADIUS | 3 (switch, AP, routeur) |
| Politiques NPS | 3 (Etudiants VLAN10, Profs VLAN20, Admin VLAN30) |
| Certificats | 1 CA Enterprise Root + 1 certificat NPS |
| Fichiers documentation | 24 fichiers Markdown |
| Configs Cisco | 3 (switch, routeur, AP) |
| Résultat final | **0 erreur** |

---

## 4. Chronologie du déploiement

| Etape | Script | Durée estimée | Reboot requis |
|-------|--------|--------------|---------------|
| 1. Configuration IP + renommage | 01_Config_IP.ps1 | 5 min | ✅ Oui |
| 2. Installation AD DS + promotion DC | 02_Install_ADDS.ps1 | 15 min | ✅ Oui |
| 3. Configuration post-promotion | 03_Post_Promo.ps1 | 10 min | Non |
| 4. Création OUs et groupes | 04_OU_Groupes.ps1 | 5 min | Non |
| 5. Création des 21 comptes | 05_Comptes.ps1 | 5 min | Non |
| 6. Configuration DHCP (5 scopes) | 06_DHCP.ps1 | 5 min | Non |
| 7. Partages SMB + 21 HomeDirs + ACL | 07_Partages_SMB.ps1 | 10 min | Non |
| 8. GPO sécurité (5 GPO) + audit | 08_GPO_Securite.ps1 | 10 min | Non |
| 9. GPO lecteurs réseau (Drives.xml) | 09_GPO_Lecteurs.ps1 | 5 min | Non |
| 10. ADCS (CA) + NPS + RADIUS | 10_ADCS_NPS.ps1 | 15 min | ✅ Oui |
| 10b. Certificat NPS post-reboot | 10b_NPS_PostReboot.ps1 | 5 min | Non |
| 11. Vérification serveur complète | 11_Verification_Serveur.ps1 | 5 min | Non |
| 12. Jonction poste client | 13_Client_JoinDomain.ps1 | 5 min | ✅ Oui |
| 13. Vérification client | 12_Verification_Client.ps1 | 10 min | Non |
| **Total** | — | **~2h30** | **4 reboots** |

---

## 5. Résultats de validation

### Serveur (script 11)

```
[OK] IP fixe 192.168.50.10 sur Ethernet 2
[OK] Domaine iris.local — mode Windows2016Domain
[OK] 21 comptes utilisateurs
[OK] 9 groupes de sécurité
[OK] Zone DNS iris.local — Zone inverse 50.168.192
[OK] Forwarders 8.8.8.8 et 1.1.1.1
[OK] 5 scopes DHCP actifs
[OK] 6 partages SMB
[OK] 21 HomeDirs — ACL correctes
[OK] 5 GPO — AllSettingsEnabled
[OK] Drives.xml — 6 mappages
[OK] CA IRIS-Nice-CA opérationnelle
[OK] Template RASAndIASServer actif
[OK] Certificat NPS valide
[OK] Service NPS Running
[OK] 3 clients RADIUS
[OK] 3 politiques NPS avec VLANs 10/20/30

RÉSULTAT GLOBAL : 0 ERREUR ✅
```

### Client (script 12 — 5 comptes testés)

```
nbelloum (Etudiant SISR) : H: OK | S: SISR OK | P: Commun OK | GPO Restrictions OK ✅
jmarcucci (Etudiant SISR) : H: OK | S: SISR OK | P: Commun OK | GPO Restrictions OK ✅
yadidi (Etudiant SLAM)   : H: OK | S: SLAM OK | P: Commun OK | GPO Restrictions OK ✅
ksenasson (Etudiant SLAM): H: OK | S: SLAM OK | P: Commun OK | GPO Restrictions OK ✅
ybourquard (Professeur)  : H: OK | S: Profs OK | P: Commun OK | Panneau config OK ✅

RÉSULTAT GLOBAL : 0 ERREUR sur tous les comptes ✅
```

---

## 6. Problèmes rencontrés et résolus (résumé)

| # | Problème | Solution |
|---|---------|---------|
| 1 | IP sur mauvaise carte réseau | Détection dynamique de la carte Host-Only |
| 2 | GRP-WiFi-Admin manquant | Recréation manuelle dans AD |
| 3 | DNS VLAN 40 Guest | Utiliser `-OptionId 6` avec scope VLAN40 |
| 4 | Template NPS en français | "Serveurs RAS et IAS" ≠ "RAS and IAS Servers" |
| 5 | New-NpsNetworkPolicy inexistante | Configuration manuelle via nps.msc |
| 6 | Certificat NPS refusé | certtmpl.msc + certutil + reboot |
| 7 | auditpol en français | Utiliser les GUIDs des sous-catégories |
| 8 | Lecteurs non mappés au logon | GPO Préférences + Drives.xml (abandon logon scripts) |
| 9 | HomeDir$ accès refusé | Grant-SmbShareAccess "Utilisateurs du domaine" Change |
| 10 | Faux négatifs vérification NPS | Parsing XML spécifique netsh nps export |

---

## 7. Index de la documentation

| Fichier | Contenu |
|---------|---------|
| README.md | Vue d'ensemble du projet |
| 01_Plan_Tests_RP01.md | Plan de tests et résultats validés |
| 02_Procedure_Installation_RP01.md | Guide d'installation pas à pas |
| 03_Documentation_Technique_RP01.md | AD, DNS, DHCP, GPO, ADCS, NPS |
| 04_Problemes_Solutions_RP01.md | 10 problèmes résolus |
| 05_NPS_RADIUS_RP01.md | 802.1X et RADIUS détaillés |
| 06_Procedure_Utilisation_RP01.md | Guide utilisateur quotidien |
| 07_Architecture_Schema_RP01.md | Schéma réseau et flux |
| 08_GPO_Detail_RP01.md | Détail des 5 GPO |
| 09_ADCS_Certificats_RP01.md | PKI et certificats |
| 10_Cisco_Config_RP01.md | Configuration des équipements Cisco |
| 11_PosteClient_SISR01_RP01.md | Jonction et configuration poste client |
| 12_Matrice_Securite_RP01.md | Matrice des droits et sécurité |
| 13_Maintenance_Sauvegarde_RP01.md | Plan de maintenance |
| 14_Comptes_Acces_RP01.md | Comptes, mots de passe, droits d'accès |
| 15_AD_OUs_Complet_RP01.md | Structure AD et OUs détaillées |
| 16_DHCP_Complet_RP01.md | Configuration DHCP complète |
| 17_DNS_Complet_RP01.md | Configuration DNS complète |
| 18_Adressage_VLAN_RP01.md | Plan d'adressage IP et VLANs |
| 19_SMB_HomeDirs_RP01.md | Partages réseau et HomeDirs |
| 20_VirtualBox_LAB_RP01.md | Configuration de l'environnement LAB |
| 21_Administration_Courante_RP01.md | Procédures d'administration quotidienne |
| 22_Glossaire_RP01.md | Glossaire et lexique technique |
| 23_Audit_Securite_RP01.md | Politique d'audit et sécurité |
| 24_Tableau_Bord_RP01.md | Ce fichier — tableau de bord projet |

---

## 8. Livrables du projet

| Livrable | Format | Statut |
|---------|--------|--------|
| 14 scripts PowerShell | .ps1 | ✅ |
| 24 fichiers documentation | .md | ✅ |
| 3 configurations Cisco | .txt | ✅ |
| Fichier GPO Drives.xml | .xml | ✅ |
| Résultats vérification | .txt | ✅ |
| Dépôt GitHub complet | .zip | ✅ |
| Rapport technique PDF | .pdf | ✅ |
| Schéma réseau | .png | ⚠️ À placer manuellement dans /schema/ |
