       IDENTIFICATION DIVISION.
       PROGRAM-ID. RETPROG.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       DATA DIVISION.


       WORKING-STORAGE SECTION.
           COPY DFHAID.
       01  WS-RET-ID-CLIENT PIC S9(9) COMP.
       01  WS-TEMP-ID-CLIENT PIC 9(10).
       01  WS-RET-PRENOM-CLIENT PIC X(15).


       01  WS-RET-SOLDE PIC S9(8)V99 COMP-3. 
       01  WS-SOLDE-AFFICHAGE PIC ZZZZZZ9.99.  

       01  WS-MONTANT-RETRAIT PIC S9(4) COMP-3.
       01  WS-TMP-MONTANT     PIC 9(4). 

       01  WS-RETRAIT         PIC X VALUE 'N'.

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



       LINKAGE SECTION.
       01  WS-COMMAREA.
           05 WS-COM-ID-CLIENT PIC X(10).


       PROCEDURE DIVISION USING WS-COMMAREA.


       0000-MAIN-PROCEDURE.

           EXEC SQL
              SET CURRENT SQLID='API3'
           END-EXEC.
           IF EIBTRNID = 'SN32'
              PERFORM 2000-TRAITER-REPONSE
                THRU 2000-TRAITER-REPONSE-EXIT
           ELSE
             PERFORM 1000-AFFICHER-ECRAN
                 THRU 1000-AFFICHER-ECRAN-EXIT
           END-IF.

           GOBACK.

       0000-MAIN-PROCEDURE-EXIT.
           EXIT.

       1000-AFFICHER-ECRAN.
           MOVE WS-COM-ID-CLIENT TO WS-TEMP-ID-CLIENT
           MOVE WS-TEMP-ID-CLIENT TO WS-RET-ID-CLIENT

           MOVE LOW-VALUES TO RETU1I
           MOVE LOW-VALUES TO RETU1O

           MOVE SPACES TO MESRETO

           EXEC SQL
               SELECT PRENOM_CLIENT INTO :WS-RET-PRENOM-CLIENT 
               FROM API3.CLIENT
               WHERE ID_CLIENT = :WS-RET-ID-CLIENT
           END-EXEC.
           
           IF SQLCODE = 0
              MOVE WS-RET-PRENOM-CLIENT TO NCPTEO
           ELSE
               IF SQLCODE = 100
                 MOVE 'PRENOM INTROUVABLE' TO MESRETO
              ELSE
                 MOVE 'ERREUR ACCES PRENOM' TO MESRETO
              END-IF
           END-IF.
           
           EXEC SQL
            SELECT SOLDE INTO :WS-RET-SOLDE
            FROM API3.COMPTE
            WHERE ID_CLIENT = :WS-RET-ID-CLIENT
           END-EXEC.

           IF SQLCODE = 0
              MOVE WS-RET-SOLDE TO WS-SOLDE-AFFICHAGE
              MOVE WS-SOLDE-AFFICHAGE TO SOLDEO
           ELSE
              MOVE 'ERREUR ACCES COMPTE' TO MESRETO
           END-IF.
           

           EXEC CICS SEND MAP ('RETU1')
                MAPSET ('APNSE02')
                ERASE
           END-EXEC.
         
           EXEC CICS RETURN 
                  TRANSID('SN32')
                  COMMAREA(WS-COMMAREA)
                  LENGTH(LENGTH OF WS-COMMAREA)
           END-EXEC.

       1000-AFFICHER-ECRAN-EXIT.
           EXIT.


       2000-TRAITER-REPONSE.
           EXEC CICS RECEIVE MAP('RETU1')
                  MAPSET('APNSE02')
           END-EXEC.

           MOVE WS-COM-ID-CLIENT  TO WS-TEMP-ID-CLIENT
           MOVE WS-TEMP-ID-CLIENT TO WS-RET-ID-CLIENT

           IF EIBAID = DFHPF3
              EXEC CICS RETURN
                   TRANSID('SN31')
              END-EXEC
           END-IF.

           IF WS-RETRAIT = 'N'
                 EVALUATE TRUE
                    WHEN MT10I = 'X'
                          MOVE 10 TO WS-TMP-MONTANT
                    WHEN MT20I = 'X'
                          MOVE 20 TO WS-TMP-MONTANT
                    WHEN MT30I = 'X'
                          MOVE 30 TO WS-TMP-MONTANT
                    WHEN MT40I = 'X'
                          MOVE 40 TO WS-TMP-MONTANT
                    WHEN MT50I = 'X'
                          MOVE 50 TO WS-TMP-MONTANT
                    WHEN MT60I = 'X'
                          MOVE 60 TO WS-TMP-MONTANT
                    WHEN MT70I = 'X'
                          MOVE 70 TO WS-TMP-MONTANT
                    WHEN MTAUTREI IS NUMERIC
                          MOVE MTAUTREI TO WS-TMP-MONTANT
                    WHEN OTHER
                          MOVE 'MONTANT INVALIDE' TO MESRETO
                    END-EVALUATE
           

              IF WS-TMP-MONTANT > 0 
                MOVE WS-TMP-MONTANT TO WS-MONTANT-RETRAIT
                EXEC SQL
                  UPDATE API3.COMPTE
                     SET SOLDE = SOLDE - :WS-MONTANT-RETRAIT
                  WHERE ID_CLIENT = :WS-RET-ID-CLIENT
                END-EXEC
                MOVE 'Y' TO WS-RETRAIT

                EXEC SQL
                  SELECT SOLDE INTO :WS-RET-SOLDE
                  FROM API3.COMPTE
                  WHERE ID_CLIENT = :WS-RET-ID-CLIENT
                END-EXEC

                MOVE WS-RET-SOLDE TO WS-SOLDE-AFFICHAGE
                MOVE LOW-VALUES TO RETU1I
                MOVE LOW-VALUES TO RETU1O
                MOVE WS-SOLDE-AFFICHAGE  TO SOLDEO
                MOVE 'RETRAIT EFFECTUE'  TO MESRETO

                EXEC CICS
                  SEND MAP('RETU1')
                  MAPSET('APNSE02')
                  ERASE
                END-EXEC
                 
                EXEC CICS RETURN
                  TRANSID('SN31')
                END-EXEC 

              END-IF
              IF WS-TMP-MONTANT = 0 
                 EXEC SQL
                   SELECT SOLDE INTO :WS-RET-SOLDE
                     FROM API3.COMPTE
                    WHERE ID_CLIENT = :WS-RET-ID-CLIENT
                 END-EXEC
                 MOVE WS-RET-SOLDE       TO WS-SOLDE-AFFICHAGE
                 MOVE LOW-VALUES         TO RETU1I
                 MOVE LOW-VALUES         TO RETU1O
                 MOVE WS-SOLDE-AFFICHAGE TO SOLDEO
                 MOVE 'MONTANT INVALIDE' TO MESRETO
                 EXEC CICS
                   SEND MAP('RETU1')
                   MAPSET('APNSE02')
                   ERASE
                 END-EXEC
                 EXEC CICS RETURN
                   TRANSID('SN32')
                   COMMAREA(WS-COMMAREA)
                   LENGTH(LENGTH OF WS-COMMAREA)
                 END-EXEC
              END-IF
           ELSE
              MOVE LOW-VALUES TO RETU1I
              MOVE LOW-VALUES TO RETU1O
              MOVE 'RETRAIT DEJA EFFECTUE' TO MESRETO

              EXEC CICS
                  SEND MAP('RETU1')
                  MAPSET('APNSE02')
                  ERASE
                END-EXEC

                EXEC CICS RETURN
                  TRANSID('SN32')
                  COMMAREA(WS-COMMAREA)
                  LENGTH(LENGTH OF WS-COMMAREA)
                END-EXEC

           END-IF.
       2000-TRAITER-REPONSE-EXIT.
           EXIT.

