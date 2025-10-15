       IDENTIFICATION DIVISION.
       PROGRAM-ID. RETPROG.
      *===============================================================
      *    PROGRAMME DE GESTION DES RETRAITS BANCAIRES
      *    Gère l'interface utilisateur pour les opérations de retrait
      *    et l'interaction avec la base de données
      *===============================================================
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       DATA DIVISION.
     
       WORKING-STORAGE SECTION.
      *---------------------------------------------------------------
      *    INCLUSION DES STRUCTURES SQL ET CICS
      *---------------------------------------------------------------
           COPY DFHAID.
      *    Inclusion des constantes CICS pour les touches de fonction

           EXEC SQL
              INCLUDE SQLCA
           END-EXEC.
      *    Inclusion de la structure de communication SQL

           EXEC SQL
              INCLUDE CLIENT
           END-EXEC.
      *    Inclusion de la structure de données CLIENT
           
           EXEC SQL
              INCLUDE COMPTE
           END-EXEC.
      *    Inclusion de la structure de données COMPTE

           EXEC SQL
              INCLUDE OPE
           END-EXEC.
      *    Inclusion de la structure de données OPERATION

           COPY APNSE02.
      *    Inclusion de la map BMS pour l'écran de retrait
    

       LINKAGE SECTION.
      *---------------------------------------------------------------
      *    ZONE DE COMMUNICATION ENTRE PROGRAMMES
      *---------------------------------------------------------------
       01  WS-COMMAREA.
      *    Zone de communication reçue du programme appelant
           05 WS-COM-ID-CLIENT PIC X(10).
      *    Identifiant du client transmis depuis BM1P

       PROCEDURE DIVISION USING WS-COMMAREA.

       0000-MAIN-PROCEDURE.
      *---------------------------------------------------------------
      *    ROUTINE PRINCIPALE DU PROGRAMME DE RETRAIT
      *    Initialise la connexion à la base et affiche l'écran
      *---------------------------------------------------------------

           EXEC SQL
              SET CURRENT SQLID='API8'
           END-EXEC.
      *    Configuration de l'identifiant SQL pour la base de données

           PERFORM 1000-AFFICHER-ECRAN   
              THRU 1000-AFFICHER-ECRAN-EXIT.
      *    Appel de la routine d'affichage de l'écran de retrait
           
           GOBACK.

       0000-MAIN-PROCEDURE-EXIT.
           EXIT.

       1000-AFFICHER-ECRAN.
      *---------------------------------------------------------------
      *    AFFICHAGE DE L'ÉCRAN DE RETRAIT
      *    Initialise et affiche la map de retrait pour l'utilisateur
      *---------------------------------------------------------------
           MOVE LOW-VALUES TO RETU1I
      *    Initialisation des champs d'entrée de la map de retrait
           MOVE LOW-VALUES TO RETU1O
      *    Initialisation des champs de sortie de la map de retrait
       
           EXEC CICS SEND MAP ('RETU1')
                MAPSET ('APNSE02')
                ERASE
           END-EXEC.
      *    Envoi de la map de retrait avec effacement de l'écran

           EXEC CICS RETURN 
                TRANSID('SN02')
                COMMAREA(WS-COMMAREA)
           END-EXEC.
      *    Retour à CICS avec la transaction SN02 et la zone de communication

       1000-AFFICHER-ECRAN-EXIT.
           EXIT.
       
           
       