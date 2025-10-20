       IDENTIFICATION DIVISION.
       PROGRAM-ID. API3RET.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       DATA DIVISION.


       WORKING-STORAGE SECTION.

           COPY DFHAID.

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

           COPY APNSE02.


       01  SWITCHES.

           05  VALID-DATA-SW               PIC X    VALUE 'Y'.
               88 VALID-DATA                        VALUE 'Y'.


        01  FLAGS.

           05  SEND-FLAG                   PIC X.
               88  SEND-ERASE                       VALUE '1'.
               88  SEND-DATAONLY                    VALUE '2'.
               88  SEND-DATAONLY-ALARM              VALUE '3'.


       01  WS-COMMUNICATION-AREA  PIC S9(9) COMP.
       01  WS-MONTANT-RETRAIT    PIC S9(8)V99 COMP-3.
       01  WS-CHAMPS-REMPLIS     PIC 9 VALUE 0.
       01  WS-NULL-INDICATOR     PIC S9(4) COMP.

       01  WS-SOLDE-ALPHA   PIC X(10).
       01  WS-SOLDE-NUM     PIC 9(10).
       01  WS-SOLDE-EDITED  PIC ZZZ,ZZ9.99.
       01  WS-XCTL-PROGRAM-SW     PIC X VALUE 'N'.
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
               WHEN EIBCALEN = ZERO OR 4
                  MOVE LOW-VALUES TO RETU1I
                  MOVE LOW-VALUES TO RETU1O
                  PERFORM 1150-GET-CLIENT-PRENOM
                  SET SEND-ERASE TO TRUE
                  PERFORM 1400-SEND-RETRAIT-MAP

               WHEN EIBAID = DFHCLEAR
                  MOVE LOW-VALUES TO RETU1I
                  MOVE LOW-VALUES TO RETU1O
                  SET SEND-ERASE TO TRUE
                  PERFORM 1400-SEND-RETRAIT-MAP

               WHEN EIBAID = DFHPA1 OR DFHPA2 OR DFHPA3
                  CONTINUE

               WHEN EIBAID = DFHPF3 OR DFHPF12
                    SET XCTL-PROGRAM TO TRUE

               WHEN EIBAID = DFHENTER
                  PERFORM 1000-PROCESS-INPUT

               WHEN OTHER
                    MOVE LOW-VALUES TO RETU1I
                    MOVE LOW-VALUES TO RETU1O
                    MOVE 'TOUCHE INVALIDE' TO MESRETO
                    SET SEND-DATAONLY-ALARM TO TRUE
                    PERFORM 1400-SEND-RETRAIT-MAP
           END-EVALUATE.

           IF NOT XCTL-PROGRAM
              EXEC CICS
                   RETURN TRANSID('SN32')
                   COMMAREA(WS-COMMUNICATION-AREA)
                   LENGTH(10)
              END-EXEC
           ELSE
              EXEC CICS
                   XCTL PROGRAM('API3BM1P')
                   COMMAREA(WS-COMMUNICATION-AREA)
                   LENGTH(LENGTH OF WS-COMMUNICATION-AREA)
              END-EXEC
           END-IF.

       1000-PROCESS-INPUT.
           PERFORM 1100-RECEIVE-RETRAIT-MAP.
           PERFORM 1200-EDIT-RETRAIT-DATA.
           IF VALID-DATA
               PERFORM 1300-VERIF-SOLDE
           ELSE
               SET SEND-DATAONLY-ALARM TO TRUE
               PERFORM 1400-SEND-RETRAIT-MAP
           END-IF.

       1100-RECEIVE-RETRAIT-MAP.
           EXEC CICS RECEIVE MAP ('RETU1')
                MAPSET ('APNSE02')
                INTO(RETU1I)
           END-EXEC.

       1150-GET-CLIENT-PRENOM.
      *    Recuperer nom du client
           EXEC SQL
              SELECT PRENOM_CLIENT
              INTO :WS-PRENOM-CLIENT
              FROM API3.CLIENT
              WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
           END-EXEC
           IF SQLCODE = 0
              MOVE WS-PRENOM-CLIENT TO NCPTEO
      *       Recuperer aussi le solde initial
              EXEC SQL
                 SELECT SOLDE
                 INTO :WS-SOLDE
                 FROM API3.COMPTE
                 WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
              END-EXEC
              IF SQLCODE = 0
      *          Convertir et afficher le solde initial avec format
                 MOVE WS-SOLDE TO WS-SOLDE-NUM
                 MOVE WS-SOLDE-NUM TO WS-SOLDE-EDITED
                 MOVE WS-SOLDE-EDITED TO SOLDEO
              ELSE
                 MOVE 'N/A' TO SOLDEO
              END-IF
           ELSE
              MOVE 'CLIENT INCONNU' TO NCPTEO
              MOVE 'N/A' TO SOLDEO
           END-IF.

       1200-EDIT-RETRAIT-DATA.
           MOVE 'Y' TO VALID-DATA-SW
      *    D'abord compter combien de champs sont remplis
           PERFORM 1205-COUNT-FILLED-FIELDS
      *    Valider qu'UN SEUL champ est rempli
           IF WS-CHAMPS-REMPLIS = 0
              MOVE 'N' TO VALID-DATA-SW
              MOVE 'SELECTIONNER UN MONTANT' TO MESRETO
              PERFORM 1290-CLEAR-ALL-FIELDS
           ELSE
              IF WS-CHAMPS-REMPLIS > 1
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'UN SEUL MONTANT AUTORISE' TO MESRETO
                 PERFORM 1290-CLEAR-ALL-FIELDS
              ELSE
      *          Un seul champ rempli - valider seulement celui rempli
                 IF MT10I = 'Y'
                    PERFORM 1210-VALIDATE-MT10
                 END-IF
                 IF MT20I = 'Y'
                    PERFORM 1220-VALIDATE-MT20
                 END-IF
                 IF MT30I = 'Y'
                    PERFORM 1230-VALIDATE-MT30
                 END-IF
                 IF MT40I = 'Y'
                    PERFORM 1240-VALIDATE-MT40
                 END-IF
                 IF MT50I = 'Y'
                    PERFORM 1250-VALIDATE-MT50
                 END-IF
                 IF MT60I = 'Y'
                    PERFORM 1260-VALIDATE-MT60
                 END-IF
                 IF MT70I = 'Y'
                    PERFORM 1270-VALIDATE-MT70
                 END-IF
                 IF MTAUTREI NOT = SPACES AND MTAUTREI IS NUMERIC
                    PERFORM 1280-VALIDATE-MTAUTRE
                 END-IF
              END-IF
           END-IF.

       1205-COUNT-FILLED-FIELDS.
           MOVE 0 TO WS-CHAMPS-REMPLIS
           IF MT10I = 'Y'
              ADD 1 TO WS-CHAMPS-REMPLIS
           END-IF
           IF MT20I = 'Y'
              ADD 1 TO WS-CHAMPS-REMPLIS
           END-IF
           IF MT30I = 'Y'
              ADD 1 TO WS-CHAMPS-REMPLIS
           END-IF
           IF MT40I = 'Y'
              ADD 1 TO WS-CHAMPS-REMPLIS
           END-IF
           IF MT50I = 'Y'
              ADD 1 TO WS-CHAMPS-REMPLIS
           END-IF
           IF MT60I = 'Y'
              ADD 1 TO WS-CHAMPS-REMPLIS
           END-IF
           IF MT70I = 'Y'
              ADD 1 TO WS-CHAMPS-REMPLIS
           END-IF
      *    Verifier MTAUTRE seulement s'il contient des chiffres
           IF MTAUTREI NOT = SPACES AND MTAUTREI IS NUMERIC
              ADD 1 TO WS-CHAMPS-REMPLIS
           END-IF.

       1210-VALIDATE-MT10.
      *    Convertir minuscule en majuscule
           IF MT10I = 'y'
              MOVE 'Y' TO MT10I
           END-IF
           EVALUATE TRUE
              WHEN MT10I = 'Y'
                 CONTINUE
              WHEN MT10I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT10 INVALIDE - Y OU VIDE SEULEMENT' TO MESRETO
                 PERFORM 1290-CLEAR-ALL-FIELDS
           END-EVALUATE.

       1220-VALIDATE-MT20.
      *    Convertir minuscule en majuscule
           IF MT20I = 'y'
              MOVE 'Y' TO MT20I
           END-IF
           EVALUATE TRUE
              WHEN MT20I = 'Y'
                 CONTINUE
              WHEN MT20I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT20 INVALIDE - Y OU VIDE SEULEMENT' TO MESRETO
                 PERFORM 1290-CLEAR-ALL-FIELDS
           END-EVALUATE.

       1230-VALIDATE-MT30.
      *    Convertir minuscule en majuscule
           IF MT30I = 'y'
              MOVE 'Y' TO MT30I
           END-IF
           EVALUATE TRUE
              WHEN MT30I = 'Y'
                 CONTINUE
              WHEN MT30I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT30 INVALIDE - Y OU VIDE SEULEMENT' TO MESRETO
                 PERFORM 1290-CLEAR-ALL-FIELDS
           END-EVALUATE.

       1240-VALIDATE-MT40.
      *    Convertir minuscule en majuscule
           IF MT40I = 'y'
              MOVE 'Y' TO MT40I
           END-IF
           EVALUATE TRUE
              WHEN MT40I = 'Y'
                 CONTINUE
              WHEN MT40I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT40 INVALIDE - Y OU VIDE SEULEMENT' TO MESRETO
                 PERFORM 1290-CLEAR-ALL-FIELDS
           END-EVALUATE.

       1250-VALIDATE-MT50.
      *    Convertir minuscule en majuscule
           IF MT50I = 'y'
              MOVE 'Y' TO MT50I
           END-IF
           EVALUATE TRUE
              WHEN MT50I = 'Y'
                 CONTINUE
              WHEN MT50I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT50 INVALIDE Y OU VIDE SEULEMENT' TO MESRETO
                 PERFORM 1290-CLEAR-ALL-FIELDS
           END-EVALUATE.

       1260-VALIDATE-MT60.
      *    Convertir minuscule en majuscule
           IF MT60I = 'y'
              MOVE 'Y' TO MT60I
           END-IF
           EVALUATE TRUE
              WHEN MT60I = 'Y'
                 CONTINUE
              WHEN MT60I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT60 INVALIDE - Y OU VIDE SEULEMENT' TO MESRETO
                 PERFORM 1290-CLEAR-ALL-FIELDS
           END-EVALUATE.

       1270-VALIDATE-MT70.
      *    Convertir minuscule en majuscule
           IF MT70I = 'y'
              MOVE 'Y' TO MT70I
           END-IF
           EVALUATE TRUE
              WHEN MT70I = 'Y'
                 CONTINUE
              WHEN MT70I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT70 INVALIDE - Y OU VIDE SEULEMENT' TO MESRETO
                 PERFORM 1290-CLEAR-ALL-FIELDS
           END-EVALUATE.

       1280-VALIDATE-MTAUTRE.
           IF MT10I = 'Y' OR MT20I = 'Y' OR MT30I = 'Y'
              CONTINUE
           ELSE
              IF MT40I = 'Y' OR MT50I = 'Y' OR MT60I = 'Y'
                 CONTINUE
              ELSE
                 IF MT70I = 'Y'
                    CONTINUE
                 ELSE
                    EVALUATE TRUE
                       WHEN MTAUTREI = SPACES
                          CONTINUE
                       WHEN MTAUTREI IS NUMERIC
                          CONTINUE
                       WHEN OTHER
                          MOVE 'N' TO VALID-DATA-SW
                          MOVE 'MTAUTRE INVALIDE - NUMERIQUE SEULEMENT'
                            TO MESRETO
                          PERFORM 1290-CLEAR-ALL-FIELDS
                    END-EVALUATE
                 END-IF
              END-IF
           END-IF.


       1300-VERIF-SOLDE.
              EVALUATE TRUE
                  WHEN MT10I = 'Y'
                       MOVE 10 TO WS-MONTANT-RETRAIT
                       PERFORM 1350-REQUETE-SQL
                       EVALUATE SQLCODE
                           WHEN 0
                             IF WS-SOLDE >= 10
                                 MOVE WS-SOLDE TO WS-SOLDE-NUM
                                 MOVE WS-SOLDE-NUM TO WS-SOLDE-ALPHA
                                 MOVE WS-SOLDE-ALPHA TO SOLDEO
                                 PERFORM 1500-UPDATE-SOLDE
                             ELSE
                                 MOVE 'N' TO VALID-DATA-SW
                                 MOVE 'SOLDE INSUFFISANT' TO MESRETO
                             END-IF

                           WHEN 100
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'COMPTE INEXISTANT' TO MESRETO

                           WHEN OTHER
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'ERREUR BDD' TO MESRETO
                       END-EVALUATE

                  WHEN MT20I = 'Y'
                       MOVE 20 TO WS-MONTANT-RETRAIT
                       PERFORM 1350-REQUETE-SQL
                       EVALUATE SQLCODE
                           WHEN 0
                             IF WS-SOLDE >= 20
                                 MOVE WS-SOLDE TO WS-SOLDE-NUM
                                 MOVE WS-SOLDE-NUM TO WS-SOLDE-ALPHA
                                 MOVE WS-SOLDE-ALPHA TO SOLDEO
                                 PERFORM 1500-UPDATE-SOLDE
                             ELSE
                                 MOVE 'N' TO VALID-DATA-SW
                                 MOVE 'SOLDE INSUFFISANT' TO MESRETO
                             END-IF

                           WHEN 100
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'COMPTE INEXISTANT' TO MESRETO

                           WHEN OTHER
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'ERREUR BDD' TO MESRETO
                       END-EVALUATE

                  WHEN MT30I = 'Y'
                       MOVE 30 TO WS-MONTANT-RETRAIT
                       PERFORM 1350-REQUETE-SQL
                       EVALUATE SQLCODE
                           WHEN 0
                             IF WS-SOLDE >= 30
                                 MOVE WS-SOLDE TO WS-SOLDE-NUM
                                 MOVE WS-SOLDE-NUM TO WS-SOLDE-ALPHA
                                 MOVE WS-SOLDE-ALPHA TO SOLDEO
                                 PERFORM 1500-UPDATE-SOLDE
                             ELSE
                                 MOVE 'N' TO VALID-DATA-SW
                                 MOVE 'SOLDE INSUFFISANT' TO MESRETO
                             END-IF

                           WHEN 100
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'COMPTE INEXISTANT' TO MESRETO

                           WHEN OTHER
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'ERREUR BDD' TO MESRETO
                       END-EVALUATE

                  WHEN MT40I = 'Y'
                       MOVE 40 TO WS-MONTANT-RETRAIT
                       PERFORM 1350-REQUETE-SQL
                       EVALUATE SQLCODE
                           WHEN 0
                             IF WS-SOLDE >= 40
                                 MOVE WS-SOLDE TO WS-SOLDE-NUM
                                 MOVE WS-SOLDE-NUM TO WS-SOLDE-ALPHA
                                 MOVE WS-SOLDE-ALPHA TO SOLDEO
                                 PERFORM 1500-UPDATE-SOLDE
                             ELSE
                                 MOVE 'N' TO VALID-DATA-SW
                                 MOVE 'SOLDE INSUFFISANT' TO MESRETO
                             END-IF

                           WHEN 100
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'COMPTE INEXISTANT' TO MESRETO

                           WHEN OTHER
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'ERREUR BDD' TO MESRETO
                       END-EVALUATE

                  WHEN MT50I = 'Y'
                       MOVE 50 TO WS-MONTANT-RETRAIT
                       PERFORM 1350-REQUETE-SQL
                       EVALUATE SQLCODE
                           WHEN 0
                             IF WS-SOLDE >= 50
                                 MOVE WS-SOLDE TO WS-SOLDE-NUM
                                 MOVE WS-SOLDE-NUM TO WS-SOLDE-ALPHA
                                 MOVE WS-SOLDE-ALPHA TO SOLDEO
                                 PERFORM 1500-UPDATE-SOLDE
                             ELSE
                                 MOVE 'N' TO VALID-DATA-SW
                                 MOVE 'SOLDE INSUFFISANT' TO MESRETO
                             END-IF

                           WHEN 100
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'COMPTE INEXISTANT' TO MESRETO

                           WHEN OTHER
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'ERREUR BDD' TO MESRETO
                       END-EVALUATE

                  WHEN MT60I = 'Y'
                       MOVE 60 TO WS-MONTANT-RETRAIT
                       PERFORM 1350-REQUETE-SQL
                       EVALUATE SQLCODE
                           WHEN 0
                             IF WS-SOLDE >= 60
                                 MOVE WS-SOLDE TO WS-SOLDE-NUM
                                 MOVE WS-SOLDE-NUM TO WS-SOLDE-ALPHA
                                 MOVE WS-SOLDE-ALPHA TO SOLDEO
                                 PERFORM 1500-UPDATE-SOLDE
                             ELSE
                                 MOVE 'N' TO VALID-DATA-SW
                                 MOVE 'SOLDE INSUFFISANT' TO MESRETO
                             END-IF

                           WHEN 100
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'COMPTE INEXISTANT' TO MESRETO

                           WHEN OTHER
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'ERREUR BDD' TO MESRETO
                       END-EVALUATE

                  WHEN MT70I = 'Y'
                       MOVE 70 TO WS-MONTANT-RETRAIT
                       PERFORM 1350-REQUETE-SQL
                       EVALUATE SQLCODE
                        WHEN 0
                         IF WS-SOLDE >= 70
                          MOVE WS-SOLDE TO WS-SOLDE-NUM
                          MOVE WS-SOLDE-NUM TO WS-SOLDE-ALPHA
                          MOVE WS-SOLDE-ALPHA TO SOLDEO
                          PERFORM 1500-UPDATE-SOLDE
                         ELSE
                          MOVE 'N' TO VALID-DATA-SW
                          MOVE 'SOLDE INSUFFISANT' TO MESRETO
                         END-IF
                        WHEN 100
                          MOVE 'N' TO VALID-DATA-SW
                          MOVE 'COMPTE INEXISTANT' TO MESRETO
                        WHEN OTHER
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'ERREUR BDD' TO MESRETO
                       END-EVALUATE

                  WHEN MTAUTREI IS NUMERIC
                       MOVE MTAUTREI TO WS-MONTANT-RETRAIT
                       PERFORM 1350-REQUETE-SQL
                       EVALUATE SQLCODE
                           WHEN 0
                             IF WS-SOLDE >= WS-MONTANT-RETRAIT
                                 MOVE WS-SOLDE TO WS-SOLDE-NUM
                                 MOVE WS-SOLDE-NUM TO WS-SOLDE-ALPHA
                                 MOVE WS-SOLDE-ALPHA TO SOLDEO
                                 PERFORM 1500-UPDATE-SOLDE
                             ELSE
                                 MOVE 'N' TO VALID-DATA-SW
                                 MOVE 'SOLDE INSUFFISANT' TO MESRETO
                             END-IF

                           WHEN 100
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'COMPTE INEXISTANT' TO MESRETO

                           WHEN OTHER
                             MOVE 'N' TO VALID-DATA-SW
                             MOVE 'ERREUR BDD' TO MESRETO
                       END-EVALUATE

                  WHEN OTHER
                       MOVE 'N' TO VALID-DATA-SW
                       MOVE 'SELECTIONNER UN MONTANT' TO MESRETO

              END-EVALUATE.


       1350-REQUETE-SQL.
           EXEC SQL
              SELECT SOLDE
              INTO :WS-SOLDE
              FROM API3.COMPTE
              WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
           END-EXEC.

       1400-SEND-RETRAIT-MAP.
           EVALUATE TRUE
              WHEN SEND-ERASE
                 EXEC CICS SEND MAP ('RETU1')
                      MAPSET ('APNSE02')
                      FROM(RETU1O)
                      ERASE
                 END-EXEC
              WHEN SEND-DATAONLY
                 EXEC CICS SEND MAP ('RETU1')
                      MAPSET ('APNSE02')
                      FROM(RETU1O)
                      DATAONLY
                 END-EXEC
              WHEN SEND-DATAONLY-ALARM
                 EXEC CICS SEND MAP ('RETU1')
                      MAPSET ('APNSE02')
                      FROM(RETU1O)
                      DATAONLY
                 END-EXEC
           END-EVALUATE.

       1500-UPDATE-SOLDE.
           EXEC SQL
              UPDATE API3.COMPTE
                 SET SOLDE = SOLDE - :WS-MONTANT-RETRAIT
                 WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
           END-EXEC.

           IF SQLCODE = 0
      *       Update réussi - enregistrer l'operation
              PERFORM 1600-INSERT-OPERATION
      *       Lire le nouveau solde pour affichage
              EXEC SQL
                 SELECT SOLDE
                 INTO :WS-SOLDE
                 FROM API3.COMPTE
                 WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
              END-EXEC
              IF SQLCODE = 0
                 MOVE WS-SOLDE TO WS-SOLDE-NUM
                 MOVE WS-SOLDE-NUM TO WS-SOLDE-EDITED
                 MOVE WS-SOLDE-EDITED TO SOLDEO
                 MOVE 'RETRAIT EFFECTUE' TO MESRETO
              ELSE
                 MOVE 'ERREUR LECTURE NOUVEAU SOLDE' TO MESRETO
              END-IF
              SET SEND-DATAONLY TO TRUE
              PERFORM 1400-SEND-RETRAIT-MAP
           ELSE
              MOVE 'N' TO VALID-DATA-SW
              MOVE 'ERREUR MISE A JOUR SOLDE' TO MESRETO
           END-IF.

       1290-CLEAR-ALL-FIELDS.
      *    Vider tous les champs de montant en cas d'erreur
           MOVE SPACES TO MT10O
           MOVE SPACES TO MT20O
           MOVE SPACES TO MT30O
           MOVE SPACES TO MT40O
           MOVE SPACES TO MT50O
           MOVE SPACES TO MT60O
           MOVE SPACES TO MT70O
           MOVE SPACES TO MTAUTREO
      *    Vider aussi les champs d'entree
           MOVE SPACES TO MT10I
           MOVE SPACES TO MT20I
           MOVE SPACES TO MT30I
           MOVE SPACES TO MT40I
           MOVE SPACES TO MT50I
           MOVE SPACES TO MT60I
           MOVE SPACES TO MT70I
           MOVE SPACES TO MTAUTREI.

       1600-INSERT-OPERATION.
      *    Recuperer l'ID_COMPTE a partir de ID_CLIENT
           EXEC SQL
              SELECT ID_COMPTE
              INTO :DCLOPERATION.WS-ID-COMPTE
              FROM API3.COMPTE
              WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
           END-EXEC.

           IF SQLCODE = 0
      *       Compte trouve - chercher le MAX des operations
              EXEC SQL
                 SELECT MAX(ID_OPERATION)
                 INTO :DCLOPERATION.WS-ID-OPERATION :WS-NULL-INDICATOR
                 FROM API3.OPERATION
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
              MOVE WS-MONTANT-RETRAIT TO 
                   WS-MONTANT-OP OF DCLOPERATION
              MOVE 'R' TO WS-TYPE-OP OF DCLOPERATION
      *       Recuperer la date du jour au format YYYYMMDD
              ACCEPT WS-DATE-OP OF DCLOPERATION FROM DATE YYYYMMDD

      *       Inserer l'operation dans la table OPERATION
              EXEC SQL
                 INSERT INTO API3.OPERATION
                    (ID_OPERATION, ID_COMPTE, MONTANT_OP,
                     TYPE_OP, DATE_OP)
                 VALUES
                    (:DCLOPERATION.WS-ID-OPERATION,
                     :DCLOPERATION.WS-ID-COMPTE,
                     :DCLOPERATION.WS-MONTANT-OP,
                     :DCLOPERATION.WS-TYPE-OP,
                     :DCLOPERATION.WS-DATE-OP)
              END-EXEC
           END-IF.
           