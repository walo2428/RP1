# 22 — Glossaire et Lexique Technique RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## Termes Active Directory

| Terme | Définition |
|-------|-----------|
| **Active Directory (AD)** | Service d'annuaire Microsoft permettant la gestion centralisée des utilisateurs, ordinateurs et ressources dans un domaine Windows. |
| **DC (Domain Controller)** | Serveur hébergeant Active Directory. Dans ce projet : SRV-DC01. |
| **Domaine** | Regroupement logique d'objets AD (utilisateurs, ordinateurs) partageant une politique de sécurité commune. Ici : iris.local. |
| **Forêt** | Ensemble de domaines AD partageant un schéma commun. Ce projet a une forêt à domaine unique. |
| **OU (Organizational Unit)** | Conteneur AD permettant de regrouper des objets et d'y appliquer des GPO. |
| **GPO (Group Policy Object)** | Objet de stratégie de groupe définissant des paramètres appliqués aux utilisateurs ou ordinateurs d'une OU. |
| **UPN (User Principal Name)** | Identifiant unique d'un utilisateur sous la forme login@domaine. Ex : nbelloum@iris.local. |
| **SID (Security Identifier)** | Identifiant unique d'un objet AD (utilisateur, groupe, ordinateur). Utilisé dans les ACL et le ciblage GPO. |
| **Kerberos** | Protocole d'authentification utilisé par Active Directory. Basé sur des tickets émis par le KDC (Key Distribution Center) hébergé sur le DC. |
| **LDAP** | Protocole d'accès à l'annuaire AD. Port TCP 389 (non chiffré) et 636 (LDAPS chiffré). |
| **SYSVOL** | Dossier partagé sur le DC contenant les GPO et les scripts de logon. Répliqué entre DCs via DFS-R. |
| **NTDS.dit** | Base de données Active Directory (fichier). Stockée dans C:\Windows\NTDS. |

---

## Termes Réseau

| Terme | Définition |
|-------|-----------|
| **VLAN (Virtual LAN)** | Segmentation logique d'un réseau physique. Permet d'isoler des groupes d'utilisateurs sur le même switch physique. |
| **802.1Q** | Standard IEEE de marquage VLAN sur les trames Ethernet (tag 12 bits identifiant le VLAN). |
| **Trunk** | Port switch transportant plusieurs VLANs simultanément (avec tags 802.1Q). |
| **Access** | Port switch appartenant à un seul VLAN (sans tag). Connecté aux postes finaux. |
| **Router-on-a-stick** | Technique de routage inter-VLAN utilisant un seul port physique du routeur avec des sous-interfaces tagguées. |
| **ip helper-address** | Commande Cisco permettant le relayage des requêtes DHCP broadcast vers un serveur unicast. |
| **DHCP (Dynamic Host Configuration Protocol)** | Protocole d'attribution automatique d'adresses IP aux clients réseau. |
| **DNS (Domain Name System)** | Système de résolution de noms de domaine en adresses IP. |
| **SMB (Server Message Block)** | Protocole de partage de fichiers Windows. Utilisé pour les lecteurs réseau (H:, S:, P:, A:). |
| **UNC (Universal Naming Convention)** | Format d'adressage des partages réseau : \\serveur\partage. |
| **ACL (Access Control List)** | Liste de règles contrôlant l'accès à une ressource (partage SMB ou fichier NTFS). |
| **NTFS** | Système de fichiers Windows supportant les ACL avancées. |

---

## Termes Sécurité / 802.1X / RADIUS

| Terme | Définition |
|-------|-----------|
| **802.1X** | Standard IEEE de contrôle d'accès réseau au niveau du port (PAE - Port Access Entity). |
| **RADIUS (Remote Authentication Dial-In User Service)** | Protocole d'authentification centralisé. Port UDP 1812 (auth), 1813 (accounting). |
| **NPS (Network Policy Server)** | Serveur RADIUS Microsoft. Gère l'authentification 802.1X et les politiques réseau. |
| **Supplicant** | Client cherchant à accéder au réseau (poste Windows, téléphone). |
| **Authenticator** | Equipement réseau validant les accès (switch Cisco, borne WiFi). |
| **Authentication Server** | Serveur RADIUS (NPS) validant les credentials. |
| **EAP (Extensible Authentication Protocol)** | Protocole encapsulant les mécanismes d'authentification dans 802.1X. |
| **EAP-TLS** | Méthode EAP utilisant des certificats X.509 côté client et serveur. |
| **PEAP-MSCHAPv2** | Méthode EAP utilisant un certificat serveur + identifiant/mot de passe client. |
| **VLAN dynamique** | Attribution automatique du VLAN en fonction des attributs RADIUS retournés après authentification. |
| **Tunnel-Type** | Attribut RADIUS (n°64) indiquant le type de tunnel. Valeur 13 = VLAN. |
| **Tunnel-Medium-Type** | Attribut RADIUS (n°65) indiquant le médium. Valeur 6 = 802. |
| **Tunnel-Pvt-Group-ID** | Attribut RADIUS (n°81) indiquant le numéro de VLAN assigné. |
| **SSID (Service Set Identifier)** | Nom du réseau WiFi. |
| **WPA3-Enterprise** | Protocole de sécurité WiFi avec authentification 802.1X. |
| **Secret RADIUS partagé** | Clé partagée entre l'authenticator (switch/AP) et le serveur RADIUS pour sécuriser les échanges. |

