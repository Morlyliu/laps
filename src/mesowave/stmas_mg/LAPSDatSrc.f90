!dis    Forecast Systems Laboratory
!dis    NOAA/OAR/ERL/FSL
!dis    325 Broadway
!dis    Boulder, CO     80303
!dis
!dis    Forecast Research Division
!dis    Local Analysis and Prediction Branch
!dis    LAPS
!dis
!dis    This software and its documentation are in the public domain and
!dis    are furnished "as is."  The United States government, its
!dis    instrumentalities, officers, employees, and agents make no
!dis    warranty, express or implied, as to the usefulness of the software
!dis    and documentation for any purpose.  They assume no responsibility
!dis    (1) for the use of the software and documentation; or (2) to provide
!dis    technical support to users.
!dis
!dis    Permission to use, copy, modify, and distribute this software is
!dis    hereby granted, provided that the entire disclaimer notice appears
!dis    in all copies.  All modifications to this software must be clearly
!dis    documented, and are solely the responsibility of the agent making
!dis    the modifications.  If significant modifications or enhancements
!dis    are made to this software, the FSL Software Policy Manager
!dis    (softwaremgr@fsl.noaa.gov) should be notified.
!dis

MODULE LAPSDatSrc

!==========================================================
!  This module defines LAPS data retrieval functionality.
!
!  HISTORY:
!	Creation: YUANFU XIE	8-2005
!==========================================================

  USE Definition

CONTAINS

SUBROUTINE LAPSInfo

!==========================================================
!  This routine configures the STMAS for its analyses.
!  Tasks:
!	1. 
!
!  NOTE: three letter variables are local; six global;
!
!  HISTORY: 
! 	Creation: YUANFU XIE	6-2005
!==========================================================

  IMPLICIT NONE

  ! Local variables:
  CHARACTER*9 :: fnm
  INTEGER :: err	! Error indicator
  INTEGER :: i

  !*********************
  ! LAPS configuration:
  !*********************

  ! Get number of gridpoints:
  CALL GET_GRID_DIM_XY(numgrd(1),numgrd(2),err)
  IF (err .ne. 1) PRINT*, 'STMAS>LAPSInfo: Error getting numgrd'

  ! Get LAPS cycle time:
  CALL GET_LAPS_CYCLE_TIME(lapsdt,err)
  IF (err .ne. 1) PRINT*, 'STMAS>LAPSInfo: Error getting cycle time'

  ! Get current system time:
  CALL GET_SYSTIME(i4time,fnm,err)

  ! Get a flag for missing data:
  CALL GET_R_MISSING_DATA(mising,err)
  IF (err .ne. 1) PRINT*, 'STMAS>LAPSInfo: Error getting mising flag'

  ! Get a flag for bad surface data:
  CALL GET_SFC_BADFLAG(badsfc,err)
  IF (err .ne. 1) PRINT*, 'STMAS>LAPSInfo: Error getting badsfc flag'

  CALL GET_MAXSTNS(mxstts,err)
  IF (err .ne. 1) print*, 'STMAS>LAPSInfo: Error getting maxstations'

  ! Check:
  IF (verbal .EQ. 1) THEN
    WRITE(*,1) numgrd(1:3),lapsdt,mxstts,mising,badsfc
  ENDIF
1 FORMAT('STMAS>LAPSInfo: Num  gridpoints: ',3I6,/, &
	 'STMAS>LAPSInfo: LAPS cycle time: ',I6,/, &
	 'STMAS>LAPSInfo: Maxnumber sites: ',I6,/, &
	 'STMAS>LAPSInfo: Missing/bad ids: ',e16.8,f16.5)

END SUBROUTINE LAPSInfo

SUBROUTINE LAPSConf

