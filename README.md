# Bancora - Système Bancaire Intégré Mainframe

## 📋 Description du Projet

Bancora est un système bancaire complet développé pour environnement **Mainframe z/OS**, utilisant **COBOL**, **JCL** et **ISPF**. Le système simule de manière réaliste le fonctionnement d'une banque moderne en environnement grand système, incluant la gestion des comptes, des clients et un distributeur automatique de billets (DAB).

## 🏗️ Architecture du Projet

```
Projet-cobol/
├── CPY/                    # Copybooks COBOL
│   ├── client.txt         # Structure données client
│   ├── COMPTE.txt         # Structure données compte
│   └── OPE.txt            # Structure données opération
├── PROGRAMME/             # Programmes COBOL batch
│   └── Client.cbl         # Programme gestion clients
├── sequentiel/            # Fichiers séquentiels (datasets)
│   ├── FCLI.txt           # Fichier clients
│   └── FCOMPT.txt         # Fichier comptes
└── sql/                   # Scripts DB2
    └── PROJDB.sql         # DDL de création des tables
```

## ✨ Fonctionnalités Principales

### 👥 Gestion des Clients
- **Création** de nouveaux clients
- **Modification** des informations client
- **Suppression** des comptes clients
- **Consultation** via ISPF

### 💳 Gestion des Comptes
- **Ouverture** de comptes bancaires
- **Clôture** de comptes
- **Suivi** des soldes
- **Gestion** multi-comptes

### 💰 Opérations Financières
- **Dépôt** sur comptes
- **Retrait** depuis comptes
- **Virement** entre comptes
- **Historique** des transactions

### 🏦 Gestion des Crédits
- **Création** d'emprunts
- **Suivi** des remboursements
- **Gestion** des échéances
- **Calcul** des intérêts

### 🏧 Distributeur Automatique de Billets (DAB)
- **Authentification** par carte et PIN
- **Consultation** du solde
- **Retrait** d'argent
- Interface CICS

### 🗄️ Intégration DB2
- Tables DB2 pour toutes les entités
- **Curseurs** pour traitement batch
- **Transactions** COMMIT/ROLLBACK
- **Intégrité** référentielle

## 🛠️ Technologies Mainframe

| Technologie | Usage |
|------------|-------|
| **COBOL** | Langage de programmation des applications batch et online |
| **DB2** | Système de gestion de base de données relationnelle |
| **JCL** | Job Control Language pour l'exécution des programmes batch |
| **ISPF** | Interface utilisateur pour la consultation et saisie |
| **CICS** | Gestionnaire transactionnel pour le DAB (online) |
| **VSAM** | Virtual Storage Access Method pour fichiers séquentiels |

## 📊 Structure des Données

### Fichiers VSAM
- **FCLI** : Fichier clients (Sequenced)
- **FCOMPT** : Fichier comptes (Sequenced)
- **Organisation** : Indexed Sequential

### Tables DB2
```sql
CLIENT (NUM_CLI, NOM, PRENOM, ADRESSE, TELEPHONE)
COMPTE (NUM_CPT, NUM_CLI, TYPE_CPT, SOLDE, DATE_OUVERTURE)
OPERATION (ID_OPE, NUM_CPT, TYPE_OPE, MONTANT, DATE_OPE)
CREDIT (NUM_CREDIT, NUM_CPT, MONTANT, TAUX, ECHEANCES)
```

### Copybooks COBOL
- Structures de données partagées entre programmes
- Définitions FD pour fichiers séquentiels
- Structures DCLGEN pour tables DB2

## 🚀 Installation et Configuration

### Prérequis
- Environnement z/OS avec TSO/ISPF
- Compilateur COBOL Enterprise (version 4.2 ou supérieure)
- DB2 pour z/OS
- CICS Transaction Server (pour module DAB)
- Droits d'accès aux datasets

### Étapes d'installation

1. **Allocation des datasets**
   ```jcl
   //ALLOC   EXEC PGM=IEFBR14
   //FCLI    DD DSN=BANCORA.FCLI,
   //           DISP=(NEW,CATLG,DELETE),
   //           SPACE=(CYL,(10,5)),
   //           DCB=(RECFM=FB,LRECL=200,BLKSIZE=2000)
   ```

