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
cdis
cdis
cdis
cdis
cdis
cdis
cdis
cdis
cdis
cdis
      real function func (x)

c     This module now includes more than just satllite data.  It is the 
c     minimization area for sounder radiance, GVAP, GPS, and cloud.

c   This routine interfaces GOES 8/10 satellite broadcast network data (and
c   local GVAR data) to the LAPS moisture analysis.  In 1999, this routine
c   was modified from an earlier version that used the University of
c   Wisconsin -- Madison's forward model to a new model developed at
c   NESDIS.  OPTRAN (optical transmittance) forward model was developed by
c   Thomas Kleespies (NESDIS) and questions about this model should be
c   directed to him.  Forecast Systems Laboratory does not in any way
c   guarantee the validity of OPTRAN and distributes this software on an
c   as-is basis.  MOREOVER, FSL HAS PERMISSION TO DISTRIBUTE OPTRAN AS PART
c   OF LAPS TO FEDERAL AGENCIES.  NON-FEDERAL ENTITIES NEED TO INQUIRE WITH
c   NESDIS TO ESTABLISH THEIR RIGHTS AND OBLIGATIONS WITH REGARD TO OPTRAN.
c   
c   The version of OPTRAN with which this software is used, has been
c   modified by FSL to include both sounder and imager channels for a
c   particular satellite in one call to the routine.  Thus a user only need
c   to setup OPTRAN for a particular satellite.  After doing such, either
c   the imager or sounding instrument can be used with the software without
c   further recompilation.

      implicit none
      save
      include 'Constants.inc'
      
c     parameter variables
      
      real x(3)
      
c     optran specific arrays for powell function calling
      
      real radiance_ob (Nchan)
      integer cost_kk
      real cost_p(Nlevel)
      real cost_t_l(Nlevel)
      real cost_mr_l(Nlevel)
      real cost_tskin
      real cost_psfc
      integer cost_julian_day
      real cost_lat
      real cost_theta
      integer cost_isnd
      integer cost_rad_istatus

c     optran common 

      common /cost_optran/radiance_ob, cost_kk, cost_p, cost_t_l,
     1     cost_mr_l, cost_tskin, cost_psfc, cost_julian_day, cost_lat,
     1     cost_theta, cost_isnd, cost_rad_istatus

c     gvap common

      common /cost_gvap/cost_w1,cost_w2,cost_w3,cost_gvap_p,cost_weight,
     1     cost_gvap_istatus,cost_data,cost_kstart,cost_qs,
     1     cost_ps, cost_p1d, cost_mdf
      real cost_w1,cost_w2,cost_w3,cost_gvap_p,cost_weight
      integer cost_gvap_istatus
      real cost_data(500)
      integer cost_kstart
      real cost_qs
      real cost_ps
      real cost_p1d(500)
      real cost_mdf

c     cloud common

      common /cost_cloud/cost_cloud,cost_cld,cost_cloud_istatus,cost_sat
      integer cost_cloud_istatus
      real cost_cloud(500)
      real cost_cld
      real cost_sat(500)
      real cloud_temp           ! temp used in subroutine call

c     gps common

      common /cost_gps/cost_gps_data, cost_gps_weight,cost_gps_istatus
      integer cost_gps_istatus
      real cost_gps_data
      real cost_gps_weight
      

c     local analogs to common block variables for input to parameters

      integer kk
      real p(Nlevel)
      real t_l(Nlevel)
      real mr_l(Nlevel)
      real tskin
      real psfc
      integer julian_day
      real lat
      real theta
      real lpw1,lpw2,lpw3

c     local monitor variables

      real max_func_rad
      real max_func_back
      real max_func_gvap1
      real max_func_gvap2
      real max_func_gvap3
      real max_func_cloud
      real max_func_gps

c     lcal variables

      integer i,j,k
      integer kan(18)
      real w(Nlevel)
      real tbest(nchan)
      logical first_time,first_gvap
      save first_time, first_gvap
      data first_time /.true./
      data first_gvap /.true./
      integer lvl500, lvl700, lvl100
      save lvl500, lvl700, lvl100
      real var_weights(7)       ! weights computing in func
      real p1,p2,p3             !pressure tops for gvap layers
      real GT,G  ! cloud functions
      real ipw                  !integrated water for GPS minimization
      
c     externals
      
      real plango
      
c     code

