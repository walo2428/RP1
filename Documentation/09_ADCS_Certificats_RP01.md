# 09 — ADCS — Autorité de Certification RP-01

> BTS SIO SISR — Talibi Omar — IRIS Nice — Session 2026

---

## 1. Configuration de la CA

| Paramètre | Valeur |
|-----------|--------|
| Nom | IRIS-Nice-CA |
| Type | Enterprise Root CA |
| CryptoProvider | RSA#Microsoft Software Key Storage Provider |
| Longueur de clé | 2048 bits |
| Algorithme de hachage | SHA256 |
| Validité | 10 ans (jusqu'en 2036) |
| Chemin base de données | C:\Windows\system32\CertLog |
| Chemin logs | C:\Windows\system32\CertLog |

---

## 2. Pourquoi une CA interne

En environnement d'entreprise (et de BTS), une CA publique coûte cher. La CA interne IRIS-Nice-CA permet de :

- Délivrer des certificats de confiance pour NPS RADIUS sans frais
- Contrôler entièrement le cycle de vie des certificats
- Permettre au protocole PEAP de valider l'identité du serveur NPS
- Déployer des certificats sur tous les postes du domaine via GPO

---

## 3. Certificats délivrés

| Sujet | Émetteur | Template | Usage | Expire |
|-------|---------|----------|-------|--------|
| CN=IRIS-Nice-CA | CN=IRIS-Nice-CA | (CA racine) | Signature CA | 2036 |
| CN=SRV-DC01.iris.local | CN=IRIS-Nice-CA | RASAndIASServer | Authentification NPS RADIUS | 2027 |

---

## 4. Template RASAndIASServer

Le template RASAndIASServer est le modèle standard Microsoft pour les serveurs NPS. Il délivre un certificat avec :

- Extended Key Usage : Server Authentication (1.3.6.1.5.5.7.3.1)
- Subject Alternative Name : DNS Name = SRV-DC01.iris.local
- Usage : Digital Signature, Key Encipherment

Ce certificat est utilisé lors de l'authentification PEAP — le client WiFi vérifie que le serveur NPS présente un certificat valide signé par une CA de confiance avant d'envoyer ses credentials.

---

## 5. Procédure d'obtention du certificat NPS

### Etape 1 — Autoriser SRV-DC01 dans certtmpl.msc

```
1. Ouvrir certtmpl.msc
2. Chercher "RAS and IAS Server"
3. Clic droit → Propriétés → onglet Sécurité
4. Ajouter → Types d'objets → cocher Ordinateurs → OK
5. Saisir SRV-DC01$ → Vérifier les noms → OK
6. Cocher Inscrire → Appliquer → OK
```

### Etape 2 — Demander le certificat dans mmc

```
1. Ouvrir mmc
2. Fichier → Ajouter composant → Certificats → Compte d'ordinateur → Local → OK
3. Certificats (Ordinateur local) → Personal
4. Clic droit sur Personal → Toutes les tâches → Demander un nouveau certificat
5. Cliquer Suivant deux fois
6. Cocher "Serveur RAS et IAS" (ou RASAndIASServer)
7. Cliquer Inscrire → Terminer
```

### Vérification

```powershell
Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*SRV-DC01*"} |
    Select-Object Subject, NotAfter, Thumbprint | Format-Table
```

---

## 6. Renouvellement du certificat NPS

Le certificat NPS expire le 18/04/2027. Pour renouveler :

```powershell
# Vérifier la date d'expiration
Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*SRV-DC01*"} |
    Select-Object Subject, NotAfter

# Renouveler (si template toujours actif)
Get-Certificate -Template "RASAndIASServer" -CertStoreLocation "Cert:\LocalMachine\My"
```

---

## 7. Commandes certutil utiles

```powershell
# Vérifier que la CA répond
certutil -ping

# Informations sur la CA
certutil -cainfo

# Voir les templates activés
certutil -CATemplates

# Activer un template
certutil -SetCATemplates +RASAndIASServer

# Lister les certificats délivrés
certutil -view -restrict "Disposition=20" -out "CommonName,NotAfter,RequestID"
```