---

## Termes PKI / ADCS

| Terme | Définition |
|-------|-----------|
| **PKI (Public Key Infrastructure)** | Infrastructure de gestion des certificats numériques. |
| **ADCS (Active Directory Certificate Services)** | Rôle Windows Server fournissant une autorité de certification (CA) intégrée à AD. |
| **CA (Certificate Authority)** | Autorité de certification délivrant des certificats X.509. Dans ce projet : IRIS-Nice-CA. |
| **Enterprise Root CA** | CA racine intégrée à AD. Peut émettre des certificats automatiquement via des templates. |
| **Template de certificat** | Modèle définissant les paramètres d'un type de certificat (usage, durée, algorithme). |
| **RASAndIASServer** | Template de certificat pour les serveurs RADIUS/NPS. |
| **X.509** | Standard définissant le format des certificats numériques. |
| **RSA 2048** | Algorithme de chiffrement asymétrique avec clé de 2048 bits. Utilisé par IRIS-Nice-CA. |
| **SHA256** | Algorithme de hachage utilisé pour la signature des certificats. |
| **CRL (Certificate Revocation List)** | Liste des certificats révoqués publiée par la CA. |

---

## Termes VirtualBox

| Terme | Définition |
|-------|-----------|
| **NAT (Network Address Translation)** | Mode réseau VirtualBox donnant accès internet à la VM via l'IP de l'hôte. IP VM : 10.0.2.15. |
| **Host-Only** | Mode réseau VirtualBox créant un réseau isolé entre les VMs et l'hôte. Pas d'internet direct. |
| **vboxnet0** | Nom de l'adaptateur Host-Only VirtualBox utilisé dans ce projet. Réseau 192.168.50.0/24. |
| **Snapshot** | Photo instantanée de l'état d'une VM permettant un retour arrière rapide. |
| **Guest Additions** | Pilotes VirtualBox améliorant les performances et fonctionnalités de la VM. |

---

## Termes Windows Server

| Terme | Définition |
|-------|-----------|
| **PowerShell** | Shell et langage de script Microsoft. Utilisé pour tous les scripts d'administration de ce projet. |
| **MMC (Microsoft Management Console)** | Interface d'administration Windows accueillant des snap-ins (DNS, DHCP, AD, NPS...). |
| **Logon script** | Script exécuté lors de la connexion d'un utilisateur. Remplacé ici par les GPO Préférences. |
| **GPO Préférences** | Extension des GPO permettant de configurer des lecteurs réseau, imprimantes, registre, avec ciblage fin. |
| **Ciblage GPO (Item-level targeting)** | Mécanisme des GPO Préférences appliquant un paramètre selon des conditions (groupe AD, OS, IP...). |
| **Lazy Connection** | Comportement Windows 11 : les lecteurs réseau semblent déconnectés jusqu'au premier accès réel. |
| **SRV-DC01** | Nom du serveur contrôleur de domaine de ce projet. |
| **SISR-01** | Nom du poste client Windows 11 joint au domaine dans ce projet. |
| **auditpol** | Outil Windows de configuration de la politique d'audit. Les catégories sont identifiées par des GUIDs en français. |
| **Event ID** | Identifiant numérique d'un événement dans le journal Windows. Ex : 4624 = connexion réussie. |

---

## Abréviations utilisées dans le projet

| Abréviation | Signification |
|-------------|--------------|
| RP-01 | Réalisation Professionnelle numéro 1 (BTS SIO) |
| BTS SIO | Brevet de Technicien Supérieur — Services Informatiques aux Organisations |
| SISR | Solutions d'Infrastructure, Systèmes et Réseaux (option BTS SIO) |
| SLAM | Solutions Logicielles et Applications Métiers (option BTS SIO) |
| DC | Domain Controller (Contrôleur de domaine) |
| AD | Active Directory |
| OU | Organizational Unit |
| GPO | Group Policy Object |
| SMB | Server Message Block |
| UNC | Universal Naming Convention |
| ACL | Access Control List |
| NTFS | New Technology File System |
| DHCP | Dynamic Host Configuration Protocol |
| DNS | Domain Name System |
| NPS | Network Policy Server |
| RADIUS | Remote Authentication Dial-In User Service |
| ADCS | Active Directory Certificate Services |
| CA | Certificate Authority |
| PKI | Public Key Infrastructure |
| EAP | Extensible Authentication Protocol |
| VLAN | Virtual Local Area Network |
| LAB | Environnement de laboratoire (virtualisé) |