c     simulate current variational code... remove when new cloud
c     routine is implemented this just tests good cloud i/o read
c     it has nothing to do with clouds at this current location

c      if(cost_cloud_istatus.ne.1 .or. cost_cld .ne. 0.0) then ! cloud 
c         func = 0.0
c         return                 ! ignore function 
c      endif

      func = 0.0                ! Default is start at minima
      max_func_rad = 0.0

c     define G parameter

      GT = 1.0

      G = 1.0


c     constrain x to positive
      do i =1,3
         x(i) = abs(x(i))
      enddo
      
      if (first_time) then
         first_time  = .false.

c     set up for sounder if needed instead of imager
         
         if (cost_isnd.eq.1) then ! sounder radiances used
            
            kan(1) = 10         ! 7.4 like ch3
            kan(2) = 8          ! 11.02 like ch4
            kan(3) = 7          ! 12.02 like ch5
            kan(4) = 11
            kan(5) = 16
            kan(6) = 6
            kan(7) = 12
           
            var_weights(1) = .0022
            var_weights(2) = 0.
            var_weights(3) = 0.
            var_weights(4) = .0034
            var_weights(5) = 0.
            var_weights(6) = 0.
            var_weights(7) = 0.0036
            
         else                   ! imager radiances used

            var_weights(1) = .0022
            var_weights(2) = 0.
            var_weights(3) = 0.
            
         endif
         
c     determine layer levels 
         
         do i = cost_kk,1, -1
            if (cost_p(i) .le. 100.) lvl100=i
            if (cost_p(i) .le. 700.) lvl700=i
            if (cost_p(i) .le. 500.) lvl500=i
         enddo
         
      endif                     ! first_time
      
c     fill local variables from common block for parameter list in ofm

      if (cost_rad_istatus .eq. 1) then
      
         do i = 1, nlevel
            p(i) = cost_p(i)
            t_l(i) = cost_t_l(i)
            mr_l(i) = cost_mr_l(i)
         enddo
         kk = cost_kk
         tskin = cost_tskin
         psfc = cost_psfc
         julian_day = cost_julian_day
         lat = cost_lat
         theta = cost_theta
         
c     modify mixing ratio per predifined pressure layers.
         
         do i = 1,cost_kk
            
            if(i.lt. lvl700) then ! sfc to 780
               mr_l(i) = abs(x(1)) * cost_mr_l(i)
            elseif (i.ge.lvl700 .and. i.le. lvl500) then ! 700 to 500
               mr_l(i) = abs(x(2)) * cost_mr_l(i)
            elseif (i.gt.lvl500 .and. i.le. lvl100) then ! between 475 and 100
               
c     the corresponding change must also be made in variational.f where
c     this information is applied.

               mr_l(i) = abs(x(3))*cost_mr_l(i)
c     1              ((abs(x(3))-1.)*(p(i)/500.) + 1.) *
c     1              cost_mr_l(i)
            else
               mr_l(i) =  cost_mr_l(i)
            endif
            
         enddo
         
c     perform forward model computation for radiance
c     here is the main call to optran in this whole module, the real
c     time-consuming part of the code.
         
         call ofm ( kk, p, t_l, 
     1        mr_l, tskin, psfc,
     1        julian_day, lat, theta, tbest) 
         
c     compute cost function

         if (cost_isnd.eq.1) then ! SOUNDER radiances used
            if(cost_isnd.eq.1 .and. cost_cld.GT. 0.75) then ! report conflict
               GT = 0.25 ! reduce influence of this term by 3/4 due to 
c     conflict with cloud analysis
            endif
            
            do j = 1,7          ! radiance _ob(1-7) is sounder btemp
               func = func + var_weights(j)*( radiance_ob(j) -
     1              tbest(j) )**2/2.
            enddo

         else                   ! IMAGER situation (only 3 channels)
            
            do j = 1,3          ! radiance _ob(1-3) is imager btemp
               func = func + var_weights(j)*( radiance_ob(j) -
     1              tbest(j+7) )**2/2.
            enddo
            
         endif

         func = func * GT ! importance reduced by cloud influence

         max_func_rad = func
            
         
c     stability cost is identical for both imager and sounder
         
      endif                     ! cost_rad_istatus

c     background weighting, in effect even if radiance data are not present.
      max_func_back = 0.0
      do j = 1,3
c         func = func +   ((x(j) - 1.)**2 )
         max_func_back =   ((x(j) - 1.)**2) + max_func_back
      enddo

      func = func + max_func_back