!==========================================================
!  This routine reads in necessary configuration grid data.
!
!  HISTORY: 
!	Creation: 8-2005 by YUANFU XIE.
!==========================================================

  IMPLICIT NONE

  ! Local variables:
  CHARACTER*9 :: fnm,ext,var
  CHARACTER :: unt*60,com*60
  INTEGER :: i,j,err	! Error indicator

  ! Physical grid points and spacing info:
  ext = 'nest7grid'
  var = 'LAT'
  CALL RD_LAPS_STATIC(dirstc,ext,numgrd(1),numgrd(2),1, &
		      var,unt,com,latgrd,phydxy(1),err)
  IF (err .NE. 1) PRINT*,'STMAS>LAPSInfo: Error getting LAT'
  var = 'LON'
  CALL RD_LAPS_STATIC(dirstc,ext,numgrd(1),numgrd(2),1, &
		      var,unt,com,longrd,phydxy(2),err)
  IF (err .NE. 1) PRINT*,'STMAS>LAPSInfo: Error getting LON'
  var = 'LDF'
  CALL RD_LAPS_STATIC(dirstc,ext,numgrd(1),numgrd(2),1, &
		      var,unt,com,lndfac,grdspc(2),err)
  IF (err .NE. 1) PRINT*,'STMAS>LAPSInfo: Error getting LON'
  ! Removing meaningless land factors:
  DO j=1,numgrd(2)
    DO i=1,numgrd(1)
      IF (lndfac(i,j) .GT. 1.0) lndfac(i,j) = 1.0
      IF (lndfac(i,j) .LT. 0.0) lndfac(i,j) = 0.0
    ENDDO
  ENDDO

  ! time step:
  grdspc(3) = lapsdt

  !*********************
  ! STMAS configuration:
  !*********************

  ! Analysis grid numbers:
  numgrd = numgrd+2*numfic

  ! Analysis domain:
  domain(1,1:2) = 1.0-numfic(1:2)	! X/Y: use grid numbers
  domain(2,1:2) = FLOAT(numgrd(1:2)-numfic(1:2))
  domain(1,3) = MOD(i4time-(numtmf-1)*lapsdt,86400)
  domain(2,3) = domain(1,3)+(numtmf-1)*lapsdt
  grdspc(1:2) = 1.0			! Based the domain setting

END SUBROUTINE LAPSConf

SUBROUTINE LAPSBKGD

!==========================================================
!  This routine reads into LGA background fields from LAPS.
!
!  HISTORY: 
! 	Creation: YUANFU XIE	8-2005
!==========================================================

  IMPLICIT NONE

  CHARACTER*31 :: ext	! extension of bkg file used (LAPS)
  INTEGER :: i,j,err	! err: 1 normal; 0 file not found
  INTEGER :: tim	! time of bkg file used (LAPS)
  INTEGER :: iwv	! index for v component of wind

  ! Set LAPS circle time frames:
  DO i=0,numtmf-1
    i4prev(numtmf-i) = i4time-i*lapsdt
  ENDDO

  ! Check LAPS time frames:
  IF (verbal .EQ. 1) THEN
    DO i=1,numtmf
      WRITE(*,11) i,i4prev(i),MOD(i4prev(i),86400)
    ENDDO
  ENDIF
11 FORMAT('STMAS>LAPSBKGD: LAPS Time stamp',I3,':',I11,I7)

  ! Read background fields:
  DO j=1,numvar

    ! Wind:
    IF (varnam(j) .EQ. 'WNDU') THEN
      ! Search index for v component of wind:
      iwv = 0
      DO i=1,numvar
        IF (varnam(i) .EQ. 'WNDV') iwv = i
      ENDDO
      IF (iwv .EQ. 0) THEN
	WRITE(*,12)
	STOP
      ENDIF
12 FORMAT('STMAS>LAPSBKGD: V component of wind is missing!')

      ! Get wind fields:
      DO i=1,numtmf
	CALL GET_BKGWIND_SFC(i4prev(i),ext,tim, &
	  bkgrnd(1,1,i,j),bkgrnd(1,1,i,iwv),lapsdt, &
	  numgrd(1),numgrd(2),err)
	IF (err .EQ. 0) WRITE(*,13) varnam(j),i4prev(i),i,j
      ENDDO

    ! Other fields:
    ELSE IF ((varnam(j) .NE. 'WNDV') .AND. &	! V in with U
	     (varnam(j) .NE. 'CEIL')) THEN	! No ceiling bkg
      DO i=1,numtmf
        CALL GET_BACKGROUND_SFC(i4prev(i),varnam(j),ext,tim, &
	  bkgrnd(1,1,i,j),lapsdt,numgrd(1),numgrd(2),err)
	IF (err .EQ. 0) WRITE(*,13) varnam(j),i4prev(i),i,j
      ENDDO
    ELSE
      IF (needbk(j) .EQ. 0) &
        bkgrnd(1:numgrd(1),1:numgrd(2),1:numtmf,j) = 0.0
    ENDIF
  ENDDO
