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
     

       PROCEDURE DIVISION.

       0000-MAIN-PROCEDURE.
           EXEC SQL
                SET CURRENT SQLID='API8'
           END-EXEC.


           PERFORM 1000-ECRAN-ACCUEIL
              THRU 1000-ECRAN-ACCUEIL-EXIT.

       0000-MAIN-PROCEDURE-EXIT.
           EXIT.


       1000-ECRAN-ACCUEIL.
 
           EXEC CICS SEND MAP ('ACU1')
                          MAPSET ('APNSE01')
                          ERASE
           END-EXEC.


           EXEC CICS RECEIVE MAP ('ACU1')
                          MAPSET ('APNSE01')
           END-EXEC.

           IF EIBAID = DFHPF3
              EXEC CICS RETURN
              END-EXEC
           END-IF.

           MOVE IDCLIENTI TO WS-ID-CLIENT.
           MOVE PASSCBI TO WS-CODE-CB.

           EXEC SQL 
              SELECT COUNT(*) INTO :WS-CARD-EXISTANT FROM API8.COMPTE
              WHERE ID_CLIENT = :WS-ID-CLIENT 
              AND CODE_CB = :WS-CODE-CB
           END-EXEC.


           IF WS-CARD-EXISTANT = 0
              MOVE 'CARD OU CLIENT NON EXISTANT' TO MESCBO
              EXEC CICS SEND MAP ('ACU1')
                          MAPSET ('APNSE01')
                          ERASE
              END-EXEC
           END-IF.

       1000-ECRAN-ACCUEIL-EXIT.
           EXIT.

           STOP RUN.

           

