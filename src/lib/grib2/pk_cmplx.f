      SUBROUTINE PK_CMPLX(KFILDO,IA,NXY,IPACK,ND5,LOCN,IPOS,
     1                    IS5,NS5,IS7,NS7,INC,MINPK,MISSP,
     2                    MISSS,IBIT,LOCN5_32,IPOS5_32,L3264B,
     3                    IER,*)
C
C        SEPTEMBER 1994   GLAHN    TDL   HP
C        JUNE      1999   LAWRENCE UPDATED THIS ROUTINE TO BE USED
C                                  WITH GRIB2.  THE ACTUAL METHOD
C                                  OF PACKING IS UNCHANGED.
C        MARCH     2000   LAWRENCE UPDATED TO REFLECT MINOR CHANGES
C                                  IN THE GRIB2 DOCUMENTATION.
C        MARCH     2000   GLAHN    RESTRUCTURED
C        JANUARY   2001   GLAHN    COMMENTS; CHANGED ERROR CODE NUMBERS;
C                                  ADDED IER AND * TO CALL TO PACK_GP
C        NOVEMBER  2001   GLAHN    CHANGED NUMBITS=(IS5(48)*8)-1 TO
C                                  NUMBITS=(IS5(49)*8)-1; ADDED * TO
C                                  900 IN RETURN FROM PACK_GP
C        MARCH     2002   GLAHN    ADDED IERSAV=0
C        PURPOSE
C            PACKS DATA AT "UNITS" RESOLUTION PROVIDED IN
C            IA( ).  VALUES ARE TAKEN OUT AT NONUNIFORM STEPS WITH 
C            A MINIMUM GROUP SIZE OF MINPK.  PACKING CONFORMS WITH 
C            THE WMO STANDARD GRIB2. IS5( ) CORRESPONDS TO 
C            GRIB2 SECTION 5.
C
C            THE FOLLOWING EQUATION IS USED TO PACK THE DATA:
C               X1 = [(Y - R) * (2 ** -E) * (10 ** -D)] - X2
C                    X1 = THE PACKED VALUE
C                     Y = THE VALUE WE ARE PACKING
C                     R = THE REFERENCE VALUE (FIRST ORDER MINIMA)
C                     E = THE BINARY SCALE FACTOR
C                     D = THE DECIMAL SCALE FACTOR
C                    X2 = THE SECOND ORDER MINIMA
C            R HAS ALREADY BEEN REMOVED UPON ENTRY.
C
C        DATA SET USE 
C           KFILDO - UNIT NUMBER FOR OUTPUT (PRINT) FILE. (OUTPUT) 
C
C        VARIABLES 
C              KFILDO = UNIT NUMBER FOR OUTPUT (PRINT) FILE.  (INPUT) 
C               IA(K) = DATA TO PACK (K=1,NXY).  (INPUT)
C                 NXY = THE DIMENSION OF IA( ). (INPUT) 
C            IPACK(J) = THE ARRAY TO HOLD THE ACTUAL PACKED MESSAGE
C                       (J=1,MAX OF ND5).  (INPUT/OUTPUT)
C                 ND5 = DIMENSION OF IPACK( ).  (INPUT)
C                LOCN = THE WORD POSITION TO PLACE THE NEXT VALUE.
C                       (INPUT/OUTPUT)
C                IPOS = THE BIT POSITION IN LOCN TO START PLACING
C                       THE NEXT VALUE. (INPUT/OUTPUT)
C              IS5(K) = CONTAINS DATA THAT CORRESPONDS TO SECTION
C                       5 OF THE GRIB2 MESSAGE (K=1,NS5). 
C                       (INPUT/OUTPUT)
C                 NS5 = DIMENSION OF IS5( ). (INPUT)
C              IS7(K) = CONTAINS THE GRID DEFINITION DATA THAT
C                       WILL BE PACKED INTO IPACK( ) (K=1,NS7).
C                       (INPUT)
C                 NS7 = SIZE OF IS7( ). (INPUT)
C                 INC = NUMBER OF VALUES TO ADD TO THE GROUP TO BE
C                       PACKED AT A TIME.  (INPUT)
C               MINPK = VALUES ARE PACKED IN GROUPS OF MINIMUM SIZE
C                       MINPK.  ONLY WHEN THE NUMBER OF BITS TO HANDLE
C                       A GROUP CHANGES WILL A NEW GROUP BE FORMED.
C                       (INPUT)
C               MISSP = THE PRIMARY MISSING VALUE.  (INPUT)
C               MISSS = THE SECONDARY MISSING VALUE.  (INPUT)
C               IBIT =  THE NUMBER OF BITS REQUIRED TO PACK THE GROUP
C                       MINIMUM VALUES.  (OUTPUT)
C           LOCN5_32 = LOCN FOR OCTET 32 IN SECTION 5.  (INPUT)
C           IPOS5_32 = IPOS FOR OCTET 32 IN SECTION 5.  (INPUT)
C              L3264B = CONTAINS THE NUMBER OF BITS IN A WORD
C                       IMPLEMENTED ON THIS PARTICULAR PLATFORM.
C                       (INPUT).
C                 IER = ERROR RETURN
C                       1-4 = ERROR CODES GENERATED BY PKBG. SEE THE 
C                             DOCUMENTATION IN THE PKBG ROUTINE.
C                       705 = ND5 IS NOT LARGE ENOUGH TO ACCOMMODATE THE
C                             BITS NECESSARY TO PACK THE VALUES STARTING
C                             AT THE VALUES LOCN AND IPOS.  RETURNED FROM
C                             PK_S7.
C                       711 = LBIT INCORRECT.
C                       712 = INCORRECT SPLITTING METHOD.
C                       713 = UNRECOGNIZED MISSING VALUE FLAG
C                             IN IS5(23).  (OUTPUT)
C                   * = ALTERNATE RETURN WHEN IER NE 0.
C
C        LOCAL VARIABLES
C               IFILL = NUMBER OF BITS TO PAD MESSAGE (AT THAT POINT
C                       IN THE PROCESS) TO AN EVEN OCTET.
C              IFIRST = KEEPS TRACK OF WHETHER OR NOT THIS IS THE
C                       FIRST TIME THAT THIS ROUTINE HAS BEEN CALLED.
C               IZERO = CONTAINS 0.
C             JMAX(M) = THE MAXIMUM OF EACH GROUP M OF PACKED VALUES
C                       AFTER SUBTRACTING THE GROUP MINIMUM VALUE
C                       (M=1,LX). (NOT ACTUALLY USED)  (AUTOMATIC)
C             JMIN(M) = THE MINIMUM VALUE SUBTRACTED FOR EACH GROUP M
C                       (M=1,LX).  (AUTOMATIC)
C              NOV(M) = THE NUMBER OF VALUES IN GROUP M (M=1,LX).
C                       AFTER THE REFERENCE VALUE IS REMOVED.
C                       (AUTOMATIC)
C              NOVREF = THE REFERENCE VALUE FOR NOV( ).
C                KBIT = THE NUMBER OF BITS USED TO PACK THE WIDTH
C                       OF WIDTHS.
C               LB2M1 = CONTAINS THE POWERS OF TWO ALLOWING FOR
C                       ONE MISSING VALUE.
C              LB2M1L = CONTAINS THE NUMBER OF BITS TO PACK A VALUE
C                       IN WHEN THERE ARE ONLY PRIMARY MISSING VALUES.
C               LB2M2 = CONTAINS THE POWERS OF TWO ALLOWING FOR
C                       TWO MISSING VALUES.
C              LB2M2L = CONTAINS THE NUMBER OF BITS TO PACK A VALUE
C                       IN WHEN THERE ARE BOTH PRIMARY AND 
C                       SECONDARY MISSING VALUES.
C             LBIT(M) = THE NUMBER OF BITS NECESSARY TO HOLD THE
C                       PACKED VALUES FOR EACH GROUP M (M=1,LX)
C                       AFTER THE REFERENCE IS REMOVED.  (AUTOMATIC)
C             LBITREF = THE REFERENCE VALUE FOR LBIT( ).
C                KBIT = THE WIDTH OF THE GROUP MINIMA.
C                  LX = THE NUMBER OF GROUPS.
C              NCOUNT = COUNTS THE VALUES ACTUALLY PACKED.  THIS CAN BE
C                       LESS THAN NXY WHEN ONE OR MORE GROUPS HAVE THE
C                       SAME VALUE, AND THE VALUES ARE OMITTED.
C                       (NOT ACTUALLY USED.)
C                   N = LOCAL VALUE OF L3264B.
C
C        NON SYSTEM SUBROUTINES CALLED 
C           PACK_GP, PKBG, PK_S7, PK_C7
C
      DIMENSION IA(NXY)
      DIMENSION JMAX(NXY),JMIN(NXY),NOV(NXY),LBIT(NXY)
