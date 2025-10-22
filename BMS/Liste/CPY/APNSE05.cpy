       01  LISTI.
           02  FILLER PIC X(12).
           02  NCPTEL    COMP  PIC  S9(4).
           02  NCPTEF    PICTURE X.
           02  FILLER REDEFINES NCPTEF.
             03 NCPTEA    PICTURE X.
           02  FILLER   PICTURE X(6).
           02  NCPTEI  PIC X(15).
           02  OPELISTD OCCURS 10 TIMES.
             03  OPELISTL    COMP  PIC  S9(4).
             03  OPELISTF    PICTURE X.
             03  FILLER   PICTURE X(6).
             03  OPELISTI  PIC X(70).
           02  PAGEL    COMP  PIC  S9(4).
           02  PAGEF    PICTURE X.
           02  FILLER REDEFINES PAGEF.
             03 PAGEA    PICTURE X.
           02  FILLER   PICTURE X(6).
           02  PAGEI  PIC X(3).
           02  TOTALL    COMP  PIC  S9(4).
           02  TOTALF    PICTURE X.
           02  FILLER REDEFINES TOTALF.
             03 TOTALA    PICTURE X.
           02  FILLER   PICTURE X(6).
           02  TOTALI  PIC X(5).
           02  MESSAGEL    COMP  PIC  S9(4).
           02  MESSAGEF    PICTURE X.
           02  FILLER REDEFINES MESSAGEF.
             03 MESSAGEA    PICTURE X.
           02  FILLER   PICTURE X(6).
           02  MESSAGEI  PIC X(60).
       01  LISTO REDEFINES LISTI.
           02  FILLER PIC X(12).
           02  FILLER PICTURE X(3).
           02  NCPTEC    PICTURE X.
           02  NCPTEP    PICTURE X.
           02  NCPTEH    PICTURE X.
           02  NCPTEV    PICTURE X.
           02  NCPTEU    PICTURE X.
           02  NCPTEM    PICTURE X.
           02  NCPTEO  PIC X(15).
           02  DFHMS1 OCCURS 10 TIMES.
             03  FILLER PICTURE X(2).
             03  OPELISTA    PICTURE X.
             03  OPELISTC    PICTURE X.
             03  OPELISTP    PICTURE X.
             03  OPELISTH    PICTURE X.
             03  OPELISTV    PICTURE X.
             03  OPELISTU    PICTURE X.
             03  OPELISTM    PICTURE X.
             03  OPELISTO  PIC X(70).
           02  FILLER PICTURE X(3).
           02  PAGEC    PICTURE X.
           02  PAGEP    PICTURE X.
           02  PAGEH    PICTURE X.
           02  PAGEV    PICTURE X.
           02  PAGEU    PICTURE X.
           02  PAGEM    PICTURE X.
           02  PAGEO  PIC X(3).
           02  FILLER PICTURE X(3).
           02  TOTALC    PICTURE X.
           02  TOTALP    PICTURE X.
           02  TOTALH    PICTURE X.
           02  TOTALV    PICTURE X.
           02  TOTALU    PICTURE X.
           02  TOTALM    PICTURE X.
           02  TOTALO  PIC X(5).
           02  FILLER PICTURE X(3).
           02  MESSAGEC    PICTURE X.
           02  MESSAGEP    PICTURE X.
           02  MESSAGEH    PICTURE X.
           02  MESSAGEV    PICTURE X.
           02  MESSAGEU    PICTURE X.
           02  MESSAGEM    PICTURE X.
           02  MESSAGEO  PIC X(60).
