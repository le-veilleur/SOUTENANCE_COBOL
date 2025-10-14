       IDENTIFICATION DIVISION.
       PROGRAM-ID. RETPROG.
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


       LINKAGE SECTION.
       01  WS-COMMAREA.
           05 WS-COM-ID-CLIENT PIC X(10).


       PROCEDURE DIVISION USING WS-COMMAREA.


       0000-MAIN-PROCEDURE.

           EXEC SQL
              SET CURRENT SQLID='API3'
           END-EXEC.

           PERFORM 1000-AFFICHER-ECRAN
              THRU 1000-AFFICHER-ECRAN-EXIT.

           GOBACK.

       0000-MAIN-PROCEDURE-EXIT.
           EXIT.

       1000-AFFICHER-ECRAN.
           MOVE LOW-VALUES TO RETU1I
           MOVE LOW-VALUES TO RETU1O
           EXEC CICS SEND MAP ('RETU1')
                MAPSET ('APNSE02')
                ERASE
           END-EXEC.
           

           EXEC CICS RETURN 
                  TRANSID('SN32')
                  COMMAREA(WS-COMMAREA)
           END-EXEC.

       1000-AFFICHER-ECRAN-EXIT.
           EXIT.