C        JMAX( ), JMIN( ), NOV( ), AND LBIT( ) ARE AUTOMATIC ARRAYS.
C        IT IS LIKELY DIMENSIONS OF NXY/MINPK WOULD SUFFICE.
      DIMENSION IPACK(ND5)
      DIMENSION IS5(NS5),IS7(NS7)
      DIMENSION LB2M1(0:30),LB2M2(0:30)
C
      SAVE LB2M1,LB2M2
C
      DATA IZERO/0/
      DATA IFIRST/0/
C
C         CALCULATE THE POWERS OF 2 THE FIRST TIME ENTERED.
C
      IER=0
      IERSAV=0
      N=L3264B
C
      IF(IFIRST.EQ.0)THEN
         IFIRST=1
         LB2M1(0)=0
         LB2M2(0)=-1
C
         DO 100 J=1,30
            LB2M1(J)=(LB2M1(J-1)+1)*2-1
            LB2M2(J)=(LB2M2(J-1)+2)*2-2
 100     CONTINUE
C
      ENDIF
C
      IF(IS5(22).NE.1)THEN
C
C           ONLY THE "GENERAL" GROUPING (OR SPLITTING) METHOD
C           IS SUPPORTED.
         IER=712
         GO TO 900
      ENDIF
C
      CALL PACK_GP(KFILDO,IA,NXY,IS5,NS5,MINPK,INC,MISSP,MISSS,
     1             JMIN,JMAX,LBIT,NOV,NXY,LX,IBIT,JBIT,KBIT,
     2             NOVREF,LBITREF,IER,*900)     
      IERSAV=IER
      IER=0
