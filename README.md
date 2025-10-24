# 🏦 Projet COBOL - Système de Gestion Bancaire

## 📋 Description du Projet

Ce projet est une **application bancaire complète** développée en **COBOL CICS** avec une base de données **DB2**. Il permet de gérer les opérations bancaires d'un client (dépôts, retraits, virements) et d'afficher l'historique des transactions avec pagination.

L'application utilise l'architecture **3270 BMS** (Basic Mapping Support) pour l'interface utilisateur et le modèle **pseudo-conversationnel CICS** pour optimiser les ressources système.

---

## 🎯 Fonctionnalités

### 📊 **Menu Principal (Transaction SN01)**
- Accueil avec navigation vers les différents modules
- Saisie de l'identifiant client
- Redirection vers :
  - Retrait (R)
  - Dépôt (D)
  - Virement (V)
  - Liste des opérations (L)

### 💰 **Module Retrait (Transaction SN02)**
- Vérification du solde disponible
- Débit du compte
- Enregistrement de l'opération en base de données
- Affichage du nouveau solde

### 💵 **Module Dépôt (Transaction SN03)**
- Crédit du compte
- Enregistrement de l'opération
- Affichage du nouveau solde avec centimes

### 🔄 **Module Virement (Transaction SN04)**
- Virement entre deux comptes
- Validation des montants (pas de valeurs négatives ou nulles)
- Vérification du solde suffisant
- Conversion automatique des montants saisis
- Mise à jour des deux comptes (débit et crédit)
- Enregistrement de deux opérations (départ et arrivée)

### 📜 **Module Liste des Opérations (Transaction SN05)**
- Affichage paginé de l'historique des transactions
- **Pagination dynamique** :
  - 10 opérations par page
  - Navigation avec **F7** (page précédente) et **F8** (page suivante)
  - Tri par ordre décroissant (opérations les plus récentes en premier)
- Affichage du nombre total d'opérations
- Détails affichés : ID opération, ID compte, montant, type, date
- Retour au menu avec **F3**

---

## 🗄️ Architecture de la Base de Données

### **Table CLIENT**
```sql
CREATE TABLE API8.CLIENT (
    ID_CLIENT       INTEGER NOT NULL PRIMARY KEY,
    NOM_CLIENT      VARCHAR(50),
    PRENOM_CLIENT   VARCHAR(50),
    ADRESSE         VARCHAR(100),
    TELEPHONE       VARCHAR(15)
);
```

### **Table COMPTE**
```sql
CREATE TABLE API8.COMPTE (
    ID_COMPTE       INTEGER NOT NULL PRIMARY KEY,
    ID_CLIENT       INTEGER NOT NULL,
    SOLDE           DECIMAL(10,2),
    DATE_OUVERTURE  DATE,
    FOREIGN KEY (ID_CLIENT) REFERENCES API8.CLIENT(ID_CLIENT)
);
```

### **Table OPERATION**
```sql
CREATE TABLE API8.OPERATION (
    ID_OPERATION    INTEGER NOT NULL PRIMARY KEY,
    ID_COMPTE       INTEGER NOT NULL,
    MONTANT_OP      DECIMAL(10,2),
    TYPE_OP         CHAR(1),  -- 'D' = Dépôt, 'R' = Retrait, 'V' = Virement
    DATE_OP         DATE,
    FOREIGN KEY (ID_COMPTE) REFERENCES API8.COMPTE(ID_COMPTE)
);
```

---

## 🏗️ Structure du Projet