2. **Création des tables DB2**
   - Se connecter à DB2 via SPUFI ou QMF
   - Exécuter le script `PROJDB.sql`
   - Vérifier les BIND pour les plans

3. **Compilation des programmes**
   ```jcl
   //COMPILE EXEC PROC=IGYWCL,
   //        PARM.COBOL='LIB,APOST,NODYNAM'
   //COBOL.SYSIN DD DSN=BANCORA.SOURCE(CLIENT),DISP=SHR
   //COBOL.SYSLIB DD DSN=BANCORA.CPY,DISP=SHR
   ```

4. **Configuration ISPF**
   - Définir les panels ISPF
   - Configurer les tables de commandes
   - Associer les programmes aux transactions

5. **Configuration CICS**
   - Définir les transactions CICS (ex: BDAB pour DAB)
   - Installer les programmes en région CICS
   - Configurer les fichiers VSAM

## 📝 Exemples JCL

### Exécution Programme Batch
```jcl
//BANCORA JOB (ACCT),'GESTION CLIENT',
//        CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//STEP1   EXEC PGM=CLIENT,REGION=4M
//STEPLIB DD DSN=BANCORA.LOADLIB,DISP=SHR
//FCLI    DD DSN=BANCORA.FCLI,DISP=SHR
//FCOMPT  DD DSN=BANCORA.FCOMPT,DISP=SHR
//SYSOUT  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
```

### Traitement DB2
```jcl
//DB2JOB  JOB (ACCT),'DB2 UPDATE',
//        CLASS=A,MSGCLASS=X
//STEP1   EXEC DSNUPROC,SYSTEM=DB2P,UID='BANCORA',
//        UTPROC=''
//DSNUPROC.SYSIN DD *
  UPDATE BANCORA.COMPTE
  SET SOLDE = SOLDE + 1000
  WHERE NUM_CPT = '12345678'
/*
```

## 🔒 Sécurité Mainframe

- **RACF** : Contrôle d'accès aux ressources
- **Encryption** : Protection des données sensibles via ICSF
- **Audit SMF** : Traçabilité via SMF (System Management Facility)
- **CICS Security** : Transaction-level security
- **DB2 Grants** : Autorisations au niveau table

## 📈 Performances

- **Buffering** : Optimisation via buffer pools DB2
- **Indexation** : Index sur clés primaires et étrangères
- **Batch Window** : Traitements nocturnes optimisés
- **VSAM Tuning** : CI/CA sizing approprié
- **COBOL Optimization** : OPTIMIZE(FULL) en compilation

## 🎯 Objectifs du Projet

1. Démontrer les capacités COBOL en environnement mainframe
2. Intégrer COBOL/DB2 de manière professionnelle
3. Simuler un système bancaire production-ready
4. Maîtriser JCL et ISPF pour applications complexes
5. Comprendre l'architecture des grands systèmes bancaires

## 🔮 Évolutions Futures

- [ ] Module de reporting batch (COBOL/SORT)
- [ ] Interface REXX pour automatisation
- [ ] Intégration MQ Series pour messaging
- [ ] Module de sauvegarde/restauration
- [ ] Dashboard ISPF avec statistiques
- [ ] Export vers fichiers XML/JSON
- [ ] Module d'archivage HSM
- [ ] Intégration z/OS Connect pour API REST

## 📝 Utilisation

### Accès via ISPF
```
Menu Principal BANCORA
---------------------------------
Option ===>

1  - Gestion des clients
2  - Gestion des comptes  
3  - Opérations financières
4  - Gestion des crédits
5  - Administration
X  - Exit
```

### Transaction CICS DAB
```
BDAB - Distributeur Automatique
---------------------------------
Entrez votre numéro de carte:
Entrez votre code PIN:
```

## 📄 Licence

Projet développé dans le cadre de l'apprentissage des technologies mainframe (COBOL, JCL, DB2, ISPF, CICS).

## 👨‍💻 Auteur

[le-veilleur] - Développeur Mainframe
[https://github.com/ALP436] - Développeur Mainframe
---

**Bancora** - *Système bancaire pour z/OS Mainframe* 🏦💻