13 FORMAT('STMAS>LAPSBKGD: Background is not found for: ',A4,i16,2i3)

  ! Save background if requested for debugging:
  IF (savdat .EQ. 1) THEN
    OPEN(unit=10,file='STMAS_bkg.dat',form='formatted')
    WRITE(10,*) numgrd(1:2),numtmf,domain
    WRITE(10,*) bkgrnd(1:numgrd(1),1:numgrd(2),1:numtmf,saveid)
    CLOSE(10)
  ENDIF

END SUBROUTINE LAPSBKGD

SUBROUTINE LAPSOBSV(m)

!==========================================================
!  This routine reads in LSO observation data from LAPS.
!
!  HISTORY:
! 	Creation: YUANFU XIE	8-2005
!==========================================================

  IMPLICIT NONE

  INTEGER, INTENT(IN) :: m	! Maximum number of sites

  ! Local variables:
  CHARACTER*24 :: tim		! Obs file time
  CHARACTER :: stn(m)*20	! Station names
  CHARACTER :: prd(m)*11	! Provider names
  CHARACTER :: pwx(m)*25	! Present weather
  CHARACTER :: rtp(m)*6		! Report type
  CHARACTER :: stp(m)*6		! Station type (manual/auto)
  CHARACTER :: amt(m,5)*4	! cloud amount

  INTEGER :: nog,nob		! Number obs over grid/box
  INTEGER :: wid		! WMO id
  INTEGER*4 :: otm(m)		! Observation time
  INTEGER*4 :: cld(m)		! Number of cloud layers

  REAL*4 :: lat(m),lon(m), &	! Lat/Lon
	    elv(m)		! Elevation
  REAL*4 :: tmp(m),tmpea(m), &	! Temperature/expected accuracy
	    dew(m),dewea(m), &	! Dewpoint/EA
	    rhd(m),rhdea(m), &	! Relative Humidity/EA
	    wdi(m),wdiea(m), &	! Wind direction/EA
	    spd(m),spdea(m), &	! Wind speed/EA
	    gdi(m),	     &	! Gust wind direction
	    gsp(m),          &	! Gust wind speed
	    alt(m),altea(m), &	! Altimeter/EA
	    spr(m),prsea(m), &	! Station pressure/EA
	    msp(m), &		! Mean sea level pressure/EA
	    pcc(m),pccea(m), &	! 3-hour pressure change character
	    pch(m),pchea(m), &	! 3-hour pressure change
	    vis(m),visea(m), &	! Visibility/EA
	    sol(m),solea(m), &	! Solar/EA
	    slt(m),sltea(m), &	! Soil/water temperature/EA
	    slm(m),slmea(m), &	! Soil moist/EA
	    pc1(m),pcpea(m), &	! 1-hour precipitation/EA
	    pc3(m),pc6(m), &
	    p24(m), &		! 3,6,24-hour precipitation
	    snw(m),snwea(m), &	! Snow depth/EA
	    mxt(m),mnt(m)	! 24-hour maximum/minimum temperature
  REAL*4 :: cht(m,5)		! cloud layer heights
  
  INTEGER :: i,j,k,err,iwv
  INTEGER :: hrs,mns,nit	! Time: hours, minutes and mid-night
  REAL :: xyt(3)		! X, Y and T
  REAL :: prs,ALT_2_SFC_PRESS

  ! Read observation data by LAPS time frames:
  numobs = 0
  DO i=1,numtmf

    ! Frame by frame: READ_SURFACE_DATAQC or READ_SURFACE_DATA
    CALL READ_SURFACE_DATA(i4prev(i),tim,nog,nob, &
	otm,wid,stn,prd,pwx,rtp,stp,lat,lon,elv, &
	tmp,dew,rhd,wdi,spd,gdi,gsp,alt,spr,msp,pcc,pch, &
	vis,sol,slt,slm,pc1,pc3,pc6,p24,snw,cld,mxt,mnt, &
	tmpea,dewea,rhdea,wdiea,spdea,altea,prsea,visea, &
	solea,sltea,slmea,pcpea,snwea,amt,cht,mxstts,err)
    IF (err .NE. 1) THEN
      ! LSO data cannot be read in:
      WRITE(*,21) i
    ELSE
      ! Assign LSO data to the corresponding arrays:

      ! Check if time cross midnight: 0 no cross; 1 cross
      nit = 0
      ! Assume time is not lapsed over 12 hours:
      IF (MAXVAL(otm(1:nob))-MINVAL(otm(1:nob)) &
	.GT. 1200.00) nit = 1

      ! Retrieve location and time sequence:
      DO j=1,nob	! Through all obs sites
	! X and Y:
	CALL LATLON_TO_RLAPSGRID(lat(j),lon(j), &
		latgrd,longrd,numgrd(1),numgrd(2), &
		xyt(1),xyt(2),err)

	! T: from LAPS time form: HHMM to seconds
	hrs = otm(j)/100
	mns = otm(j)-hrs*100

	! If cross midnight, set morning hour to 24+:
	IF ((nit .EQ. 1) .AND. (hrs .LE. 11)) hrs = 24+hrs
	! Cross midnight:
	xyt(3) = hrs*3600+mns*60

	! Pass the location/time to obs arrays:
        DO k=1,numvar
	  rawobs(2:4,j+numobs(k),k) = xyt(1:3)
	ENDDO
      ENDDO

      ! Place the observations into right variables:
      DO j=1,numvar
	SELECT CASE (varnam(j))
	CASE ("TEMP")
	  rawobs(1,1+numobs(j):nob+numobs(j),j) = tmp(1:nob)
	  weight(1+numobs(j):nob+numobs(j),j) = tmpea(1:nob)
	CASE ("DEWP")
	  rawobs(1,1+numobs(j):nob+numobs(j),j) = dew(1:nob)
	  weight(1+numobs(j):nob+numobs(j),j) = dewea(1:nob)
	CASE ("VISB")
	  rawobs(1,1+numobs(j):nob+numobs(j),j) = vis(1:nob)
	  weight(1+numobs(j):nob+numobs(j),j) = visea(1:nob)
        CASE ("CEIL")
	  rawobs(1,1+numobs(j):nob+numobs(j),j) = cht(1:nob,1)
	  weight(1+numobs(j):nob+numobs(j),j) = 1.0
	CASE ("REDP")
	  DO k=1,nob
	    ! Collect either station pressure or altimeter:
	    IF ((spr(k) .NE. mising) .AND. &
		(spr(k) .NE. badsfc)) THEN
	      prs = spr(k)
	    ELSEIF ((alt(k) .NE. mising) .AND. &
		    (alt(k) .NE. badsfc)) THEN
	      prs = ALT_2_SFC_PRESS(alt(k),elv(k))
	    ELSE
	      prs = badsfc
	    ENDIF

	    ! Convert to reduced pressure:
	    IF (prs .NE. badsfc) THEN
	      CALL REDUCE_P(tmp(k),dew(k),prs,elv(k), &
		lapses(1),lapses(2), &
		rawobs(1,numobs(j)+k,j),0.0,badsfc)
	    ELSE
	      rawobs(1,numobs(j)+k,j) = badsfc
            ENDIF
	  ENDDO
	  weight(1+numobs(j):nob+numobs(j),j) = 1.0 ! altea(1:nob)
	CASE ("WNDU")
	  ! Find the index for v component:
	  iwv = 0
	  DO k=1,numvar
	    IF (varnam(k) .EQ. "WNDV") iwv = k
	  ENDDO
	  IF (iwv .EQ. 0) THEN
	    WRITE(*,24)
	  ENDIF