C        IERSAV CAN BE USED IN THE CALLING ROUTINE TO PROVIDE
C        ERROR TRACING.  SUBROUTINE REDUCE CAN PRODUCE NON
C        FATAL ERRORS.  OTHER ERRORS ARE FATAL AND RETURN IS
C        TO *900.
C
C        SUBTRACT LOCAL MIN FOR EACH OF LX GROUPS.
C        SEPARATE LOOPS USED FOR EFFICIENCY, DEPENDING
C        ON POSSIBILITY OF MISSING VALUES.
      IF(IS5(23).EQ.0)THEN
C           THERE ARE NO MISSING VALUES.
         K=0
C
         DO 120 L=1,LX
            DO 119 M=1,NOV(L)+NOVREF
               K=K+1
               IA(K)=IA(K)-JMIN(L)
 119        CONTINUE
 120     CONTINUE
C
      ELSEIF(IS5(23).EQ.1)THEN
C           THERE ARE NO SECONDARY MISSING VALUES.
C
         K=0
C
         DO 130 L=1,LX
         LB2M1L=LB2M1(LBIT(L)+LBITREF)
C
         DO 129 M=1,NOV(L)+NOVREF
         K=K+1
C
         IF(IA(K).EQ.MISSP)THEN
            IA(K)=LB2M1L
         ELSE
            IA(K)=IA(K)-JMIN(L)
         ENDIF
C
 129     CONTINUE
 130     CONTINUE
C
      ELSEIF(IS5(23).EQ.2)THEN
C           THERE ARE BOTH PRIMARY AND SECONDARY MISSING VALUES.
C
         K=0
