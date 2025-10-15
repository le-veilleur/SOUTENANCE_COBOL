//API8DBC JOB (ACCT#),'COMPDB2',MSGCLASS=H,REGION=4M,
//    CLASS=A,MSGLEVEL=(1,1),NOTIFY=&SYSUID,
//    COND=(4,LT),TIME=(0,5)
//*
//*------------------------------------------------------*
//* ===> CHANGER XX PAR N¢ DU GROUPE   (XX 01 @ 15)      *
//*      CHANGER     YYYYYYYY PAR LE NOM DU PROGRAMME    *
//*------------------------------------------------------*
//*
//*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-*
//*   CETTE PROCEDURE CONTIENT 5 STEPS :                             *
//*       ======> SI RE-EXECUTION FAIRE RESTART AU "STEPRUN"         *
//*                                                                  *
//*         1/  PRECOMPILE  DB2                                      *
//*         2/  COMPILE COBOL II                                     *
//*         3/  LINKEDIT  (DANS FORM.CICS.LOAD)                      *
//*         4/  BIND PLAN PARTIR DE API15.SOURCE.DBRMLIB             *
//*         5/  EXECUTE DU PROGRAMME                                 *
//*  LES   PROCEDURES  SE TROUVENT DANS SDJ.FORM.PROCLIB             *
//*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-*
//PROCLIB  JCLLIB ORDER=SDJ.FORM.PROCLIB
//*
//         SET NOMPGM=FILDB
//*
//APPROC   EXEC COMPDB2
//STEPDB2.SYSLIB   DD DSN=&SYSUID..COB.CPY,DISP=SHR
//STEPDB2.SYSIN    DD DSN=&SYSUID..COB.SRC(&NOMPGM),DISP=SHR
//STEPDB2.DBRMLIB  DD DSN=&SYSUID..COB.DBRM(&NOMPGM),DISP=SHR
//STEPCOB.SYSLIB   DD DSN=&SYSUID..COB.CPY,DISP=SHR
//STEPLNK.SYSLMOD  DD DSN=&SYSUID..COB.LOAD(&NOMPGM),DISP=SHR
//*
//*--- ETAPE DE BIND --------------------------------------
//*
//BIND     EXEC PGM=IKJEFT01,COND=(4,LT)
//DBRMLIB  DD  DSN=&SYSUID..COB.DBRM,DISP=SHR
//SYSTSPRT DD  SYSOUT=*,OUTLIM=25000
//SYSTSIN  DD  *
  DSN SYSTEM (DSN1)
  BIND PLAN      (FILDB) -
       QUALIFIER (API8)    -
       ACTION    (REPLACE)  -
       MEMBER    (FILDB) -
       VALIDATE  (BIND)     -
       ISOLATION (CS)       -
       ACQUIRE   (USE)      -
       RELEASE   (COMMIT)   -
       EXPLAIN   (NO)
/*
//STEPRUN  EXEC PGM=IKJEFT01,COND=(4,LT)
//STEPLIB  DD  DSN=&SYSUID..COB.LOAD,DISP=SHR
//SYSOUT   DD  SYSOUT=*,OUTLIM=1000
//SYSTSPRT DD  SYSOUT=*,OUTLIM=2500
//INP001   DD  DSN=API8.COB.FIC.FCLI,DISP=SHR
//INP002   DD  DSN=API8.COB.FIC.FCOMPT,DISP=SHR
//*ETATCLI  DD  SYSOUT=*
//*ETATANO  DD  SYSOUT=*
//SYSTSIN  DD  *
  DSN SYSTEM (DSN1)
  RUN PROGRAM(FILDB) PLAN (FILDB)
//