24 FORMAT('STMAS>LAPSOBS: Warning: no v component wind analysis!')

	  ! Convert wind from direction/speed to U/V:
	  DO k=1,nob
	    IF ((wdi(k) .EQ. mising) .OR. &
	        (wdi(k) .EQ. badsfc) .OR. &
	        (spd(k) .EQ. mising) .OR. &
		(spd(k) .EQ. badsfc)) THEN
	      rawobs(1,numobs(j)+k,j) = badsfc
	    ELSE
	      ! Conversion:
	      CALL DISP_TO_UV(wdi(k),spd(k),xyt(1),xyt(2))
	      CALL UVTRUE_TO_UVGRID(xyt(1),xyt(2), &
		rawobs(1,numobs(j)+k,j), &
		rawobs(1,numobs(j)+k,iwv),lon(k))
	    ENDIF
	  ENDDO
	  weight(1+numobs(j):nob+numobs(j),j) = 1.0
	  weight(1+numobs(j):nob+numobs(j),iwv) = 1.0
	CASE ("WNDV")
	  ! V should be in already. See CASE ("WNDU").
	CASE DEFAULT
	  WRITE(*,22) varnam(j)
	END SELECT
      ENDDO
    ENDIF

    ! Update frm:
    numobs(1:numvar) = numobs(1:numvar)+nob
  ENDDO
