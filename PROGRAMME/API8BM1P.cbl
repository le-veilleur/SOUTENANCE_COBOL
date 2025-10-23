       IDENTIFICATION DIVISION.
       PROGRAM-ID. API8BM1P.

       ENVIRONMENT DIVISION.


       DATA DIVISION.

       WORKING-STORAGE SECTION.

           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.

           EXEC SQL
               INCLUDE COMPTE
           END-EXEC.

       01  SWITCHES.
      *
           05  VALID-DATA-SW               PIC X    VALUE 'Y'.
               88 VALID-DATA                        VALUE 'Y'.
      *

        01  FLAGS.
      *
           05  SEND-FLAG                   PIC X.
               88  SEND-ERASE                       VALUE '1'.
               88  SEND-DATAONLY                    VALUE '2'.
               88  SEND-DATAONLY-ALARM              VALUE '3'.
      *



       COPY DFHAID.

       COPY APNSE01.

       01  WS-TEMP-ID-CLIENT-ALPHA  PIC X(10).
       01  WS-TEMP-CODE-CB-ALPHA    PIC X(4).
       01  WS-TEMP-ID-CLIENT-NUM    PIC 9(10).
       01  WS-TEMP-CODE-CB-NUM      PIC 9(4).

       01  WS-COMMUNICATION-AREA  PIC S9(9) COMP.

       LINKAGE SECTION.
       01  DFHCOMMAREA.
           05 DFHCOM-ID-CLIENT PIC S9(9) COMP.


       PROCEDURE DIVISION.

       0000-MAIN-PROCEDURE.
           EVALUATE TRUE
              WHEN EIBCALEN = ZERO
                 MOVE LOW-VALUES TO ACU1I
                 MOVE LOW-VALUES TO ACU1O
                 SET SEND-ERASE TO TRUE
                 PERFORM 1400-SEND-ACCUEIL-MAP

              WHEN EIBAID = DFHCLEAR
                 MOVE LOW-VALUES TO ACU1I
                 MOVE LOW-VALUES TO ACU1O
                 SET SEND-ERASE TO TRUE
                 PERFORM 1400-SEND-ACCUEIL-MAP

              WHEN EIBAID = DFHPA1 OR DFHPA2 OR DFHPA3
                  CONTINUE
              
              WHEN EIBAID = DFHPF3 OR DFHPF12
                 EXEC CICS
                     RETURN
                 END-EXEC

              WHEN EIBAID = DFHENTER
                  PERFORM 1000-PROCESS-INPUT-MAP

              WHEN OTHER
                 MOVE LOW-VALUES TO ACU1I
                 MOVE LOW-VALUES TO ACU1O
                 MOVE 'Touche invalide.    ' TO MESDEPRETO
                 SET SEND-DATAONLY-ALARM TO TRUE
                 PERFORM 1400-SEND-ACCUEIL-MAP
           END-EVALUATE.

      * Seulement si on n'a pas fait de XCTL
           IF NOT VALID-DATA
              MOVE DFHCOM-ID-CLIENT TO WS-COMMUNICATION-AREA
              EXEC CICS
                 RETURN TRANSID('SN01')
                        COMMAREA(WS-COMMUNICATION-AREA)
                        LENGTH(10)
              END-EXEC
           END-IF.



       1000-PROCESS-INPUT-MAP.
           PERFORM 1100-RECEIVE-ACCUEIL-MAP.
           PERFORM 1200-EDIT-ACCUEIL-DATA.
           IF VALID-DATA
                 PERFORM 1300-GET-CLIENT
           END-IF.

       1100-RECEIVE-ACCUEIL-MAP.


           EXEC CICS RECEIVE MAP ('ACU1')
                  MAPSET ('APNSE01')
                  INTO (ACU1I)
           END-EXEC.


       1200-EDIT-ACCUEIL-DATA.
           IF NOT PASSCBI NUMERIC OR IDCLIENTI IS NOT NUMERIC
              MOVE 'N' TO VALID-DATA-SW
              MOVE 'Champs numériques uniquement    ' TO MESDEPRETO
           END-IF.
           
           EVALUATE RETDEPI
              WHEN 'D'
              WHEN 'R'
              WHEN 'V'
              WHEN 'L'
                 CONTINUE
              WHEN OTHER
                 MOVE 'N' TO VALID-DATA-SW
                 MOVE 'OPERATION INCORRECTE (D/R/V/L)    ' TO MESDEPRETO
           END-EVALUATE.
          


       1300-GET-CLIENT.
           MOVE IDCLIENTI TO WS-TEMP-ID-CLIENT-ALPHA.
           MOVE PASSCBI TO WS-TEMP-CODE-CB-ALPHA.

           MOVE WS-TEMP-ID-CLIENT-ALPHA TO WS-TEMP-ID-CLIENT-NUM.
           MOVE WS-TEMP-CODE-CB-ALPHA TO WS-TEMP-CODE-CB-NUM.

           MOVE WS-TEMP-ID-CLIENT-NUM TO WS-ID-CLIENT.
           MOVE WS-TEMP-CODE-CB-NUM TO WS-CODE-CB.


           EXEC SQL
              SELECT ID_CLIENT
              INTO :WS-ID-CLIENT
              FROM API8.COMPTE
              WHERE ID_CLIENT = :WS-ID-CLIENT
              AND CODE_CB = :WS-CODE-CB
           END-EXEC.

           EVALUATE SQLCODE
             WHEN 0
               MOVE WS-ID-CLIENT TO WS-COMMUNICATION-AREA
               PERFORM 1500-EXEC-RETDEP
             WHEN 100
               MOVE 'N' TO VALID-DATA-SW
               MOVE 'CLIENT INCONNU' TO MESDEPRETO
             WHEN OTHER
               MOVE 'N' TO VALID-DATA-SW
               MOVE 'ERREUR BDD' TO MESDEPRETO
           END-EVALUATE.


       1400-SEND-ACCUEIL-MAP.
           EVALUATE TRUE
              WHEN SEND-ERASE
                 EXEC CICS SEND MAP ('ACU1')
                      MAPSET ('APNSE01')
                      FROM(ACU1O)
                      ERASE
                 END-EXEC
              WHEN SEND-DATAONLY
                 EXEC CICS SEND MAP ('ACU1')
                      MAPSET ('APNSE01')
                      FROM(ACU1O)
                      DATAONLY
                 END-EXEC
              WHEN SEND-DATAONLY-ALARM
                 EXEC CICS SEND MAP ('ACU1')
                      MAPSET ('APNSE01')
                      FROM(ACU1O)
                      DATAONLY
                 END-EXEC
           END-EVALUATE.


       1500-EXEC-RETDEP.
           EVALUATE RETDEPI
              WHEN 'R'
                 EXEC CICS XCTL PROGRAM('API8RET')
                      COMMAREA(WS-COMMUNICATION-AREA)
                      LENGTH(LENGTH OF WS-COMMUNICATION-AREA)
                 END-EXEC

              WHEN 'D'
                 EXEC CICS XCTL PROGRAM('API8DEPO')
                      COMMAREA(WS-COMMUNICATION-AREA)
                      LENGTH(LENGTH OF WS-COMMUNICATION-AREA)
                 END-EXEC
              
              WHEN 'L'
                 EXEC CICS XCTL PROGRAM('API8LIST')
                      COMMAREA(WS-COMMUNICATION-AREA)
                      LENGTH(LENGTH OF WS-COMMUNICATION-AREA)
                 END-EXEC

              WHEN 'V'
                 EXEC CICS XCTL PROGRAM('API8VIR')
                      COMMAREA(WS-COMMUNICATION-AREA)
                      LENGTH(LENGTH OF WS-COMMUNICATION-AREA)
                 END-EXEC
           END-EVALUATE.
