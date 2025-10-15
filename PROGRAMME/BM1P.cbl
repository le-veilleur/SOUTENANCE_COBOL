       IDENTIFICATION DIVISION.
       PROGRAM-ID. BM1P.
       ENVIRONMENT DIVISION.

       CONFIGURATION SECTION.

       INPUT-OUTPUT SECTION.

       FILE-CONTROL.

       DATA DIVISION.

       WORKING-STORAGE SECTION.
           EXEC SQL
              INCLUDE SQLCA
           END-EXEC.

           EXEC SQL
              INCLUDE COMPTE
           END-EXEC.

       COPY DFHAID.

       COPY APNSE01.


       01  WS-CARD-EXISTANT PIC S9(4) COMP VALUE 0.

       01  WS-COMMAREA.
           05 WS-COM-ID-CLIENT PIC X(10).


       PROCEDURE DIVISION.

       0000-MAIN-PROCEDURE.
           EXEC SQL
                SET CURRENT SQLID='API3'
           END-EXEC.

           IF EIBCALEN = ZERO
              PERFORM 1000-ECRAN-ACCUEIL
                 THRU 1000-ECRAN-ACCUEIL-EXIT
           ELSE
              PERFORM 2000-TRAITER-REPONSE
                 THRU 2000-TRAITER-REPONSE-EXIT
           END-IF.
           GOBACK.

       0000-MAIN-PROCEDURE-EXIT.
           EXIT.


       1000-ECRAN-ACCUEIL.
           MOVE LOW-VALUES TO ACU1I
           MOVE LOW-VALUES TO ACU1O

           EXEC CICS SEND MAP ('ACU1')
                          MAPSET ('APNSE01')
                          ERASE
           END-EXEC.

           EXEC CICS RETURN
                TRANSID('SN31')
                COMMAREA(WS-COMMAREA)
           END-EXEC.

       1000-ECRAN-ACCUEIL-EXIT.
           EXIT.


       2000-TRAITER-REPONSE.

           EXEC CICS RECEIVE MAP ('ACU1')
                MAPSET ('APNSE01')
           END-EXEC.

           IF EIBAID = DFHPF3
              EXEC CICS RETURN
              END-EXEC
           END-IF.

           MOVE IDCLIENTI TO WS-ID-CLIENT.
           MOVE PASSCBI TO WS-CODE-CB.
           MOVE IDCLIENTI TO WS-COM-ID-CLIENT.

           EXEC SQL
              SELECT COUNT(*) INTO :WS-CARD-EXISTANT FROM API3.COMPTE
              WHERE ID_CLIENT = :WS-ID-CLIENT
              AND CODE_CB = :WS-CODE-CB
           END-EXEC.

           IF WS-CARD-EXISTANT = 0
              MOVE LOW-VALUES TO ACU1I
              MOVE LOW-VALUES TO ACU1O

              MOVE SPACES TO MESCBO
              MOVE SPACES TO MESDEPRETO
            
              MOVE 'CARTE OU CLIENT NON EXISTANT' TO MESCBO
              EXEC CICS SEND MAP ('ACU1')
                          MAPSET ('APNSE01')
                          ERASE
              END-EXEC
              EXEC CICS RETURN
                  TRANSID('SN31')
                  COMMAREA(WS-COMMAREA)
              END-EXEC
           END-IF.

           EVALUATE RETDEPI
              WHEN 'R'
                 EXEC CICS XCTL PROGRAM('RETPROG')
                    COMMAREA(WS-COMMAREA)
                    LENGTH(LENGTH OF WS-COMMAREA)
                 END-EXEC
              WHEN 'D'
                 EXEC CICS XCTL PROGRAM('DEPROG')
                    COMMAREA(WS-COMMAREA)
                    LENGTH(LENGTH OF WS-COMMAREA)
                 END-EXEC
              WHEN OTHER
                 MOVE 'CHOIX INVALIDE' TO MESDEPRETO

                 EXEC CICS SEND MAP ('ACU1')
                           MAPSET('APNSE01')
                           ERASE
                 END-EXEC

                 EXEC CICS RETURN
                           TRANSID('SN31')
                           COMMAREA(WS-COMMAREA)
                 END-EXEC
           END-EVALUATE.

       2000-TRAITER-REPONSE-EXIT.
           EXIT.