21 FORMAT('STMAS>LAPSOBS: Cannot read in LSO data: ',i8)
22 FORMAT('STMAS>LAPSOBS: No such var in LSO data: ',A4)

  ! Check number of obs:
  DO i=1,numvar
    IF (verbal .EQ. 1) WRITE(*,23) varnam(i),numobs(i)
  ENDDO
23 FORMAT('STMAS>LAPSOBSV: NumObs of (raw) ',A4,': ',I8)

  ! Remove invalid data:
  CALL RmvInvld

  ! Remove redundant observations:
  ! CALL RmvDupls

  ! Check the data ranges:
  IF (verbal .EQ. 1) THEN
    DO i=1,numvar
      WRITE(*,25) varnam(i), &
        MINVAL(rawobs(4,1:numobs(i),i)), &
        MAXVAL(rawobs(4,1:numobs(i),i)), &
	(MAXVAL(rawobs(4,1:numobs(i),i))- &
	 MINVAL(rawobs(4,1:numobs(i),i)))/3600.00
      WRITE(*,26) varnam(i), &
		  MINVAL(rawobs(1,1:numobs(i),i)), &
		  MAXVAL(rawobs(1,1:numobs(i),i))
    ENDDO
  ENDIF
25 FORMAT('STMAS>LAPSOBSV: ',A4,' obs time interval: ', &
     2F11.2,/,'STMAS>LAPSOBSV: Time length: ',F4.2,' hours')
26 FORMAT('STMAS>LAPSOBSV: ',A4,' min/max values: ', 2F11.2)

  ! Write out requested obs for testing:
  IF (savdat .EQ. 1) THEN
  OPEN(unit=10,file='STMAS_ob1.dat',form='formatted')
    WRITE(10,*) numobs(saveid),numtmf,domain,grdspc(3)
    WRITE(10,*) rawobs(1:4,1:numobs(saveid),saveid)
    CLOSE(10)
  ENDIF

END SUBROUTINE LAPSOBSV

SUBROUTINE RmvInvld

!==========================================================
!  This routine removes the invalid data (missing/badsfc)
!  data from observations.
!
!  HISTORY:
!	Creation: 8-2005 by YUANFU XIE
!==========================================================

  IMPLICIT NONE

  INTEGER :: i,j,num

  ! For every variables:
  DO i=1,numvar

    num = numobs(i)
    numobs(i) = 0
    ! For every obs:
    DO j=1,num
      IF ((rawobs(1,j,i) .NE. mising) .AND. &
	  (rawobs(1,j,i) .NE. badsfc)) THEN
	! Valid data:
	numobs(i) = numobs(i)+1
	rawobs(1:4,numobs(i),i) = rawobs(1:4,j,i)
	weight(numobs(i),i) = weight(j,i)
      ENDIF
    ENDDO
  ENDDO
 
  ! Check numbers of obs left:
  DO i=1,numvar
    IF (verbal .EQ. 1) WRITE(*,31) varnam(i),numobs(i)
  ENDDO
31 FORMAT('STMAS>LAPS_QCs: NumObs of (Vld) ',A4,': ',I8)

END SUBROUTINE RmvInvld

SUBROUTINE RmvDupls

