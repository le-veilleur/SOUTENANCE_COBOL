       IDENTIFICATION DIVISION.
       PROGRAM-ID. BM1P.
      *===============================================================
      *    PROGRAMME PRINCIPAL DE GESTION BANCAIRE
      *    Gère l'authentification des clients et le routage vers les
      *    programmes de retrait et de dépôt
      *===============================================================
       ENVIRONMENT DIVISION.
       
       CONFIGURATION SECTION.
       
       INPUT-OUTPUT SECTION.
       
       FILE-CONTROL.
       
       DATA DIVISION.

       WORKING-STORAGE SECTION.
      *---------------------------------------------------------------
      *    INCLUSION DES STRUCTURES SQL ET CICS
      *---------------------------------------------------------------
           EXEC SQL
              INCLUDE SQLCA
           END-EXEC.
            
           EXEC SQL
              INCLUDE COMPTE
           END-EXEC.

      * Inclusion des constantes CICS pour les touches de fonction
       COPY DFHAID.
       
      * Inclusion de la map BMS pour l'écran d'accueil
       COPY APNSE01.
      

      *---------------------------------------------------------------
      *    VARIABLES DE TRAVAIL
      *---------------------------------------------------------------
       01  WS-CARD-EXISTANT PIC S9(4) COMP VALUE 0.
      *    Compteur pour vérifier l'existence de la carte bancaire

       01  WS-COMMAREA.
      *    Zone de communication entre programmes CICS
           05 WS-COM-ID-CLIENT PIC X(10).
      *    Identifiant du client transmis aux programmes suivants

       PROCEDURE DIVISION.

       0000-MAIN-PROCEDURE.
      *---------------------------------------------------------------
      *    ROUTINE PRINCIPALE DU PROGRAMME
      *    Détermine si c'est un premier appel ou une réponse utilisateur
      *---------------------------------------------------------------
           EXEC SQL
                SET CURRENT SQLID='API8'
           END-EXEC.
      *    Configuration de l'identifiant SQL pour la base de données

           IF EIBCALEN = 0
      *       Premier appel : affichage de l'écran d'accueil
              PERFORM 1000-ECRAN-ACCUEIL
                 THRU 1000-ECRAN-ACCUEIL-EXIT
           ELSE
      *       Réponse utilisateur : traitement de la saisie
              PERFORM 2000-TRAITER-REPONSE
                 THRU 2000-TRAITER-REPONSE-EXIT
           END-IF.
           GOBACK.

       0000-MAIN-PROCEDURE-EXIT.
           EXIT.


       1000-ECRAN-ACCUEIL.
      *---------------------------------------------------------------
      *    AFFICHAGE DE L'ÉCRAN D'ACCUEIL
      *    Initialise et affiche la map d'authentification
      *---------------------------------------------------------------
           MOVE LOW-VALUES TO ACU1I
      *    Initialisation des champs d'entrée de la map
           MOVE LOW-VALUES TO ACU1O
      *    Initialisation des champs de sortie de la map

 
           EXEC CICS SEND MAP ('ACU1')
                          MAPSET ('APNSE01')
                          ERASE
           END-EXEC.
      *    Envoi de la map avec effacement de l'écran

           EXEC CICS RETURN 
                TRANSID('SN01')
                COMMAREA(WS-COMMAREA)
           END-EXEC.
      *    Retour à CICS avec la transaction et la zone de communication

       1000-ECRAN-ACCUEIL-EXIT.
           EXIT.
         

       2000-TRAITER-REPONSE.       
      *---------------------------------------------------------------
      *    TRAITEMENT DE LA RÉPONSE UTILISATEUR
      *    Authentification et routage vers les programmes appropriés
      *---------------------------------------------------------------
      
           EXEC CICS RECEIVE MAP ('ACU1')
                MAPSET ('APNSE01')
           END-EXEC.
      *    Récupération des données saisies par l'utilisateur
           IF EIBAID = DFHPF3
      *       Touche PF3 : sortie du programme
              EXEC CICS RETURN
              END-EXEC
           END-IF.

      *---------------------------------------------------------------
      *    RÉCUPÉRATION DES DONNÉES DE CONNEXION
      *---------------------------------------------------------------
           MOVE IDCLIENTI TO WS-ID-CLIENT.
      *    Récupération de l'identifiant client saisi
           MOVE PASSCBI TO WS-CODE-CB.
      *    Récupération du code de la carte bancaire saisi
           MOVE IDCLIENTI TO WS-COM-ID-CLIENT.
      *    Préparation de l'ID client pour la transmission

      *---------------------------------------------------------------
      *    VÉRIFICATION DE L'EXISTENCE DE LA CARTE BANCAIRE
      *---------------------------------------------------------------
           EXEC SQL 
      *    Recherche de la combinaison client/carte dans la base
              SELECT COUNT(*) INTO :WS-CARD-EXISTANT FROM API8.COMPTE
              WHERE ID_CLIENT = :WS-ID-CLIENT 
              AND CODE_CB = :WS-CODE-CB
           END-EXEC.
      *    Recherche de la combinaison client/carte dans la base

           IF SQLCODE NOT = 0
      *       Erreur d'accès à la base de données
              MOVE 'ERREUR ACCES BASE DE DONNEES' TO MESCBO
      *    Envoi de la map avec effacement de l'écran
              EXEC CICS SEND MAP ('ACU1')
                          MAPSET ('APNSE01')
                          ERASE
              END-EXEC
      *    Retour à CICS avec la transaction et la zone de communication
              EXEC CICS RETURN
                  TRANSID('SN01')
                  COMMAREA(WS-COMMAREA)
              END-EXEC
           END-IF.

           EXEC SQL COMMIT END-EXEC.
      *    Validation de la transaction SQL

           IF WS-CARD-EXISTANT = 0
      *        Initialisation du champ de message d'erreur
              MOVE LOW-VALUES TO ACU1O
      *        Initialisation du champ de message d'erreur
              MOVE LOW-VALUES TO ACU1I
      *        Initialisation du champ de message d'erreur
              MOVE SPACES TO MESCBO
      *        Initialisation du champ de message d'erreur
              MOVE SPACES TO MESDEPRETO

      *       Carte ou client non trouvé dans la base
              MOVE 'CARTE OU CLIENT NON EXISTANT' TO MESCBO
              EXEC CICS SEND MAP ('ACU1')
                          MAPSET ('APNSE01')
                          ERASE
              END-EXEC
      *    Retour à CICS avec la transaction et la zone de communication
              EXEC CICS RETURN
                  TRANSID('SN01')
                  COMMAREA(WS-COMMAREA)
              END-EXEC  


           END-IF.

      *---------------------------------------------------------------
      *    ROUTAGE VERS LE PROGRAMME APPROPRIÉ
      *    Selon le choix de l'utilisateur (Retrait ou Dépôt)
      *---------------------------------------------------------------
           EVALUATE RETDEPI
              WHEN 'R'         
      *          Choix "Retrait" : transfert vers RETPROG
                 EXEC CICS XCTL PROGRAM('RETPROG')
                    COMMAREA(WS-COMMAREA)
                    LENGTH(LENGTH OF WS-COMMAREA)
                 END-EXEC
              WHEN 'D'
      *          Choix "Dépôt" : transfert vers DEPROG
                 EXEC CICS XCTL PROGRAM('DEPROG')
                    COMMAREA(WS-COMMAREA)
                    LENGTH(LENGTH OF WS-COMMAREA)
                 END-EXEC
              WHEN OTHER
      *          Choix invalide : affichage d'un message d'erreur
                 MOVE 'CHOIX INVALIDE' TO MESDEPRETO

                 EXEC CICS SEND MAP ('ACU1')
                          MAPSET ('APNSE01')
                          ERASE
                 END-EXEC
                 EXEC CICS RETURN
                     TRANSID('SN01')
                     COMMAREA(WS-COMMAREA)
                 END-EXEC
           END-EVALUATE.
  
       2000-TRAITER-REPONSE-EXIT.
           EXIT.

           STOP RUN.