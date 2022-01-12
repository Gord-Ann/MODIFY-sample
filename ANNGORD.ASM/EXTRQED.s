EXTRQED  CSECT ,
EXTRQED  AMODE 24
EXTRQED  RMODE 24
         YREGS
         USING EXTRQED,R12
         STM   R14,R12,12(R13)
         LR    R12,R15
* ESTABLISH RSA CROSS REFERENCE
         LA    R7,SAVEAREA
         ST    R13,4(R7)
         ST    R7,8(R13)
         LR    R13,R7
         OPEN  (OUTFILE,(OUTPUT))
***---------------------
*** OBTAIN ADDR OF CIB
***---------------------
********                                   ********
* EXTRACT answer area,FIELDS=COMM                 *
* obtain a pointer to the ECB and to the first CIB*
********                                   ********
         EXTRACT COMPTR,FIELDS=COMM
         L     R9,COMPTR          POINTER TO COMM FIELDS
*** check if CIB related to a START
         USING COM,R9             USE R9 AS BASE ADDRESS OF COMM AREA
         CLI   COMCIBPT,X'0'
         BE    NOCIB
********                                              ********
* QEDIT ORIGIN=address of pointer to CIB,BLOCK=address of CIB*
* ORIGIN refers the the address of the COMCIBPT field        *
* BLOCK points the the CIB we wish to free                   *
********                                              ********
*        QEDIT ORIGIN=COMCIBPT,BLOCK=(R7)
         B     NEXT
NOCIB    EQU   *
         QEDIT ORIGIN=COMCIBPT,CIBCTR=1   SET CIB LIMIT
* WAIT FOR A COMMAND FROM THE CONSOLE
NEXT     EQU   *
         LA    R2,COMECBPT        ECB ADDRESS PTR
         L     R3,0(,R2)          ECB ADDRESS
WAIT     EQU   *
         WAIT  1,ECB=(R3)         WAIT FOR A COMMAND
*
*  WHEN POSTED HERE, A MODIFY OR STOP HAS BEEN ISSUED
         ICM   R7,15,COMCIBPT     GET CIB ADDRESS FROM COM AREA
         USING CIB,R7             BASE CIB MAPPING
         CLI   CIBVERB,CIBMODFY   WAS IT A MODIFY?
*        BNE   NOTDMFY            NO, GO FREE CIB
         BE    MODIFY             IT WAS A MODIFY
NOTMDFY  EQU   *
*        BAL   R14,FREECIB
         CLI   CIBVERB,CIBSTOP    WAS IT A STOP?
         BE    STOP               BRANCH TO STOP
         B     NEXT               WAIT FOR ANOTHER COMMAND
***---------------------
*** COMMANDS
***---------------------
* MODIFY COMMAND RECEIVED
MODIFY   EQU   *
         WTO   '*MODIFY*'
         LH    R5,CIBDATLN        GET COMMAND LENGTH
         LA    R6,CIBDATA         POINT TO COMMAND
*
CHECK    CLC   PCMD,CIBDATA       IF PARM IS STOP
         BE    STOP
         CLC   HCMD,CIBDATA       IF PARM IS HELP
         BE    HELP
         B     DOCIB
*
* STOP COMMAND RECEIVED
STOP     EQU   *
         WTO   '*STOP*'
         B     RETURN
* HELP PARM RECEIVED
HELP     EQU   *
         WTO   '*HELP*'
        
         B     DOCIB
***---------------------
*** COPY THE DATA AFTER MODIFY
***---------------------
DOCIB    EQU   *
         MVC   WORK,CLEAR         CLEAR WKAREA
         LR    R1,R5              COPY LENGTH
         BCTR  R1,0               SUBTRACT ONE
         EX    R1,MODMVC
MODMVC   MVC   WORK+1(1),0(R6)
         LA    R1,WORK
         AR    R1,R5
         LA    R0,8(,R5)
         B     CONT
CONT     EQU   *
         B PUT
*** WRITE DATA
PUT      EQU   *
         PUT   OUTFILE,WORK
         B     FREECIB
***---------------------
*** FREE THE CIB
***---------------------
FREECIB  EQU   *
* QEDIT ORIGIN=address of pointer to CIB,BLOCK=address of CIB
         QEDIT ORIGIN=COMCIBPT,BLOCK=(R7)
*
         B     NEXT
***---------------------
*** RETURN TO CALLER
RETURN   EQU   *
         CLOSE (OUTFILE)
         L     R13,4(R13)
         LM    R14,R12,12(R13)
         LA    R15,0
         BR    R14
***---------------------
*** DEFINE THE OUTOUT FILE
OUTFILE  DCB   DDNAME=OUT,                                             +
               DSORG=PS,                                               +
               LRECL=80,                                               +
               MACRF=PM,                                               +
               RECFM=FBA,                                              +
               BLKSIZE=160
***---------------------
*** VARIABLES
SAVEAREA DS    18F
MODECB   DS    A                  ADDR of ECB
COMPTR   DS    F                  COMAREA
ECBS     DS    0CL4               ECB LIST FOR WAIT
FIELD    DS    CL80
WORK     DS    CL80
CLEAR    DS    CL80
PCMD     DC    CL4'STOP'
HCMD     DC    CL4'HELP'
HLPBLK   DS    OH
***---------------------
*** REQUIRED DSECTs
COM      DSECT
         IEZCOM   ,                COM AREA
CIB      DSECT
         IEZCIB   ,                CIB
***
         LTORG
         END   EXTRQED