!==========================================================
!  This routine removes the duplicated observations.
!
!  HISTORY:
!	Creation: 9-2005 by YUANFU XIE.
!==========================================================

  IMPLICIT NONE

  INTEGER :: i,j,k,l,nob
  REAL :: dis

  obsspc = 1.0e10
  DO i=1,numvar

    ! Use weight as flag:
    DO j=1,numobs(i)
      DO k=j+1,numobs(i)
	dis = 0.0
	DO l=2,4
	  dis = dis+(rawobs(l,j,i)-rawobs(l,k,i))* &
		    (rawobs(l,j,i)-rawobs(l,k,i))
	ENDDO

	! Mark those redundants:
	IF (dis .LT. epsiln) THEN
	  weight(k,i) = 0.0
	  IF (verbal .EQ. 1) THEN
	    WRITE(*,11) rawobs(1:4,j,i),rawobs(1:4,k,i), &
		varnam(i),j,k
	  ENDIF
	ELSE
	  ! Minimal observation spacing:
          IF ((ABS(rawobs(2,j,i)-rawobs(2,k,i)) .GT. 0.0) .AND. &
              (ABS(rawobs(2,j,i)-rawobs(2,k,i)) .LT. obsspc(1,i))) &
            obsspc(1,i) = ABS(rawobs(2,j,i)-rawobs(2,k,i))
          IF ((ABS(rawobs(3,j,i)-rawobs(3,k,i)) .GT. 0.0) .AND. &
              (ABS(rawobs(3,j,i)-rawobs(3,k,i)) .LT. obsspc(2,i))) &
            obsspc(2,i) = ABS(rawobs(3,j,i)-rawobs(3,k,i))
          IF ((ABS(rawobs(4,j,i)-rawobs(4,k,i)) .GT. 0.0) .AND. &
              (ABS(rawobs(4,j,i)-rawobs(4,k,i)) .LT. obsspc(3,i))) &
            obsspc(3,i) = ABS(rawobs(4,j,i)-rawobs(4,k,i))
	ENDIF
      ENDDO
11 FORMAT('STMAS>RmvDupls: Redundant data: ',/,4F14.4,/, &
	4F14.4,/,A6,2I8)

    ENDDO
    WRITE(*,12) varnam(i),obsspc(1:3,i)
12 FORMAT('STMAS>RmvDupls: Minimal obs (',A4,') spacing: ',3E12.4)

    ! Remove redundants:
    nob = 0
    DO j=1,numobs(i)
      IF (weight(j,i) .GT. 0.0) THEN
        nob = nob+1
        rawobs(1:4,nob,i) = rawobs(1:4,j,i)
	weight(nob,i) = weight(j,i)
      ENDIF
    ENDDO
    numobs(i) = nob

  ENDDO

END SUBROUTINE RmvDupls

SUBROUTINE LAPSUnit

!==========================================================
!  This routine converts LSO observation units into a unit
!  consistent with the background.
!
!  HISTORY:
!	Creation: 8-2005 by YUANFU XIE.
!==========================================================

  IMPLICIT NONE

  INTEGER :: i

  ! Check all variables:
  DO i=1,numvar

    ! Find necessary conversion:
    SELECT CASE (varnam(i))
    CASE ("TEMP")
      ! Convert to Kelvin from Fahrenheit:
      rawobs(1,1:numobs(i),i) = &
	(rawobs(1,1:numobs(i),i)-32.0)*5.0/9.0+temp_0
    CASE ("DEWP")
      ! Convert to Kelvin from Fahrenheit:
      rawobs(1,1:numobs(i),i) = &
	(rawobs(1,1:numobs(i),i)-32.0)*5.0/9.0+temp_0
    CASE ("WNDU")
      ! Convert to m/s from knots:
      rawobs(1,1:numobs(i),i) = &
	rawobs(1,1:numobs(i),i)*knt2ms
    CASE ("WNDV")
      ! Convert to m/s from knots:
      rawobs(1,1:numobs(i),i) = &
	rawobs(1,1:numobs(i),i)*knt2ms
    CASE ("VISB")
      rawobs(1,1:numobs(i),i) = &
	rawobs(1,1:numobs(i),i)*mile2m
    CASE ("REDP")
      ! Convert to pascal from mb:
      rawobs(1,1:numobs(i),i) = &
	rawobs(1,1:numobs(i),i)*mb2pas
    END SELECT
  ENDDO

