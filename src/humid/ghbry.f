cdis   
cdis    Open Source License/Disclaimer, Forecast Systems Laboratory
cdis    NOAA/OAR/FSL, 325 Broadway Boulder, CO 80305
cdis    
cdis    This software is distributed under the Open Source Definition,
cdis    which may be found at http://www.opensource.org/osd.html.
cdis    
cdis    In particular, redistribution and use in source and binary forms,
cdis    with or without modification, are permitted provided that the
cdis    following conditions are met:
cdis    
cdis    - Redistributions of source code must retain this notice, this
cdis    list of conditions and the following disclaimer.
cdis    
cdis    - Redistributions in binary form must provide access to this
cdis    notice, this list of conditions and the following disclaimer, and
cdis    the underlying source code.
cdis    
cdis    - All modifications to this software must be clearly documented,
cdis    and are solely the responsibility of the agent making the
cdis    modifications.
cdis    
cdis    - If significant modifications or enhancements are made to this
cdis    software, the FSL Software Policy Manager
cdis    (softwaremgr@fsl.noaa.gov) should be notified.
cdis    
cdis    THIS SOFTWARE AND ITS DOCUMENTATION ARE IN THE PUBLIC DOMAIN
cdis    AND ARE FURNISHED "AS IS."  THE AUTHORS, THE UNITED STATES
cdis    GOVERNMENT, ITS INSTRUMENTALITIES, OFFICERS, EMPLOYEES, AND
cdis    AGENTS MAKE NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE USEFULNESS
cdis    OF THE SOFTWARE AND DOCUMENTATION FOR ANY PURPOSE.  THEY ASSUME
cdis    NO RESPONSIBILITY (1) FOR THE USE OF THE SOFTWARE AND
cdis    DOCUMENTATION; OR (2) TO PROVIDE TECHNICAL SUPPORT TO USERS.
cdis   
cdis cdis
cdis
cdis
cdis
cdis
cdis
cdis
cdis
cdis
cdis
      subroutine ghbry (i4time,p_3d,pb,lt1dat,htby,
     1     ii,jj,kk,istatus)
    
c     routine to return boundary layer top in pressure units
     
      implicit none

c     input parameters
      
      integer i4time
      integer ii,jj,kk,istatus
      real p_3d (ii,jj,kk)
      real pb (ii,jj)           ! surface station pressure
      real lt1dat(ii,jj,kk)
      real htby (ii,jj)
      
c     dynamic allocation 
      
      real n2(ii,jj,kk)         ! brunt-vaisala frequency
      
c     internal variables

      integer i,j,k
      real x1,x2,y1,y2          ! brackets for zero brunt-vaisala freq. interp
      real g                    ! gravity
      real r                    ! gas constant of dry air
      real kkk                  ! (r/cp) where cp is the specific heat

      save g,r,kkk              ! inserted save to be safe, probably not needed

      data g / 980.665/         !  cm/s**2  (cgs units)
      data r / 2.8704e6/        !  erg/g/k  (cgs units)
      data kkk / 0.2857/        ! (dimensionless)

c     note: in the computation of n2 the units of pressure cancel since
c     the pressure occurs both in the numerator and denominator....therefore
c     mb are sufficient units for pressure and the relationship
c     1  mb = 1000 cgs units does not have to be applied.
      
c     ------------begin exe last revised 10/26/99 db
      
      do j = 1,jj
         do i = 1,ii
            
            htby(i,j) = pb(i,j) !put surface pressure in as first guess of
c     boundary level top
            
         enddo
      enddo

c     section is for better boundary layer analysis
      
      do j = 1,jj
         do i = 1,ii
            do k = 2,kk-1  !note that n2(,,k) end points are not filled.
               
               n2(i,j,k) = (g/lt1dat(i,j,k) )**2 * (p_3d(i,j,k)/r) *
     1              (
     1              kkk*lt1dat(i,j,k)/p_3d(i,j,k)
     1              -  ( lt1dat(i,j,k+1)-lt1dat(i,j,k-1) )
     1              / ( p_3d(i,j,k+1) - p_3d(i,j,k-1) )
     1              )
               
               
            enddo               ! k
         enddo
      enddo
 
c     now decide where the "height of the boundary layer" is

      do j = 1,jj
         do i = 1,ii

            y2 = 2.             ! number greater than zero for test below

c     search upward for n2(k+1) being negative, then interpolate there

            do k = 2,kk-2       ! avoid using n2(,,k) endpoints, (not filled)
                  x1 = p_3d(i,j,k)
                  y1 = n2(i,j,k)

               if (pb(i,j) .ge. p_3d(i,j,k+1) 
     1              .and. n2(i,j,k+1) .lt. 0.0) then

                  x2 = p_3d(i,j,k+1)
                  y2 = n2(i,j,k+1) 
c     bail out of loop here to not affect regions above 1st inversion
                  go to 111

               endif
               
            enddo
c     divert code here to not fall into section 111
            go to 112
 111        continue
            
            if (y2.lt.0.0)   then !actually found negative level
c     this test prevents going to the top of the column w/o inversion
c     should never happen, but this is safeguard.

c     sun machines seem to have a problem when y2 and y1 are very close.
c     to avoid this situation, such close numbers indicate that the 
c     top of the boundary is very close to x1 so we assign this
c     here,  if the difference is large enough, then we use the interp
c     routine.

c               write (6,*) 'TEMPP ', abs(y2-y1)

               if (abs(y2-y1) .le. 1.e-6) then
                  htby(i,j) = x1
               else
               
c     interpolate in height space
                  call interp( 0.,y1,y2,log(x1),log(x2),htby(i,j) )
                  htby(i,j) = exp(htby(i,j))

c     double safeguard on making sure htby is not below ground level.
                  htby(i,j) = min (htby(i,j),pb(i,j))
               endif

c     check for runaway adjustment, assign to base value
               if (htby(i,j).lt.pb(i,j)-400. ) then ! regard as too high
                  write (6,*) 'i,j,htby(i,j), gt 400mb depth, adjust',
     1                 ' to surface pressure - 400 mb', i,j,htby(i,j)
                  htby(i,j) = pb(i,j)-400.
               endif

            endif
               
 112        continue
            
         enddo
         
      enddo
      
c     write out the pbl pressure top

      call check_nan2 (htby,ii,jj,istatus)
      if(istatus.ne.1) then
         write(6,*) 'NaN values in var:htby routine:ghbry.f'
         return
      endif
      
      call gen_bl_file (i4time,htby,ii,jj,istatus)
      
      if (istatus.eq.0) print*, 'Error in gen_bl_file routine'
      
      return
      end
