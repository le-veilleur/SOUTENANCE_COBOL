       IDENTIFICATION DIVISION.
       PROGRAM-ID. API8VIR.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       DATA DIVISION.


       WORKING-STORAGE SECTION.


           EXEC SQL
              INCLUDE SQLCA
           END-EXEC.

           EXEC SQL
              INCLUDE CLIENT
           END-EXEC.

           EXEC SQL
              INCLUDE COMPTE
           END-EXEC.

           EXEC SQL
              INCLUDE OPE
           END-EXEC.

           COPY DFHAID.
           COPY APNSE04.

       01  WS-TEMP-ID-BENEF-ALPHA  PIC X(10).
       01  WS-TEMP-ID-BENEF-NUM    PIC 9(10).
       01  WS-ID-BENEF             PIC S9(9) COMP.


       01  SWITCHES.

           05  VALID-DATA-SW               PIC X    VALUE 'Y'.
               88 VALID-DATA                        VALUE 'Y'.


        01  FLAGS.

           05  SEND-FLAG                   PIC X.
               88  SEND-ERASE                       VALUE '1'.
               88  SEND-DATAONLY                    VALUE '2'.
               88  SEND-DATAONLY-ALARM              VALUE '3'.


       01  WS-COMMUNICATION-AREA  PIC S9(9) COMP.
       01  WS-MONTANT-VIREMENT-ALPHA  PIC X(10).
       01  WS-MONTANT-VIREMENT-NUM PIC 9(10).
       01  WS-MONTANT-VIREMENT   PIC S9(8)V99 COMP-3.
       01  WS-NULL-INDICATOR     PIC S9(4) COMP.
       01  WS-XCTL-PROGRAM-SW    PIC X VALUE 'N'.
           88 XCTL-PROGRAM              VALUE 'Y'.

       LINKAGE SECTION.
       01  DFHCOMMAREA.
           05 DFHCOM-ID-CLIENT PIC S9(9) COMP.


       PROCEDURE DIVISION.


       0000-MAIN-PROCEDURE.
           IF EIBCALEN > ZERO
            MOVE DFHCOM-ID-CLIENT TO WS-COMMUNICATION-AREA
           END-IF.

           EVALUATE TRUE
               WHEN EIBCALEN = 4 
                  MOVE LOW-VALUES TO VIRU1I
                  MOVE LOW-VALUES TO VIRU1O
                  PERFORM 1150-GET-CLIENT-PRENOM
                  SET SEND-ERASE TO TRUE
                  PERFORM 1400-SEND-VIREMENT-MAP

               WHEN EIBAID = DFHCLEAR
                  MOVE LOW-VALUES TO VIRU1I
                  MOVE LOW-VALUES TO VIRU1O
                  SET SEND-ERASE TO TRUE
                  PERFORM 1400-SEND-VIREMENT-MAP

               WHEN EIBAID = DFHPA1 OR DFHPA2 OR DFHPA3
                  CONTINUE

               WHEN EIBAID = DFHPF3 OR DFHPF12
                    SET XCTL-PROGRAM TO TRUE

               WHEN EIBAID = DFHENTER
                  PERFORM 1000-PROCESS-INPUT

               WHEN OTHER
                    MOVE LOW-VALUES TO VIRU1I
                    MOVE LOW-VALUES TO VIRU1O
                    MOVE 'TOUCHE INVALIDE' TO MESVIRO
                    SET SEND-DATAONLY-ALARM TO TRUE
                    PERFORM 1400-SEND-VIREMENT-MAP
           END-EVALUATE.
           
           IF NOT XCTL-PROGRAM
              EXEC CICS
                   RETURN TRANSID('SN04')
                   COMMAREA(WS-COMMUNICATION-AREA)
                   LENGTH(10)
              END-EXEC
           ELSE
              EXEC CICS
                   XCTL PROGRAM('API8BM1P')
                   
              END-EXEC
           END-IF.

       1000-PROCESS-INPUT.
           PERFORM 1100-RECEIVE-VIREMENT-MAP.
           PERFORM 1200-EDIT-VIREMENT-DATA.
           IF VALID-DATA
              PERFORM 1250-CONVERT-MONTANT
           END-IF.
           IF VALID-DATA
              PERFORM 1500-VERIF-SOLDE
              IF VALID-DATA
                 PERFORM 1300-PROCESS-VIREMENT
              END-IF
           END-IF.
           
           IF NOT VALID-DATA
              SET SEND-DATAONLY-ALARM TO TRUE
              PERFORM 1400-SEND-VIREMENT-MAP
           END-IF.

       1100-RECEIVE-VIREMENT-MAP.
           EXEC CICS RECEIVE MAP ('VIRU1')
                MAPSET ('APNSE04')
                INTO(VIRU1I)
           END-EXEC.
    

       1150-GET-CLIENT-PRENOM.
           MOVE DFHCOM-ID-CLIENT TO WS-ID-CLIENT OF DCLCLIENT.
      *    Recuperer nom du client
           EXEC SQL
              SELECT PRENOM_CLIENT
              INTO :WS-PRENOM-CLIENT
              FROM API8.CLIENT
              WHERE ID_CLIENT = :DCLCLIENT.WS-ID-CLIENT
           END-EXEC
           IF SQLCODE = 0
              MOVE WS-PRENOM-CLIENT TO NCPTEO
           ELSE
              MOVE 'CLIENT INCONNU' TO NCPTEO
           END-IF.

       1200-EDIT-VIREMENT-DATA.
           MOVE 'Y' TO VALID-DATA-SW
           IF INPUTDEP1I = SPACES OR INPUTVIRI = SPACES
              MOVE 'N' TO VALID-DATA-SW
              MOVE 'CHAMPS OBLIGATOIRES' TO MESVIRO
              PERFORM 1290-CLEAR-ALL-FIELDS
           ELSE
              IF NOT INPUTDEP1I NUMERIC OR INPUTVIRI IS NOT NUMERIC
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'CHAMPS NUMERIQUES SEULEMENT' TO MESVIRO
                 PERFORM 1290-CLEAR-ALL-FIELDS
              END-IF
           END-IF.

       1250-CONVERT-MONTANT.
      *    Convertir les données saisies
           MOVE INPUTDEP1I TO WS-TEMP-ID-BENEF-ALPHA.
           MOVE WS-TEMP-ID-BENEF-ALPHA TO WS-TEMP-ID-BENEF-NUM.
           MOVE WS-TEMP-ID-BENEF-NUM TO WS-ID-BENEF.
           
      *    Convertir le montant directement (sans passer par X(10))
      *    INPUTVIRI (PIC X(4)) -> WS-MONTANT-VIREMENT-NUM (PIC 9(10))
      *    COBOL converti automatiquement "0025" en 25
           MOVE INPUTVIRI TO WS-MONTANT-VIREMENT-NUM.
           
      *    Puis conversion en COMP-3 avec décimales
           MOVE WS-MONTANT-VIREMENT-NUM TO WS-MONTANT-VIREMENT.

       1300-PROCESS-VIREMENT.
      *    Les conversions ont déjà été faites dans 1250-CONVERT-MONTANT
           EXEC SQL
            UPDATE API8.COMPTE
            SET SOLDE = SOLDE - :WS-MONTANT-VIREMENT
            WHERE ID_CLIENT = :DCLCOMPTE.WS-ID-CLIENT
           END-EXEC.

           EVALUATE SQLCODE
              WHEN 0
                    EXEC SQL
                    UPDATE API8.COMPTE
                    SET SOLDE = SOLDE + :WS-MONTANT-VIREMENT
                    WHERE ID_CLIENT = :WS-ID-BENEF
                    END-EXEC
                   EVALUATE SQLCODE
                      WHEN 0
                         PERFORM 1600-INSERT-OPERATION
                         PERFORM 1610-INSERT-OPERATION-BENEF
                         MOVE 'VIREMENT EFFECTUE' TO MESVIRO
                       WHEN 100
                          MOVE 'N' TO VALID-DATA-SW
                          MOVE 'BENEFICIAIRE INEXISTANT' TO MESVIRO
                          PERFORM 1290-CLEAR-ALL-FIELDS
                       WHEN OTHER
                          MOVE 'N' TO VALID-DATA-SW
                          MOVE 'ERREUR BDD CREDIT' TO MESVIRO
                          PERFORM 1290-CLEAR-ALL-FIELDS
                    END-EVALUATE
              WHEN 100
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'COMPTE EMETTEUR INEXISTANT' TO MESVIRO
                 PERFORM 1290-CLEAR-ALL-FIELDS
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'ERREUR BDD DEBIT' TO MESVIRO
                 PERFORM 1290-CLEAR-ALL-FIELDS
           END-EVALUATE.
           
           SET SEND-DATAONLY TO TRUE
           PERFORM 1400-SEND-VIREMENT-MAP.

       1290-CLEAR-ALL-FIELDS.
      *    Vider tous les champs en cas d'erreur
           MOVE SPACES TO INPUTDEP1O
           MOVE SPACES TO INPUTVIRO
           MOVE SPACES TO INPUTDEP1I
           MOVE SPACES TO INPUTVIRI.



       1400-SEND-VIREMENT-MAP.
           EVALUATE TRUE
              WHEN SEND-ERASE
                 EXEC CICS SEND MAP ('VIRU1')
                      MAPSET ('APNSE04')
                      FROM(VIRU1O)
                      ERASE
                 END-EXEC
              WHEN SEND-DATAONLY
                 EXEC CICS SEND MAP ('VIRU1')
                      MAPSET ('APNSE04')
                      FROM(VIRU1O)
                      DATAONLY
                 END-EXEC
              WHEN SEND-DATAONLY-ALARM
                 EXEC CICS SEND MAP ('VIRU1')
                      MAPSET ('APNSE04')
                      FROM(VIRU1O)
                      DATAONLY
                 END-EXEC
           END-EVALUATE.
   
       1500-VERIF-SOLDE.
           MOVE DFHCOM-ID-CLIENT TO WS-ID-CLIENT OF DCLCOMPTE.
           EXEC SQL
              SELECT SOLDE
              INTO :DCLCOMPTE.WS-SOLDE
              FROM API8.COMPTE
              WHERE ID_CLIENT = :DCLCOMPTE.WS-ID-CLIENT
           END-EXEC.

           EVALUATE SQLCODE
              WHEN 0
                 IF WS-MONTANT-VIREMENT <= ZERO
                    MOVE 'N' TO VALID-DATA-SW
                    MOVE 'MONTANT DOIT ETRE SUPERIEUR A ZERO' TO MESVIRO
                    PERFORM 1290-CLEAR-ALL-FIELDS
                 ELSE
                    IF WS-SOLDE OF DCLCOMPTE < WS-MONTANT-VIREMENT
                       MOVE 'N' TO VALID-DATA-SW
                       MOVE 'SOLDE INSUFFISANT POUR VIREMENT' TO MESVIRO
                       PERFORM 1290-CLEAR-ALL-FIELDS
                    ELSE
                       CONTINUE
                    END-IF
                 END-IF
              WHEN 100
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'COMPTE INEXISTANT' TO MESVIRO
                 PERFORM 1290-CLEAR-ALL-FIELDS
              WHEN OTHER
                 MOVE 'ERREUR BDD' TO MESVIRO
                 MOVE 'N' TO VALID-DATA-SW
                 PERFORM 1290-CLEAR-ALL-FIELDS
           END-EVALUATE.
    

       1600-INSERT-OPERATION.
      *    Recuperer l'ID_COMPTE a partir de ID_CLIENT
           EXEC SQL
              SELECT ID_COMPTE
              INTO :DCLOPERATION.WS-ID-COMPTE
              FROM API8.COMPTE
              WHERE ID_CLIENT = :DCLCOMPTE.WS-ID-CLIENT
           END-EXEC.

           IF SQLCODE = 0
      *       Compte trouve - chercher le MAX des operations
              EXEC SQL
                 SELECT MAX(ID_OPERATION)
                 INTO :DCLOPERATION.WS-ID-OPERATION :WS-NULL-INDICATOR
                 FROM API8.OPERATION
              END-EXEC

      *       Gerer le cas table vide ou valeur NULL
              IF WS-NULL-INDICATOR = -1
      *          Table OPERATION vide - commencer a 1
                 MOVE 1 TO WS-ID-OPERATION OF DCLOPERATION
              ELSE
      *          Operations existent - incrementer le max
                 ADD 1 TO WS-ID-OPERATION OF DCLOPERATION
              END-IF

      *       Preparer les donnees de l'operation
              MOVE WS-MONTANT-VIREMENT TO WS-MONTANT-OP OF DCLOPERATION
              MOVE 'R' TO WS-TYPE-OP OF DCLOPERATION

      *       Inserer l'operation dans la table OPERATION
              EXEC SQL
                 INSERT INTO API8.OPERATION
                    (ID_OPERATION, ID_COMPTE, MONTANT_OP,
                     TYPE_OP, DATE_OP)
                 VALUES
                    (:DCLOPERATION.WS-ID-OPERATION,
                     :DCLOPERATION.WS-ID-COMPTE,
                     :DCLOPERATION.WS-MONTANT-OP,
                     :DCLOPERATION.WS-TYPE-OP,
                     CURRENT DATE)
              END-EXEC

      *       Verifier si l'insertion a reussi
              EVALUATE SQLCODE
                 WHEN 0
                    CONTINUE
                 WHEN -803
                    MOVE 'ID OPERATION EN DOUBLE' TO MESVIRO
                    PERFORM 1290-CLEAR-ALL-FIELDS
                 WHEN -530
                    MOVE 'COMPTE INVALIDE POUR OPERATION' TO MESVIRO
                    PERFORM 1290-CLEAR-ALL-FIELDS
                 WHEN OTHER
                    MOVE 'ERREUR ENREGISTREMENT OPERATION' TO MESVIRO
                    PERFORM 1290-CLEAR-ALL-FIELDS
              END-EVALUATE
           ELSE
              MOVE 'ERREUR COMPTE INTROUVABLE' TO MESVIRO
              PERFORM 1290-CLEAR-ALL-FIELDS
           END-IF.

       1610-INSERT-OPERATION-BENEF.
      *    Recuperer l'ID_COMPTE du beneficiaire a partir de ID_CLIENT
           EXEC SQL
              SELECT ID_COMPTE
              INTO :DCLOPERATION.WS-ID-COMPTE
              FROM API8.COMPTE
              WHERE ID_CLIENT = :WS-ID-BENEF
           END-EXEC.

           IF SQLCODE = 0
      *       Compte trouve - chercher le MAX des operations
              EXEC SQL
                 SELECT MAX(ID_OPERATION)
                 INTO :DCLOPERATION.WS-ID-OPERATION :WS-NULL-INDICATOR
                 FROM API8.OPERATION
              END-EXEC

      *       Gerer le cas table vide ou valeur NULL
              IF WS-NULL-INDICATOR = -1
      *          Table OPERATION vide - commencer a 1
                 MOVE 1 TO WS-ID-OPERATION OF DCLOPERATION
              ELSE
      *          Operations existent - incrementer le max
                 ADD 1 TO WS-ID-OPERATION OF DCLOPERATION
              END-IF

      *       Preparer les donnees de l'operation
              MOVE WS-MONTANT-VIREMENT TO WS-MONTANT-OP OF DCLOPERATION
              MOVE 'D' TO WS-TYPE-OP OF DCLOPERATION

      *       Inserer l'operation dans la table OPERATION
              EXEC SQL
                 INSERT INTO API8.OPERATION
                    (ID_OPERATION, ID_COMPTE, MONTANT_OP,
                     TYPE_OP, DATE_OP)
                 VALUES
                    (:DCLOPERATION.WS-ID-OPERATION,
                     :DCLOPERATION.WS-ID-COMPTE,
                     :DCLOPERATION.WS-MONTANT-OP,
                     :DCLOPERATION.WS-TYPE-OP,
                     CURRENT DATE)
              END-EXEC

      *       Verifier si l'insertion a reussi
              EVALUATE SQLCODE
                 WHEN 0
                    CONTINUE
                 WHEN -803
                    MOVE 'ID OPERATION EN DOUBLE (BENEF)' TO MESVIRO
                    PERFORM 1290-CLEAR-ALL-FIELDS
                 WHEN -530
                    MOVE 'COMPTE INVALIDE OPERATION (BENEF)' TO MESVIRO
                    PERFORM 1290-CLEAR-ALL-FIELDS
                 WHEN OTHER
                    MOVE 'ERREUR ENREGISTREMENT OP (BENEF)' TO MESVIRO
                    PERFORM 1290-CLEAR-ALL-FIELDS
              END-EVALUATE
           ELSE
              MOVE 'ERREUR COMPTE BENEF INTROUVABLE' TO MESVIRO
              PERFORM 1290-CLEAR-ALL-FIELDS
           END-IF.
           