C
         DO 140 L=1,LX
         LB2M1L=LB2M1(LBIT(L)+LBITREF)
         LB2M2L=LB2M2(LBIT(L)+LBITREF)
C
         IF((LBIT(L)+LBITREF).LT.2)THEN
C           WRITE(KFILDO,135)LBIT(L),MISSS
C135        FORMAT(/' ****LBIT(L) ='I2,' IS LT 2 IN PK_CMPLX',
C    1              ' FOR MISSS ='I5)
            IER=711
            GO TO 900
         ENDIF
C
         DO 139 M=1,NOV(L)+NOVREF
         K=K+1
C
         IF(IA(K).EQ.MISSP)THEN
            IA(K)=LB2M1L
         ELSEIF(IA(K).EQ.MISSS)THEN
            IA(K)=LB2M2L
         ELSE
            IA(K)=IA(K)-JMIN(L)
         ENDIF
C
 139     CONTINUE
 140     CONTINUE
C
      ELSE
C
C           INVALID VALUE IN IS5(23).
         IER=713
         GOTO 900
      ENDIF
C
C        FILL APPROPRIATE ELEMENTS OF IS5( ).
C
      IS5(32)=LX
      IS5(36)=LBITREF
      IS5(37)=JBIT
      IS5(38)=NOVREF
      IS5(42)=1
      IS5(43)=NOV(LX)+NOVREF
      IS5(47)=KBIT
C
C        TEMPORARY DIAGNOSTIC OUTPUT FOR COMPLEX PACKING.
C     WRITE(KFILDO,101)IBIT
C101  FORMAT(/' NUMBER OF BITS TO PACK THE GROUP REFERENCES = ',I6)
C     WRITE(KFILDO,102)JBIT, LBITREF
C102  FORMAT(/' NUMBER OF BITS TO PACK GROUP WIDTHS =         ',I6,//
C    1        ' REFERENCE FOR GROUP WIDTHS =                  ',I6)
C     WRITE(KFILDO,103)KBIT, NOVREF
C103  FORMAT(/' NUMBER OF BITS TO PACK THE GROUP LENGTHS =    ',I6,//
C    1        ' REFERENCE FOR GROUP LENGTHS =                 ',I6)
C     WRITE(KFILDO,104)IS5(42)
C104  FORMAT(/' LENTGH INCREMENT FOR GROUP LENGTHS =          ',I6)
C     WRITE(KFILDO,105)IS5(43)
C105  FORMAT(/' LAST GROUP''S TRUE LENGTH =                  ',I8)
C     WRITE(KFILDO,106)LX
C106  FORMAT(/' THE NUMBER OF GROUPS IN THE PACKED MESSAGE =',I8,//)
C
C***D     DO 110 J=1,LX
C***D        WRITE(KFILDO,115) J,NOV(J),JMIN(J),LBIT(J)
C***D115     FORMAT(' GROUP ',I6,'     LENGTH = ',I8,'     REF = ',I8,
C***D    1           '     WIDTH = ',I6)
C***D110  END DO
C
      LOCN5=LOCN5_32
      IPOS5=IPOS5_32
      CALL PKBG(KFILDO,IPACK,ND5,LOCN5,IPOS5,IS5(32),32,N,IER,*900)
      CALL PKBG(KFILDO,IPACK,ND5,LOCN5,IPOS5,IS5(36),8,N,IER,*900)
      CALL PKBG(KFILDO,IPACK,ND5,LOCN5,IPOS5,IS5(37),8,N,IER,*900)
      CALL PKBG(KFILDO,IPACK,ND5,LOCN5,IPOS5,IS5(38),32,N,IER,*900)
      CALL PKBG(KFILDO,IPACK,ND5,LOCN5,IPOS5,IS5(42),8,N,IER,*900)
      CALL PKBG(KFILDO,IPACK,ND5,LOCN5,IPOS5,IS5(43),32,N,IER,*900)
      CALL PKBG(KFILDO,IPACK,ND5,LOCN5,IPOS5,IS5(47),8,N,IER,*900)
C
      IF(IS5(10).EQ.3)THEN
         CALL PKBG(KFILDO,IPACK,ND5,LOCN5,IPOS5,IS5(48),8,N,IER,*900)
         CALL PKBG(KFILDO,IPACK,ND5,LOCN5,IPOS5,IS5(49),8,N,IER,*900)
C
C           PACK THE ADDITIONAL INFORMATION FOR SECOND ORDER
C           DIFFERENCING IN SECTION 7 HERE (THE FIRST AND SECOND
C           ORIGINAL VALUES AND THE MINIMUM OF THE FIELD OF
C           SECOND ORDER DIFFERENCES).
         NUMBITS=(IS5(49)*8)-1
         ISIGN=0
         IF(IS7(6).LT.0)ISIGN=1
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,ISIGN,1,N,IER,*900)
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,ABS(IS7(6)),
     1             NUMBITS,N,IER,*900)
         ISIGN=0
         IF(IS7(7).LT.0)ISIGN=1
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,ISIGN,1,N,IER,*900)
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,ABS(IS7(7)),
     1             NUMBITS,N,IER,*900)
         ISIGN=0
         IF(IS7(8).LT.0)ISIGN=1
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,ISIGN,1,N,IER,*900)
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,ABS(IS7(8)),
     1             NUMBITS,N,IER,*900)
      ENDIF
