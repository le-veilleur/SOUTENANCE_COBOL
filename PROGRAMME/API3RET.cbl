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

       01  WS-SOLDE-ALPHA   PIC X(10).
       01  WS-SOLDE-NUM     PIC 9(10).
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
           EXEC SQL
              SELECT PRENOM_CLIENT
              INTO :WS-PRENOM-CLIENT
              FROM API3.CLIENT
              WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
           END-EXEC
           IF SQLCODE = 0
              MOVE WS-PRENOM-CLIENT TO NCPTEO
           ELSE
              MOVE 'CLIENT INCONNU' TO NCPTEO
           END-IF.

       1200-EDIT-RETRAIT-DATA.
           MOVE 'Y' TO VALID-DATA-SW
           PERFORM 1210-VALIDATE-MT10
           PERFORM 1220-VALIDATE-MT20
           PERFORM 1230-VALIDATE-MT30
           PERFORM 1240-VALIDATE-MT40
           PERFORM 1250-VALIDATE-MT50
           PERFORM 1260-VALIDATE-MT60
           PERFORM 1270-VALIDATE-MT70
           PERFORM 1280-VALIDATE-MTAUTRE.

       1210-VALIDATE-MT10.
           EVALUATE TRUE
              WHEN MT10I = 'X'
                 CONTINUE
              WHEN MT10I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT10 INVALIDE - X OU VIDE SEULEMENT' TO MESRETO
           END-EVALUATE.

       1220-VALIDATE-MT20.
           EVALUATE TRUE
              WHEN MT20I = 'X'
                 CONTINUE
              WHEN MT20I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT20 INVALIDE - X OU VIDE SEULEMENT' TO MESRETO
           END-EVALUATE.

       1230-VALIDATE-MT30.
           EVALUATE TRUE
              WHEN MT30I = 'X'
                 CONTINUE
              WHEN MT30I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT30 INVALIDE - X OU VIDE SEULEMENT' TO MESRETO
           END-EVALUATE.

       1240-VALIDATE-MT40.
           EVALUATE TRUE
              WHEN MT40I = 'X'
                 CONTINUE
              WHEN MT40I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT40 INVALIDE - X OU VIDE SEULEMENT' TO MESRETO
           END-EVALUATE.

       1250-VALIDATE-MT50.
           EVALUATE TRUE
              WHEN MT50I = 'X'
                 CONTINUE
              WHEN MT50I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT50 INVALIDE X OU VIDE SEULEMENT' TO MESRETO
           END-EVALUATE.

       1260-VALIDATE-MT60.
           EVALUATE TRUE
              WHEN MT60I = 'X'
                 CONTINUE
              WHEN MT60I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT60 INVALIDE - X OU VIDE SEULEMENT' TO MESRETO
           END-EVALUATE.

       1270-VALIDATE-MT70.
           EVALUATE TRUE
              WHEN MT70I = 'X'
                 CONTINUE
              WHEN MT70I = SPACES
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MT70 INVALIDE - X OU VIDE SEULEMENT' TO MESRETO
           END-EVALUATE.

       1280-VALIDATE-MTAUTRE.
           EVALUATE TRUE
              WHEN MTAUTREI = SPACES
                 CONTINUE
              WHEN MTAUTREI IS NUMERIC
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'MTAUTRE INVALIDE - NUMERIQUE SEULEMENT'
                   TO MESRETO
           END-EVALUATE.


       1300-VERIF-SOLDE.
              EVALUATE TRUE
                  WHEN MT10I = 'X'
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

                  WHEN MT20I = 'X'
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

                  WHEN MT30I = 'X'
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

                  WHEN MT40I = 'X'
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

                  WHEN MT50I = 'X'
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

                  WHEN MT60I = 'X'
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

                  WHEN MT70I = 'X'
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
              EXEC SQL
                 COMMIT
              END-EXEC
              MOVE 'RETRAIT EFFECTUE' TO MESRETO
              SET SEND-DATAONLY TO TRUE
              PERFORM 1400-SEND-RETRAIT-MAP
           ELSE
              EXEC SQL
                 ROLLBACK
              END-EXEC
              MOVE 'N' TO VALID-DATA-SW
              MOVE 'ERREUR MISE A JOUR SOLDE' TO MESRETO
           END-IF.