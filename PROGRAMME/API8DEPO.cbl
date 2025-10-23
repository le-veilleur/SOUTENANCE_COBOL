       IDENTIFICATION DIVISION.
       PROGRAM-ID. API8DEPO.
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

       01  WS-XCTL-PROGRAM-SW              PIC X VALUE 'N'.
           88 XCTL-PROGRAM                       VALUE 'Y'.      
      
      
      *
       COPY DFHAID.
       COPY APNSE03.


       01  WS-MONTANT-DEPOT       PIC S9(8)V99 COMP-3.   
       01  WS-SOLDE-APRES-DEPOT   PIC S9(8)V99 COMP-3.

       01  WS-SOLDE-ALPHA         PIC X(10).
       01  WS-SOLDE-NUM           PIC 9(10).
       01  WS-SOLDE-DISPLAY       PIC ZZZ,ZZZ,ZZ9.99.
       01  WS-NULL-INDICATOR      PIC S9(4) COMP.

       01  WS-INPUT-DEPO         PIC S9(8)V99.

       01  WS-COMMUNICATION-AREA  PIC S9(9) COMP.

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
                 MOVE LOW-VALUES TO DEPOI
                 MOVE LOW-VALUES TO DEPOO
                 PERFORM 1150-LIRE-SOLDE
                 SET SEND-ERASE TO TRUE
                 PERFORM 1400-SEND-ECRAN-DEPO

              WHEN EIBAID = DFHCLEAR
                 MOVE LOW-VALUES TO DEPOI
                 MOVE LOW-VALUES TO DEPOO
                 SET SEND-ERASE TO TRUE
                 PERFORM 1400-SEND-ECRAN-DEPO
              
              WHEN EIBAID = DFHPA1 OR DFHPA2 OR DFHPA3
                   CONTINUE

               WHEN EIBAID = DFHPF3 OR DFHPF12
                    SET XCTL-PROGRAM TO TRUE
              
              WHEN EIBAID = DFHENTER
                   PERFORM 1000-TRAITER-SAISIE

              WHEN OTHER
                 PERFORM 1100-RECEIVE-ECRAN-DEPO
                 MOVE 'Touche invalide' TO MESDEPO
                 SET SEND-DATAONLY-ALARM TO TRUE
                 PERFORM 1400-SEND-ECRAN-DEPO
           
           END-EVALUATE.

           IF NOT XCTL-PROGRAM            
               EXEC CICS RETURN TRANSID('SN03')
                    COMMAREA(WS-COMMUNICATION-AREA)
                    LENGTH(10)
               END-EXEC
           ELSE
               EXEC CICS XCTL PROGRAM('API8BM1P')
                    COMMAREA(WS-COMMUNICATION-AREA)
                    LENGTH(LENGTH OF WS-COMMUNICATION-AREA)
               END-EXEC
           END-IF.

       1000-TRAITER-SAISIE.
           PERFORM 1100-RECEIVE-ECRAN-DEPO.
           PERFORM 1150-LIRE-SOLDE.
           PERFORM 1200-VALIDER-MONTANT.
           IF VALID-DATA
               PERFORM 1300-TRAITER-DEPOT
           ELSE
               SET SEND-DATAONLY-ALARM TO TRUE
               PERFORM 1400-SEND-ECRAN-DEPO
             END-IF.
           
       
       1150-LIRE-SOLDE.
           EXEC SQL
             SELECT SOLDE
             INTO :DCLCOMPTE.WS-SOLDE
             FROM API8.COMPTE
             WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
           END-EXEC.
           
           IF SQLCODE = 0
                MOVE WS-SOLDE OF DCLCOMPTE TO WS-SOLDE-DISPLAY
                MOVE WS-SOLDE-DISPLAY TO SOLDEO
           ELSE
                MOVE 'Erreur lecture compte' TO MESDEPO
                MOVE 'N' TO VALID-DATA-SW
           END-IF.

       1100-RECEIVE-ECRAN-DEPO.
           EXEC CICS RECEIVE MAP ('DEPO')
                  MAPSET ('APNSE03')
                  INTO (DEPOI)
           END-EXEC.

       1200-VALIDER-MONTANT.
           IF INPUTDEPI = SPACES OR INPUTDEPI = LOW-VALUES
                MOVE 'N' TO VALID-DATA-SW
                MOVE 'Veuillez saisir un montant      ' TO MESDEPO
           ELSE
             IF INPUTDEPI IS NOT NUMERIC
                MOVE 'N' TO VALID-DATA-SW
                MOVE 'Champs numeriques uniquement    ' TO MESDEPO
             ELSE
                MOVE INPUTDEPI TO WS-INPUT-DEPO           
                IF WS-INPUT-DEPO <= 0
                   MOVE 'N' TO VALID-DATA-SW
                   MOVE 'Le montant doit etre positif    ' TO MESDEPO
                END-IF
             END-IF
           END-IF.
           
       1300-TRAITER-DEPOT.
           MOVE INPUTDEPI TO WS-INPUT-DEPO
           MOVE WS-INPUT-DEPO TO WS-MONTANT-DEPOT
           
           EXEC SQL
             UPDATE API8.COMPTE
             SET SOLDE = SOLDE + :WS-MONTANT-DEPOT
             WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
           END-EXEC.
           
           IF SQLCODE = 0
             PERFORM 1310-ENREG-OPERATION
             PERFORM 1150-LIRE-SOLDE
             MOVE 'Depot effectue avec succes' TO MESDEPO
             SET SEND-DATAONLY TO TRUE
             PERFORM 1400-SEND-ECRAN-DEPO
             EXEC CICS RETURN TRANSID('SN03')
                 COMMAREA(WS-COMMUNICATION-AREA)
                 LENGTH(10)
             END-EXEC
           ELSE
             MOVE 'Erreur lors du depot' TO MESDEPO
             SET SEND-DATAONLY-ALARM TO TRUE
             PERFORM 1400-SEND-ECRAN-DEPO
           END-IF.
       
       1310-ENREG-OPERATION.
           EXEC SQL
               SELECT ID_COMPTE
               INTO :DCLOPERATION.WS-ID-COMPTE
               FROM API8.COMPTE
               WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
           END-EXEC.
           
           IF SQLCODE = 0
           EXEC SQL
            SELECT MAX(ID_OPERATION)
            INTO :DCLOPERATION.WS-ID-OPERATION :WS-NULL-INDICATOR
            FROM API8.OPERATION
           END-EXEC
               
            IF WS-NULL-INDICATOR = -1
              MOVE 1 TO WS-ID-OPERATION OF DCLOPERATION
              ELSE
              ADD 1 TO WS-ID-OPERATION OF DCLOPERATION
            END-IF

             MOVE WS-INPUT-DEPO TO WS-MONTANT-OP OF DCLOPERATION
             MOVE 'D' TO WS-TYPE-OP OF DCLOPERATION
               
            EXEC SQL
              INSERT INTO API8.OPERATION
               (ID_OPERATION, ID_COMPTE, MONTANT_OP, TYPE_OP, DATE_OP)
                 VALUES
                    (:DCLOPERATION.WS-ID-OPERATION,
                     :DCLOPERATION.WS-ID-COMPTE,
                     :DCLOPERATION.WS-MONTANT-OP,
                     :DCLOPERATION.WS-TYPE-OP,
                     CURRENT DATE)
            END-EXEC
           END-IF.

       1350-RETOUR-MENU.
           EXEC CICS
             XCTL PROGRAM('API8BM1P')
           END-EXEC.
      
       1400-SEND-ECRAN-DEPO.
           EVALUATE TRUE
              WHEN SEND-ERASE
                 EXEC CICS SEND MAP ('DEPO')
                      MAPSET ('APNSE03')
                      FROM(DEPOO)
                      ERASE
                 END-EXEC
              WHEN SEND-DATAONLY
                 EXEC CICS SEND MAP ('DEPO')
                      MAPSET ('APNSE03')
                      FROM(DEPOO)
                      DATAONLY
                 END-EXEC
              WHEN SEND-DATAONLY-ALARM
                 EXEC CICS SEND MAP ('DEPO')
                      MAPSET ('APNSE03')
                      FROM(DEPOO)
                      DATAONLY
                 END-EXEC
           END-EVALUATE.