```
Projet-cobol/
│
├── BMS/                          # Définitions des écrans BMS
│   ├── Accueil/
│   │   └── APNSE01.bms          # Écran du menu principal
│   ├── Depot/
│   │   └── APNSE03.bms          # Écran de dépôt
│   ├── retrait/
│   │   └── APNSE02.bms          # Écran de retrait
│   ├── VIREMENT/
│   │   └── APNSE04.bms          # Écran de virement
│   └── Liste/
│       └── APNSE05.bms          # Écran de liste des opérations
│
├── PROGRAMME/                    # Programmes COBOL
│   ├── API8BM1P.cbl             # Menu principal (SN01)
│   ├── API8RET.cbl              # Gestion des retraits (SN02)
│   ├── API8DEPO.cbl             # Gestion des dépôts (SN03)
│   ├── API3VIR.cbl              # Gestion des virements (SN04)
│   ├── API8LIST.cbl             # Liste paginée des opérations (SN05)
│   └── API8FILDB.cbl            # Utilitaire de remplissage de la base
│
├── CPY/                          # Copybooks
│   ├── client                    # Structure CLIENT (générée par DB2)
│   ├── COMPTE                    # Structure COMPTE (générée par DB2)
│   └── OPE                       # Structure OPERATION (générée par DB2)
│
├── JCL/                          # Jobs de compilation
│   ├── BINPLAN.jcl              # Compilation des BMS
│   ├── JCLLIST                  # Compilation du programme liste
│   └── JCOMPDB2.jcl             # Compilation avec précompilation DB2
│
├── sql/                          # Scripts SQL
│   ├── PROJDB.sql               # Création des tables
│   └── BIDON.sql                # Données de test
│
└── README.md                     # Ce fichier
```

---

## 🚀 Installation et Configuration

### **Prérequis**
- Mainframe avec **CICS Transaction Server**
- **DB2** pour z/OS
- **JCL** pour la compilation
- Émulateur 3270 (ex: x3270, PCOMM)

### **Étapes d'installation**

#### **1. Créer la base de données**
```bash
# Exécuter le script SQL de création des tables
db2 -tvf sql/PROJDB.sql

# Insérer les données de test
db2 -tvf sql/BIDON.sql
```

#### **2. Compiler les BMS**
```bash
# Compiler tous les écrans BMS
# Utiliser le JCL BINPLAN.jcl
```

#### **3. Précompiler et compiler les programmes COBOL**
```bash
# Pour les programmes avec DB2, utiliser JCOMPDB2.jcl
# Exemple pour API8LIST :
# 1. Précompilation DB2
# 2. Compilation COBOL
# 3. Link-edit
```

#### **4. Définir les transactions CICS**
```cics
CEDA DEFINE TRANSACTION(SN01) GROUP(PROJET) PROGRAM(API8BM1P)
CEDA DEFINE TRANSACTION(SN02) GROUP(PROJET) PROGRAM(API8RET)
CEDA DEFINE TRANSACTION(SN03) GROUP(PROJET) PROGRAM(API8DEPO)
CEDA DEFINE TRANSACTION(SN04) GROUP(PROJET) PROGRAM(API3VIR)
CEDA DEFINE TRANSACTION(SN05) GROUP(PROJET) PROGRAM(API8LIST)

CEDA INSTALL GROUP(PROJET)
```

#### **5. Définir les programmes CICS**
```cics
CEDA DEFINE PROGRAM(API8BM1P) GROUP(PROJET) LANGUAGE(COBOL)
CEDA DEFINE PROGRAM(API8RET) GROUP(PROJET) LANGUAGE(COBOL)
CEDA DEFINE PROGRAM(API8DEPO) GROUP(PROJET) LANGUAGE(COBOL)
CEDA DEFINE PROGRAM(API3VIR) GROUP(PROJET) LANGUAGE(COBOL)
CEDA DEFINE PROGRAM(API8LIST) GROUP(PROJET) LANGUAGE(COBOL)
```

#### **6. Définir les mapsets CICS**
```cics
CEDA DEFINE MAPSET(APNSE01) GROUP(PROJET)
CEDA DEFINE MAPSET(APNSE02) GROUP(PROJET)
CEDA DEFINE MAPSET(APNSE03) GROUP(PROJET)
CEDA DEFINE MAPSET(APNSE04) GROUP(PROJET)
CEDA DEFINE MAPSET(APNSE05) GROUP(PROJET)
```

---

## 🎮 Utilisation

### **Démarrer l'application**
```
Depuis un terminal 3270, saisir : SN01
```

### **Navigation**
- **Saisir l'ID client** : Entrer un numéro de client existant (ex: 1, 2, 3)
- **Choisir une opération** :
  - `R` = Retrait
  - `D` = Dépôt
  - `V` = Virement
  - `L` = Liste des opérations

### **Touches de fonction**
- **F3** : Retour au menu principal
- **F7** : Page précédente (dans la liste)
- **F8** : Page suivante (dans la liste)
- **ENTER** : Valider une saisie
- **CLEAR** : Effacer l'écran

---

## 🔧 Fonctionnalités Techniques

### **Gestion de la Pagination (API8LIST.cbl)**

