       IDENTIFICATION DIVISION.
       PROGRAM-ID. API8FILDB.
       ENVIRONMENT DIVISION.

       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

           SELECT FCLI ASSIGN TO INP001
           ORGANIZATION IS SEQUENTIAL
           ACCESS MODE IS SEQUENTIAL
           FILE STATUS IS FS-FCLI.

           SELECT FCOMPTE ASSIGN TO INP002
           ORGANIZATION IS SEQUENTIAL
           ACCESS MODE IS SEQUENTIAL
           FILE STATUS IS FS-FCOMPTE.

       
       DATA DIVISION.

     
       FILE SECTION.
       FD  FCLI
           RECORD CONTAINS 50 CHARACTERS.
       01  BUFCLIENT.
           05 BUF-ID-CLIENT           PIC 9(10).
           05 BUF-NOM-CLIENT          PIC X(10).
           05 BUF-PRENOM-CLIENT       PIC X(15).
           05 BUF-ADRESSE-CLIENT      PIC X(15).

       FD FCOMPTE
           RECORD CONTAINS 34 CHARACTERS.
       01  BUFCOMPTE.
      *    BUFFER EN FORMAT TEXTE POUR LECTURE FICHIER SEQUENTIEL
           05 BUF-ID-COMPTE            PIC 9(10).
           05 BUF-ID-CLIENT-COMPTE     PIC 9(10).
           05 BUF-CODE-CB              PIC 9(4).
           05 BUF-SOLDE                PIC X(10).

 
       WORKING-STORAGE SECTION.
       
       77  FS-FCLI PIC X(2).
       77  FS-FCOMPTE PIC X(2).

       01  TEMP-SOLDE                PIC 9(10).

           EXEC SQL
              INCLUDE SQLCA
           END-EXEC.
       
           EXEC SQL
              INCLUDE CLIENT
           END-EXEC.
           
           EXEC SQL
              INCLUDE COMPTE
           END-EXEC.
           
       01  ERR-MSG.
           05  ERR-LONG      PIC S9(4) COMP VALUE +720.
           05  ERR-TXT       PIC X(72) OCCURS 10 TIMES.
       01  ERR-TXT-LONG      PIC S9(9) COMP VALUE 72.
       01  I                 PIC 99.

    
       PROCEDURE DIVISION.
       
       0000-MAIN-PROCEDURE.
           EXEC SQL
              SET CURRENT SQLID = 'API8'
           END-EXEC.
           
           EXEC SQL
              WHENEVER SQLERROR GOTO 9998-ERROR-DB2
           END-EXEC.

           PERFORM 6000-OPEN-CLI
              THRU 6000-OPEN-CLI-EXIT.
           
           PERFORM 6000-OPEN-COMPTE
              THRU 6000-OPEN-COMPTE-EXIT.

           PERFORM 6110-READ-CLI
              THRU 6110-READ-CLI-EXIT.

           PERFORM 6110-READ-COMPTE
              THRU 6110-READ-COMPTE-EXIT.


           PERFORM 1000-TRAITER-CLI
              THRU 1000-TRAITER-CLI-EXIT
              UNTIL FS-FCLI = '10'.

           PERFORM 1000-TRAITER-COMPTE
              THRU 1000-TRAITER-COMPTE-EXIT
              UNTIL FS-FCOMPTE = '10'.


           PERFORM 6220-CLOSE-CLI
              THRU 6220-CLOSE-CLI-EXIT.

           PERFORM 6220-CLOSE-COMPTE
              THRU 6220-CLOSE-COMPTE-EXIT.

           PERFORM 9999-FIN-PROGRAMME-DEB
              THRU 9999-FIN-PROGRAMME-FIN.

       0000-MAIN-PROCEDURE-EXIT.
           EXIT.


       6000-OPEN-CLI.
           OPEN INPUT FCLI.
           IF FS-FCLI NOT = '00'
               DISPLAY 'ERROR OPENING FCLI: '
               DISPLAY 'VALEUR DU FILE STATUS: ' FS-FCLI
               GO TO 9999-ERREUR-PROGRAMME-DEB
           END-IF.
           
       6000-OPEN-CLI-EXIT.
           EXIT.

       6000-OPEN-COMPTE.
           OPEN INPUT FCOMPTE.
           IF FS-FCOMPTE NOT = '00'
               DISPLAY 'ERROR OPENING FCOMPT: '
               DISPLAY 'VALEUR DU FILE STATUS: ' FS-FCOMPTE
               GO TO 9999-ERREUR-PROGRAMME-DEB
           END-IF.
       6000-OPEN-COMPTE-EXIT.
           EXIT.


       6110-READ-CLI.
           READ FCLI
           IF FS-FCLI NOT = '00' AND NOT = '10'
               DISPLAY 'ERROR READING FCLI: '
               DISPLAY 'VALEUR DU FILE STATUS: ' FS-FCLI
               GO TO 9999-ERREUR-PROGRAMME-DEB
           END-IF.
       6110-READ-CLI-EXIT.
           EXIT.

       6110-READ-COMPTE.
           READ FCOMPTE
           IF FS-FCOMPTE NOT = '00' AND NOT = '10'
               DISPLAY 'ERROR READING FCOMPT: '
               DISPLAY 'VALEUR DU FILE STATUS: ' FS-FCOMPTE
               GO TO 9999-ERREUR-PROGRAMME-DEB
           END-IF.
       6110-READ-COMPTE-EXIT.
           EXIT.


       1000-TRAITER-CLI.
           MOVE BUF-ID-CLIENT TO WS-ID-CLIENT OF DCLCLIENT.
           MOVE BUF-NOM-CLIENT TO WS-NOM-CLIENT.
           MOVE BUF-PRENOM-CLIENT TO WS-PRENOM-CLIENT.
           MOVE BUF-ADRESSE-CLIENT TO WS-ADRESSE-CLIENT.

           EXEC SQL
            INSERT INTO API8.CLIENT 
           (ID_CLIENT, NOM_CLIENT, PRENOM_CLIENT, ADRESSE_CLIENT) VALUES
           (:DCLCLIENT.WS-ID-CLIENT, :WS-NOM-CLIENT, 
           :WS-PRENOM-CLIENT, :WS-ADRESSE-CLIENT)
           END-EXEC.


           EXEC SQL
              WHENEVER SQLERROR GOTO 9998-ERROR-DB2
           END-EXEC.

           PERFORM 6110-READ-CLI
              THRU 6110-READ-CLI-EXIT.
       
       1000-TRAITER-CLI-EXIT.
           EXIT.

       1000-TRAITER-COMPTE.
           
           MOVE BUF-ID-COMPTE TO WS-ID-COMPTE.
           MOVE BUF-ID-CLIENT-COMPTE TO WS-ID-CLIENT OF DCLCOMPTE.
           MOVE BUF-CODE-CB TO WS-CODE-CB.
           MOVE BUF-SOLDE TO TEMP-SOLDE.
           MOVE TEMP-SOLDE TO WS-SOLDE.


           EXEC SQL
            INSERT INTO API8.COMPTE
           (ID_COMPTE, ID_CLIENT, CODE_CB, SOLDE) VALUES
           (:WS-ID-COMPTE, :DCLCOMPTE.WS-ID-CLIENT, 
           :WS-CODE-CB, :WS-SOLDE)
           END-EXEC.


           EXEC SQL
              WHENEVER SQLERROR GOTO 9998-ERROR-DB2
           END-EXEC.

           PERFORM 6110-READ-COMPTE
              THRU 6110-READ-COMPTE-EXIT.
       
       1000-TRAITER-COMPTE-EXIT.
           EXIT.

       6220-CLOSE-COMPTE.
           CLOSE FCOMPTE.
           IF FS-FCOMPTE NOT = '00'
               DISPLAY 'ERROR CLOSING FCOMPT: '
               DISPLAY 'VALEUR DU FILE STATUS: ' FS-FCOMPTE
               GO TO 9999-ERREUR-PROGRAMME-DEB
           END-IF.
       6220-CLOSE-COMPTE-EXIT.
           EXIT.


       6220-CLOSE-CLI.
           CLOSE FCLI.
           IF FS-FCLI NOT = '00'
               DISPLAY 'ERROR CLOSING FCLI: '
               DISPLAY 'VALEUR DU FILE STATUS: ' FS-FCLI
               GO TO 9999-ERREUR-PROGRAMME-DEB
           END-IF.
       6220-CLOSE-CLI-EXIT.
           EXIT.
       
       
       9998-ERROR-DB2.
            DISPLAY 'ERREUR DB2 '.
            DISPLAY 'MISE EN FORME SQLCA '.
            CALL 'DSNTIAR' USING SQLCA, ERR-MSG, ERR-TXT-LONG.
            PERFORM VARYING I FROM 1 BY 1 UNTIL I > 10
               DISPLAY ERR-TXT (I)
            END-PERFORM.

            PERFORM 9999-ERREUR-PROGRAMME-DEB
               THRU 9999-ERREUR-PROGRAMME-FIN.
       
               
      *
       9999-FIN-PROGRAMME-DEB.
      *
            DISPLAY '=============================================='
            DISPLAY '*     FIN NORMALE DU PROGRAMME XXXXXXXX        '
            DISPLAY '==============================================*'.
      *
       9999-FIN-PROGRAMME-FIN.
            STOP RUN.
      *
       9999-ERREUR-PROGRAMME-DEB.
      *
            DISPLAY '=============================================='
            DISPLAY '*        UNE ANOMALIE A ETE DETECTEE           '
            DISPLAY '     FIN ANORMALE DU PROGRAMME XXXXXXXX       '
            DISPLAY '==============================================*'.
      *
       9999-ERREUR-PROGRAMME-FIN.
            STOP RUN.