C
C        PACK THE MINIMUM VALUES FOR EACH GROUP--THE GROUP
C        REFERENCE VALUES.  NOTE THAT THIS USES LOCN,IPOS, NOT
C        THE LOCN5,IPOS5 FROM DIRECTLY ABOVE.
C
      CALL PK_S7(KFILDO,IPACK,ND5,LOCN,IPOS,JMIN,LX,IBIT,N,IER,*900)
C
C        PAD WITH ZERO BITS TO FILL OUT AN OCTET.
C
      IFILL=MOD(33-IPOS,8)
C
      IF(IFILL.NE.0)THEN
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IZERO,IFILL,N,IER,*900)
      ENDIF
C
C        PACK THE NUMBER OF BITS REQUIRED FOR THE VALUES IN
C        EACH GROUP--THE GROUP WIDTHS.
C
      CALL PK_S7(KFILDO,IPACK,ND5,LOCN,IPOS,LBIT,LX,JBIT,N,IER,*900)
C
C        PAD WITH ZERO BITS TO FILL OUT AN OCTET.
C
      IFILL=MOD(33-IPOS,8)
C
      IF(IFILL.NE.0)THEN
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IZERO,IFILL,N,IER,*900)
      ENDIF
C
C        PACK THE LENGTHS OF EACH GROUP.
C
      CALL PK_S7(KFILDO,IPACK,ND5,LOCN,IPOS,NOV,LX,KBIT,N,IER,*900)
C
C        PAD WITH ZERO BITS TO FILL OUT AN OCTET.
C
      IFILL=MOD(33-IPOS,8)
C
      IF(IFILL.NE.0)THEN
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IZERO,IFILL,N,IER,*900)
      ENDIF
C
C        PACK THE VALUES, WITH BOTH FIRST AND SECOND ORDER MINIMA OUT.
C
      NCOUNT=0
C
C        PUT THE FIELD WIDTH AND BIT REFERENCES BACK INTO 
C        NOV AND LBIT FOR THE PURPOSE OF PACKING THE ACTUAL
C        VALUES.  THESE WERE REMOVED IN PACK_GP.
      DO K=1,LX
         NOV(K)=NOV(K)+NOVREF
         LBIT(K)=LBIT(K)+LBITREF
      ENDDO
C
      CALL PK_C7(KFILDO,IPACK,ND5,LOCN,IPOS,IA,NXY,NOV,LBIT,LX,
     1           N,NCOUNT,IER,*900)
C
C        PAD WITH ZERO BITS TO FILL OUT AN OCTET.
C
      IFILL=MOD(33-IPOS,8)
C
      IF(IFILL.NE.0)THEN
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IZERO,IFILL,N,IER,*900)
      ENDIF
C
 900  IF(IER.NE.0)RETURN1
C
      IF(IERSAV.NE.0)IER=IERSAV
      RETURN
      END