Le module de liste implémente une pagination efficace :

1. **Tri décroissant** : `ORDER BY ID_OPERATION DESC` pour afficher les opérations les plus récentes en premier
2. **Calcul de l'offset** : `WS-PAGE-OFFSET = (WS-PAGE-NUMBER - 1) × 10`
3. **Saut de lignes** : Le curseur SQL saute les pages précédentes avant d'afficher
4. **Comptage total** : Continue la lecture après affichage pour compter toutes les opérations
5. **Sauvegarde d'état** : Utilise la COMMAREA pour conserver le numéro de page entre transactions

### **Validation des Montants (API3VIR.cbl)**

Le module de virement inclut des validations robustes :

- Vérification des champs non vides
- Validation numérique stricte
- Conversion automatique des montants (`PIC X` → `PIC 9` → `PIC S9V99 COMP-3`)
- Vérification du solde suffisant
- Prévention des montants négatifs ou nuls

### **Mode Pseudo-Conversationnel**

Tous les programmes utilisent `RETURN TRANSID` pour libérer les ressources CICS entre chaque interaction utilisateur, optimisant ainsi les performances du système.

---

## 🐛 Résolution des Problèmes Courants

### **Abend 4038**
- **Cause** : Boucle infinie ou erreur de logique
- **Solution** : Vérifier que `VALID-DATA-SW` est réinitialisé correctement

### **Abend ASRA**
- **Cause** : Exception de données (conversion numérique invalide)
- **Solution** : Valider les champs avant conversion, utiliser `IF NUMERIC`

### **Liste vide après pagination**
- **Cause** : Variables mal initialisées ou `SEND DATAONLY` au lieu de `SEND ERASE`
- **Solution** : Utiliser `SEND ERASE` pour F7/F8, initialiser `WS-PAGE-OFFSET` correctement

### **Montants incorrects**
- **Cause** : Mauvaise conversion entre types `PIC X`, `PIC 9`, et `COMP-3`
- **Solution** : Utiliser des variables intermédiaires et éviter `INSPECT REPLACING`

---

## 📚 Concepts COBOL/CICS Utilisés

- **CICS Transaction Server** : Gestion des transactions en ligne
- **BMS (Basic Mapping Support)** : Définition des écrans 3270
- **DB2 Embedded SQL** : Requêtes SQL dans COBOL
- **Curseurs SQL** : `DECLARE`, `OPEN`, `FETCH`, `CLOSE`
- **COMMAREA** : Communication entre transactions
- **XCTL** : Transfert de contrôle entre programmes
- **RETURN TRANSID** : Mode pseudo-conversationnel
- **EIBAID** : Détection des touches de fonction
- **Packed Decimal (COMP-3)** : Stockage efficace des montants

---

## 📊 Statistiques du Projet

- **5 programmes COBOL** (~1500 lignes de code)
- **5 écrans BMS**
- **3 tables DB2**
- **5 transactions CICS**
- Support de la **pagination dynamique**
- **Gestion complète des erreurs**

---

## 👨‍💻 Auteurs

**Antoine Le Provost**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/antoine-le-provost/)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/ALP436)

**Maxime L.**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/maxime-l-5530941b5/)

---

## 📝 Licence

Ce projet est à usage éducatif.

---

## 🎓 Technologies

![COBOL](https://img.shields.io/badge/COBOL-004080?style=for-the-badge&logo=cobol&logoColor=white)
![IBM CICS](https://img.shields.io/badge/IBM%20CICS-054ADA?style=for-the-badge&logo=ibm&logoColor=white)
![DB2](https://img.shields.io/badge/IBM%20DB2-052FAD?style=for-the-badge&logo=ibm&logoColor=white)
![Mainframe](https://img.shields.io/badge/IBM%20z%2FOS-000000?style=for-the-badge&logo=ibm&logoColor=white)

---

## 📞 Support

Pour toute question ou problème, n'hésitez pas à nous contacter via :
- 🔗 **Antoine** : [LinkedIn](https://www.linkedin.com/in/antoine-le-provost/) | [GitHub](https://github.com/ALP436)
- 🔗 **Maxime** : [LinkedIn](https://www.linkedin.com/in/maxime-l-5530941b5/)

---

**⭐ Si ce projet vous a été utile, n'oubliez pas de lui donner une étoile !**