c      write(6,*) 'func 1, ',func
      
c     GVAP section



      if (cost_gvap_istatus .eq. 1) then

         if (cost_cld.GT.0.25) then
            G = 0.25            !reduction factor
         else
            G = 1.0
         endif

c     test for weight of measurement
         if(cost_weight.eq.cost_mdf) then !skip this step
            continue ! skip this iteration
         else                   ! process gvap
            if (first_gvap) then
               first_gvap = .false.
               write(6,*) 'TEMP GVAP accepted'
            endif

c     integrate q for gvap layers
c     determine sigma level pressure analogs

            call sigma_to_p (0.1, cost_ps, 0.9, p1)
            call sigma_to_p (0.1, cost_ps, 0.7, p2)
            call sigma_to_p (0.1, cost_ps, 0.3, p3)
            call int_layerpw(x,cost_data,cost_kstart,
     1           cost_qs,cost_ps,cost_p1d,p1,p2,p3,lpw1,lpw2,lpw3,
     1           cost_kk,cost_mdf)

            if (p1 .le. 300.0) then
               write(6,*)'TEMM ', x, p1,p2,p3,lpw1,lpw2,lpw3,
     1              cost_w1,cost_w2,cost_w3
            endif

            if (lpw2.eq.cost_mdf) then
               i = i
            endif

            
c     minimize with respect to layer gvap data

            max_func_gvap1 = 0.0
            max_func_gvap2 = 0.0
            max_func_gvap3 = 0.0
          
            if (lpw1.ne.cost_mdf) then
               max_func_gvap1 =  
     1              (lpw1-cost_w1)**2*cost_weight
            endif
            if (lpw2.ne.cost_mdf) then
               max_func_gvap2 =
     1              (lpw2-cost_w2)**2*cost_weight
            endif
            if (lpw3.ne.cost_mdf) then
               max_func_gvap3 =  
     1              (lpw3-cost_w3)**2*cost_weight
            endif

c     note that gvap data are in mm and other func computations are in
c     cm units.  therefore each weight must be converted unitwise
c     (divided by 100 since they are a factor of 10**2) higher in the 
c     numerator of the J function.

            func = func + (max_func_gvap1/100.+max_func_gvap2/100.
     1           +max_func_gvap3/100.)
c            write(6,*) 'func 2 ',func

c     generate modfied cost function based on these layers

         endif                  !weight function test
      endif                     !data present test

c     minimize with respect to partly cloudy data

      if (cost_cloud_istatus.eq.1) then ! cloud data present
         max_func_cloud = 0.0
         do k = 1,cost_kk
            if (cost_data(k).ne.cost_mdf) then
               if(cost_data(k).ge.0.0) then
                  cloud_temp = cost_data(k)
                  call cloud_sat (cost_cloud(k),cost_sat(k),cloud_temp)
               
                  if(k .lt. lvl700 ) then ! sfc to 700
                     max_func_cloud = max_func_cloud + 
     1                    (cost_data(k)*x(1) - cloud_temp)**2 
                  elseif (k .lt. lvl500) then ! 700-500
                     max_func_cloud = max_func_cloud + 
     1                    (cost_data(k)*x(2) - cloud_temp)**2
                  elseif (k .lt. lvl100) then ! 500-100
                     max_func_cloud = max_func_cloud + 
     1                    (cost_data(k)*x(3) - cloud_temp)**2  
                  endif         ! level test
               endif            ! negative check
            endif               ! mdf check
         enddo                  ! enddo k level
      endif                     ! cloud data present

      func = func + max_func_cloud

c     GPS section

      if (cost_gps_istatus .eq. 1) then

      call int_ipw (x,cost_p1d,cost_data,ipw,cost_mdf,cost_kk)

      max_func_gps = 0.0

      max_func_gps = (cost_gps_data-ipw)**2*cost_gps_weight
c      write(6,*) 'TEMPM max_func_gps,',max_func_gps
      else
c         write(6,*) 'NO GPS in func'
      endif

      func = func + max_func_gps

c     print test output

c      write (6,*) 'TEMP, ', x,
c     1     max_func_back/func,
c     1     max_func_rad/func,
c     1     max_func_gvap1/100./func,
c     1     max_func_gvap2/100./func,
c     1     max_func_gvap3/100./func,
c     1     max_func_cloud/func,
c     1     max_func_gps/func,func

      return
      end