END SUBROUTINE LAPSUnit

SUBROUTINE LAPS_QCs

!==========================================================
!  This routine runs quality control over data by threshold
!  values and standard deviation.
!
!  HISTORY:
! 	Creation: YUANFU XIE	6-2005
!==========================================================

  IMPLICIT NONE

  ! Interpolation indices and coefficients:
  CALL LAPSIntp

  ! Optional QCs:
  IF (qc_val .EQ. 1) CALL Thrshold

  ! Save QCed obs:
  CALL CpyQCObs

END SUBROUTINE LAPS_QCs

SUBROUTINE CpyQCObs

!==========================================================
!  This routine copies QCed observation data from rawobs to
!  qc_obs after all QC is done. This routine can be avoid
!  if the qc_obs array keeps the same structure as rawobs.
!
!  HISTORY:
!	Creation: 8-2005 by YUANFU XIE.
!==========================================================

  IMPLICIT NONE

  INTEGER :: i,j

  ! Copy:
  DO i=1,numvar
    DO j=1,numobs(i)
      qc_obs(1:4,j,i) = rawobs(1:4,j,i)

      ! Save innovations:
      IF (needbk(i) .EQ. 1) &
        qc_obs(1,j,i) = qc_obs(1,j,i)-bkgobs(j,i)

    ENDDO
  ENDDO

END SUBROUTINE CpyQCObs

SUBROUTINE Thrshold

!==========================================================
!  This routine does the threshold value QC checks.
!
!  HISTORY:
!	Creation: 8-2005 by YUANFU XIE.
!==========================================================

  IMPLICIT NONE

  INTEGER :: i,j,num

  ! Check:
  DO i=1,numvar
    IF (needbk(i) .EQ. 1) THEN
      num = numobs(i)
      numobs(i) = 0
      DO j=1,num

        ! QC check: avoid bkg = mising with roundoff error:
        IF (ABS(rawobs(1,j,i)-bkgobs(j,i)) .LE. thresh(i)) THEN
	  numobs(i) = numobs(i)+1
	  rawobs(1:4,numobs(i),i) = rawobs(1:4,j,i)
	  weight(numobs(i),i) = weight(j,i)
	  indice(1:6,numobs(i),i) = indice(1:6,j,i)
	  coeffs(1:6,numobs(i),i) = coeffs(1:6,j,i)
	  bkgobs(numobs(i),i) = bkgobs(j,i)
        ENDIF
      ENDDO
    ENDIF
  ENDDO
 
  ! Check numbers of obs left:
  DO i=1,numvar
    IF (verbal .EQ. 1) WRITE(*,31) varnam(i),numobs(i)
  ENDDO
31 FORMAT('STMAS>LAPS_QCs: NumObs of (Vlu) ',A4,': ',I8)

END SUBROUTINE Thrshold

SUBROUTINE LAPSIntp

!==========================================================
!  This routine interpolates gridpoints to observation site
!  and saves the indices and coefficients.
!
!  HISTORY:
!	Creation: 9-2005 by YUANFU XIE.
!==========================================================

  IMPLICIT NONE

  INTEGER :: i,j,ix,iy,it

  DO i=1,numvar
    CALL Grid2Obs(indice(1,1,i),coeffs(1,1,i), &
	rawobs(1,1,i),numobs(i),weight(1,i),numgrd, &
	grdspc,domain)

    ! Compute background values at observation sites:
    DO j=1,numobs(i)

      ! Interpolate background to the obs site:
      bkgobs(j,i) = 0.0
      DO it=3,6,3
        DO iy=2,5,3
          DO ix=1,4,3
            bkgobs(j,i) = bkgobs(j,i) + &
	      bkgrnd(indice(ix,j,i), &
		     indice(iy,j,i), &
		     indice(it,j,i),i)* &
	      coeffs(ix,j,i)*coeffs(iy,j,i)*coeffs(it,j,i)
          ENDDO
        ENDDO
      ENDDO
    ENDDO

  ENDDO

END SUBROUTINE LAPSIntp

END MODULE LAPSDatSrc
