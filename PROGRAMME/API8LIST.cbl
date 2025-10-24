       IDENTIFICATION DIVISION.
       PROGRAM-ID. API8LIST.
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

           

      * Ajout des nouvelles structures
       COPY DFHAID.
       COPY APNSE05.
      
       
       01  SWITCHES.
           05  VALID-DATA-SW               PIC X    VALUE 'Y'.
              88 VALID-DATA                         VALUE 'Y'.
           05  OPERATIONS-SW               PIC X    VALUE 'Y'.
              88 OPERATIONS                         VALUE 'Y'.


       01  FLAGS.
           05  SEND-FLAG                   PIC X.
              88  SEND-ERASE                       VALUE '1'.
              88  SEND-DATAONLY                    VALUE '2'.
              88  SEND-DATAONLY-ALARM              VALUE '3'.

       01  WS-XCTL-PROGRAM-SW              PIC X VALUE 'N'.
           88 XCTL-PROGRAM                       VALUE 'Y'.      
       
      * Variables temporaires pour FETCH SQL (obligatoires pour OCCURS)
        01 WS-TEMP-OPERATION.
           05 WS-TEMP-ID                 PIC 9(10).
           05 WS-TEMP-ACCOUNT-ID         PIC 9(10).
           05 WS-TEMP-AMOUNT             PIC S9(8)V99 COMP-3.
           05 WS-TEMP-TYPE               PIC X(1).
           05 WS-TEMP-DATE               PIC X(10).
           05 WS-TEMP-AMOUNT-DISPLAY     PIC ZZZ,ZZ9.99.

     

      * Variables manquantes pour SQL
       01  WS-PRENOM-CLIENT           PIC X(20).
       01  WS-CURRENT-CLIENT-ID       PIC 9(10).
       01  WS-COMMUNICATION-AREA      PIC S9(9) COMP.
       01  WS-DISPLAY-LINE            PIC X(58).

      * Variables de travail
       01  WS-HEADER-LINE                  PIC X(58).
       01  OPERATION-LINE                  PIC X(79).
       01  WS-OP-COUNT                     PIC 9(2) VALUE 0.
       01  WS-OP-INDEX                     PIC 9(2) VALUE 0.
       
      * Variables de pagination
       01  WS-PAGE-NUMBER                  PIC S9(4) COMP VALUE 1.
       01  WS-TOTAL-OPERATIONS             PIC S9(4) COMP VALUE 0.
       01  WS-PAGE-OFFSET                  PIC S9(4) COMP VALUE 0.
       01  WS-MAX-PER-PAGE                 PIC S9(4) COMP VALUE 10.
       01  WS-PAGE-DISPLAY                 PIC 9(3) VALUE 1.
       01  WS-TOTAL-DISPLAY                PIC 9(5) VALUE 0.
       
       
       LINKAGE SECTION.
       01  DFHCOMMAREA.
           05 DFHCOM-ID-CLIENT PIC S9(9) COMP.
           05 DFHCOM-PAGE-NUM  PIC S9(4) COMP.
       
       PROCEDURE DIVISION.
       
       0000-MAIN-PROCEDURE.
           IF EIBCALEN > ZERO
                 MOVE DFHCOM-ID-CLIENT TO WS-COMMUNICATION-AREA
                 IF EIBCALEN >= 6
                    MOVE DFHCOM-PAGE-NUM TO WS-PAGE-NUMBER
                    COMPUTE WS-PAGE-OFFSET = 
                        (WS-PAGE-NUMBER - 1) * WS-MAX-PER-PAGE
                 END-IF
              END-IF.
           
              EVALUATE TRUE
                 WHEN EIBCALEN = 4 OR EIBAID = DFHCLEAR
                    MOVE LOW-VALUES TO LISTO
                    MOVE 1 TO WS-PAGE-NUMBER
                    MOVE 0 TO WS-PAGE-OFFSET
                    MOVE 1 TO WS-PAGE-DISPLAY
                    MOVE WS-PAGE-DISPLAY TO PAGEO
                    MOVE SPACES TO MESSAGEO
                    PERFORM 1050-LIRE-NOM
                    PERFORM 1060-LIRE-COMPTE
                    PERFORM 1200-LOAD-CLIENT-OPERATIONS
                    PERFORM 1300-BUILD-OPERATION-LINE
                    SET SEND-ERASE TO TRUE
                    PERFORM 1400-SEND-LIST-MAP
                 
                 WHEN EIBAID = DFHPA1 OR DFHPA2 OR DFHPA3
                     CONTINUE
           
                 WHEN EIBAID = DFHPF3 OR DFHPF12
                      SET XCTL-PROGRAM TO TRUE
           
                 WHEN EIBAID = DFHPF7
                      MOVE LOW-VALUES TO LISTO
                      PERFORM 1500-PAGE-PRECEDENTE
                      PERFORM 1050-LIRE-NOM
                      PERFORM 1060-LIRE-COMPTE
                      PERFORM 1200-LOAD-CLIENT-OPERATIONS
                      PERFORM 1300-BUILD-OPERATION-LINE
                      SET SEND-ERASE TO TRUE
                      PERFORM 1400-SEND-LIST-MAP
          
                 WHEN EIBAID = DFHPF8
                      MOVE LOW-VALUES TO LISTO
                      PERFORM 1600-PAGE-SUIVANTE
                      PERFORM 1050-LIRE-NOM
                      PERFORM 1060-LIRE-COMPTE
                      PERFORM 1200-LOAD-CLIENT-OPERATIONS
                      PERFORM 1300-BUILD-OPERATION-LINE
                      SET SEND-ERASE TO TRUE
                      PERFORM 1400-SEND-LIST-MAP
           
                 WHEN EIBAID = DFHENTER
                     PERFORM 1000-TRAITER-SAISIE
                     PERFORM 1200-LOAD-CLIENT-OPERATIONS
                     PERFORM 1300-BUILD-OPERATION-LINE
                     SET SEND-DATAONLY TO TRUE
                     PERFORM 1400-SEND-LIST-MAP
           
                 WHEN OTHER
                     PERFORM 1100-RECEIVE-LIST
                     MOVE 'TOUCHE INVALIDE' TO MESSAGEO
                     SET SEND-DATAONLY-ALARM TO TRUE
                     PERFORM 1400-SEND-LIST-MAP
           
              END-EVALUATE.
           
           IF NOT XCTL-PROGRAM
              MOVE WS-PAGE-NUMBER TO DFHCOM-PAGE-NUM
              EXEC CICS RETURN TRANSID('SN05')
                    COMMAREA(DFHCOMMAREA)
                    LENGTH(LENGTH OF DFHCOMMAREA)
              END-EXEC
           ELSE
              EXEC CICS XCTL PROGRAM('API8BM1P')
                   
              END-EXEC
              
           END-IF.
       1000-TRAITER-SAISIE.
           PERFORM 1100-RECEIVE-LIST.
           PERFORM 1050-LIRE-NOM.
           PERFORM 1060-LIRE-COMPTE.
       
       1050-LIRE-NOM.
           MOVE SPACES TO NCPTEO
           EXEC SQL
              SELECT PRENOM_CLIENT
              INTO :DCLCLIENT.WS-PRENOM-CLIENT
              FROM API8.CLIENT
              WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
           END-EXEC.
           
           EVALUATE SQLCODE
              WHEN 0
                 MOVE WS-PRENOM-CLIENT OF DCLCLIENT TO NCPTEO
              WHEN 100
                 MOVE 'CLIENT INCONNU' TO NCPTEO
              WHEN OTHER
                 MOVE 'ERREUR SQL' TO NCPTEO
           END-EVALUATE.
      
       1060-LIRE-COMPTE.
           EXEC SQL
              SELECT ID_COMPTE
              INTO :DCLOPERATION.WS-ID-COMPTE
              FROM API8.COMPTE
              WHERE ID_CLIENT = :WS-COMMUNICATION-AREA
           END-EXEC.
           
           IF SQLCODE = 0
              CONTINUE
           ELSE
              MOVE 'COMPTE INCONNU' TO NCPTEO
           END-IF.
       
       1100-RECEIVE-LIST.
           EXEC CICS RECEIVE MAP ('LIST')
              MAPSET ('APNSE05')
              INTO(LISTI)
           END-EXEC.

       
       1200-LOAD-CLIENT-OPERATIONS.
           MOVE 0 TO WS-OP-COUNT
           MOVE 1 TO WS-OP-INDEX
           MOVE SPACES TO OPERATION-LINE
           
      * Vérifier si un compte a été trouvé
           IF WS-ID-COMPTE OF DCLOPERATION = 0
              MOVE 'AUCUN COMPTE POUR CE CLIENT' TO MESSAGEO
           ELSE
           EXEC SQL
            DECLARE CUSTAPI8 CURSOR FOR
            SELECT ID_OPERATION, ID_COMPTE, MONTANT_OP, TYPE_OP, DATE_OP
            FROM API8.OPERATION
            WHERE ID_COMPTE = :DCLOPERATION.WS-ID-COMPTE
            ORDER BY ID_OPERATION DESC
           END-EXEC
              
              EXEC SQL
                 OPEN CUSTAPI8
              END-EXEC
              
              IF SQLCODE = 0
                    PERFORM 1210-FETCH-OPERATIONS
                    EXEC SQL
                       CLOSE CUSTAPI8
                    END-EXEC
              ELSE
                    MOVE 'ERREUR LECTURE OPERATIONS' TO MESSAGEO
              END-IF
           END-IF.
       
             
       1210-FETCH-OPERATIONS.
           MOVE 1 TO WS-OP-INDEX.
           MOVE 0 TO WS-OP-COUNT.
           MOVE 0 TO WS-TOTAL-OPERATIONS.
           
      *    Nettoyer OPELISTO avant de remplir
           PERFORM VARYING WS-OP-INDEX FROM 1 BY 1 
                   UNTIL WS-OP-INDEX > 10
              MOVE SPACES TO OPELISTO(WS-OP-INDEX)
              MOVE 70 TO OPELISTL(WS-OP-INDEX)
           END-PERFORM
           MOVE 1 TO WS-OP-INDEX
           
      *    Sauter les lignes des pages précédentes
           PERFORM WS-PAGE-OFFSET TIMES
              EXEC SQL
                 FETCH CUSTAPI8 INTO :DCLOPERATION.WS-ID-OPERATION,
                                     :DCLOPERATION.WS-ID-COMPTE,
                                     :DCLOPERATION.WS-MONTANT-OP,
                                     :DCLOPERATION.WS-TYPE-OP,
                                     :DCLOPERATION.WS-DATE-OP
              END-EXEC
              ADD 1 TO WS-TOTAL-OPERATIONS
           END-PERFORM
           
           PERFORM UNTIL WS-OP-INDEX > 10
              EXEC SQL
                 FETCH CUSTAPI8 INTO :DCLOPERATION.WS-ID-OPERATION,
                                        :DCLOPERATION.WS-ID-COMPTE,
                                        :DCLOPERATION.WS-MONTANT-OP,
                                        :DCLOPERATION.WS-TYPE-OP,
                                        :DCLOPERATION.WS-DATE-OP
              END-EXEC
              
              EVALUATE SQLCODE
                 WHEN 0
                     ADD 1 TO WS-OP-COUNT
                     ADD 1 TO WS-TOTAL-OPERATIONS
                     MOVE WS-ID-OPERATION OF DCLOPERATION TO WS-TEMP-ID
                     MOVE WS-ID-COMPTE     OF DCLOPERATION 
                     TO WS-TEMP-ACCOUNT-ID
                     MOVE WS-MONTANT-OP    OF DCLOPERATION 
                     TO WS-TEMP-AMOUNT
                     MOVE WS-TYPE-OP       OF DCLOPERATION 
                     TO WS-TEMP-TYPE
                     MOVE WS-DATE-OP       OF DCLOPERATION 
                     TO WS-TEMP-DATE
                     MOVE WS-TEMP-AMOUNT TO WS-TEMP-AMOUNT-DISPLAY
          
                     MOVE SPACES TO OPERATION-LINE
                     MOVE WS-TEMP-ID             
                     TO OPERATION-LINE(10:10)
                     MOVE WS-TEMP-ACCOUNT-ID     
                     TO OPERATION-LINE(24:10)
                     MOVE WS-TEMP-AMOUNT-DISPLAY 
                     TO OPERATION-LINE(36:10)
                     MOVE WS-TEMP-TYPE           
                     TO OPERATION-LINE(49:1)
                     MOVE WS-TEMP-DATE           
                     TO OPERATION-LINE(59:10)
                     MOVE SPACES
                     TO OPERATION-LINE(69:11)
          
                    MOVE OPERATION-LINE TO OPELISTO(WS-OP-INDEX)
                    MOVE 70 TO OPELISTL(WS-OP-INDEX)
                    ADD 1 TO WS-OP-INDEX
                     
                 WHEN 100
                     MOVE 11 TO WS-OP-INDEX
                     
                 WHEN OTHER
                     MOVE 'ERREUR LECTURE OPERATIONS' TO MESSAGEO
                     MOVE 11 TO WS-OP-INDEX
              END-EVALUATE
           END-PERFORM
           
      *    Continuer à compter les opérations restantes
           PERFORM UNTIL SQLCODE NOT = 0
              EXEC SQL
                 FETCH CUSTAPI8 INTO :DCLOPERATION.WS-ID-OPERATION,
                                        :DCLOPERATION.WS-ID-COMPTE,
                                        :DCLOPERATION.WS-MONTANT-OP,
                                        :DCLOPERATION.WS-TYPE-OP,
                                        :DCLOPERATION.WS-DATE-OP
              END-EXEC
              IF SQLCODE = 0
                 ADD 1 TO WS-TOTAL-OPERATIONS
              END-IF
           END-PERFORM.
           
           
       
       1300-BUILD-OPERATION-LINE.
           IF WS-OP-COUNT = 0
              MOVE 'AUCUNE OPERATION TROUVEE' TO OPELISTO(1)
           END-IF
           MOVE WS-TOTAL-OPERATIONS TO WS-TOTAL-DISPLAY
           MOVE WS-TOTAL-DISPLAY TO TOTALO.

       1400-SEND-LIST-MAP.
           EVALUATE TRUE
              WHEN SEND-ERASE
                 EXEC CICS SEND MAP ('LIST')
                     MAPSET ('APNSE05')
                     FROM(LISTO)
                     ERASE
                 END-EXEC
              WHEN SEND-DATAONLY
                 EXEC CICS SEND MAP ('LIST')
                     MAPSET ('APNSE05')
                     FROM(LISTO)
                     DATAONLY
                 END-EXEC
              WHEN SEND-DATAONLY-ALARM
                 EXEC CICS SEND MAP ('LIST')
                     MAPSET ('APNSE05')
                     FROM(LISTO)
                     DATAONLY
              END-EXEC
           END-EVALUATE.
       
       1410-RETURN-TO-LIST.
           MOVE WS-PAGE-NUMBER TO DFHCOM-PAGE-NUM
           EXEC CICS RETURN TRANSID('SN05')
              COMMAREA(DFHCOMMAREA)
              LENGTH(LENGTH OF DFHCOMMAREA)
           END-EXEC.
       
       1420-RETURN-TO-MENU.
           EXEC CICS 
              XCTL PROGRAM('API8BM1P')
           END-EXEC.
       
       1500-PAGE-PRECEDENTE.
      *    Aller à la page précédente
           IF WS-PAGE-NUMBER > 1
              SUBTRACT 1 FROM WS-PAGE-NUMBER
           END-IF
           COMPUTE WS-PAGE-OFFSET = 
               (WS-PAGE-NUMBER - 1) * WS-MAX-PER-PAGE.
           MOVE WS-PAGE-NUMBER TO WS-PAGE-DISPLAY
           MOVE WS-PAGE-DISPLAY TO PAGEO.
       
       1600-PAGE-SUIVANTE.
      *    Aller à la page suivante
           ADD 1 TO WS-PAGE-NUMBER
           COMPUTE WS-PAGE-OFFSET = 
               (WS-PAGE-NUMBER - 1) * WS-MAX-PER-PAGE.
           MOVE WS-PAGE-NUMBER TO WS-PAGE-DISPLAY
           MOVE WS-PAGE-DISPLAY TO PAGEO.
      