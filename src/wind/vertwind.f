cdis    Forecast Systems Laboratory
cdis    NOAA/OAR/ERL/FSL
cdis    325 Broadway
cdis    Boulder, CO     80303
cdis 
cdis    Forecast Research Division
cdis    Local Analysis and Prediction Branch
cdis    LAPS 
cdis 
cdis    This software and its documentation are in the public domain and 
cdis    are furnished "as is."  The United States government, its 
cdis    instrumentalities, officers, employees, and agents make no 
cdis    warranty, express or implied, as to the usefulness of the software 
cdis    and documentation for any purpose.  They assume no responsibility 
cdis    (1) for the use of the software and documentation; or (2) to provide
cdis     technical support to users.
cdis    
cdis    Permission to use, copy, modify, and distribute this software is
cdis    hereby granted, provided that the entire disclaimer notice appears
cdis    in all copies.  All modifications to this software must be clearly
cdis    documented, and are solely the responsibility of the agent making 
cdis    the modifications.  If significant modifications or enhancements 
cdis    are made to this software, the FSL Software Policy Manager  
cdis    (softwaremgr@fsl.noaa.gov) should be notified.
cdis 
cdis 
cdis 
cdis 
cdis 
cdis 
cdis 

        subroutine vert_wind(uanl,vanl,u_sfc,v_sfc,ni,nj,nk,wanl
     1          ,topo,lat,lon,grid_spacing_m,istatus
     1          ,r_missing_data
     1          ,laps_rotate_winds)

!      ~1990        Steve Albers  Orig version
!       1997 Jun    Ken Dritz     Added ni and nj as dummy
!                                 arguments, thus making wsum and one and
!                                 several other arrays automatic.
!       1997 Jun    Ken Dritz     Initialize wsum and one dynamically, instead
!                                 of by DATA statements.
!       1997 Jun    Ken Dritz     Added r_missing_data as dummy argument.
!       1997 Jun    Ken Dritz     Removed include of 'lapsparms.for'.
!       1997 Oct    Steve Albers  Pass lon to fflxc. Misc Cleanup.
!       1997 Dec    Steve Albers  Changed NX_L_MAX/NY_L_MAX to ni/nj
!       1998 Nov    Steve Albers  Change to M, hopefully cancels out change to
!                                 fflxc/sigma

        include 'trigd.inc'
        real m ! Grid points per meter

        real*4 wsum(ni,nj)
        real*4  one(ni,nj)

        logical laps_rotate_winds

        integer k_terrain(ni,nj)

        DATA scale/1./

        real*4 uanl(ni,nj,nk),vanl(ni,nj,nk)
        real*4 wanl(ni,nj,nk) ! omega (pascals/second)
        real*4 terrain_w(ni,nj),conv(ni,nj)
        real*4 u_sfc(ni,nj),v_sfc(ni,nj)
        real*4 topo_pa(ni,nj)

        real*4 lat(ni,nj)
        real*4 lon(ni,nj)
        real*4 topo(ni,nj)

        real*4 flu(ni,nj)
        real*4 flv(ni,nj)
        real*4 sigma(ni,nj)

        real*4 u_sfc_grid(ni,nj),
     1         v_sfc_grid(ni,nj)
        real*4 beta_factor(ni,nj)

        real*4 radius_earth
        parameter (radius_earth = 6371e3)

        character*6 c6_maproj

        do i=1,ni
           do j=1,nj
              wsum(i,j) = 0.0
              one(i,j) = 1.0
           enddo
        enddo

        ierrcnt = 0
        istatus = 1

!       grid_spacing_m = sqrt(
!       1                      (  lat(1,2) - lat(1,1)                  )**2
!       1                    + ( (lon(1,2) - lon(1,1))*cosd(lat(1,1))  )**2
!       1                                       )    * 111317. ! Grid spacing m

        call get_standard_latitudes(slat1,slat2,istatus)
        if(istatus .ne. 1)then
            return
        endif

        call get_c6_maproj(c6_maproj,istatus)
        if(istatus .ne. 1)then
            return
        endif

        if(c6_maproj .eq. 'plrstr')then
            call get_ps_parms(slat1,slat2,grid_spacing_m,phi0
     1                                 ,grid_spacing_proj_m)
        else
            grid_spacing_proj_m = grid_spacing_m
        endif

        write(6,*)' Grid spacings (m) = ',grid_spacing_m
     1                                   ,grid_spacing_proj_m

        m = 1.0 / grid_spacing_proj_m

        imaxm1 = ni - 1
        jmaxm1 = nj - 1

!       Calculate surface pressure array
        do j=1,nj
        do i=1,ni
            topo_pa(i,j) = ztopsa(topo(i,j)) * 100.
        enddo
        enddo

!       Rotate Sfc Winds
        if(.not. laps_rotate_winds)then
          write(6,*)' Rotating SFC winds to calculate terrain forcing'
          write(6,*)' Calculating Beta Factor'
          do j=1,nj
          do i=1,ni
            if(u_sfc(i,j) .ne. r_missing_data
     1                   .and. v_sfc(i,j) .ne. r_missing_data)then

                call uvtrue_to_uvgrid(u_sfc(i,j),
     1                              v_sfc(i,j),
     1                              u_sfc_grid(i,j),
     1                              v_sfc_grid(i,j),
     1                              lon(i,j))

            endif

            beta_factor(i,j) = sind(lat(i,j)) / radius_earth

          enddo
          enddo

        else ! Winds are already rotated
          do j=1,nj
          do i=1,ni
              u_sfc_grid(i,j) = u_sfc(i,j)
              v_sfc_grid(i,j) = v_sfc(i,j)
              beta_factor(i,j) = 0.
          enddo
          enddo

        endif

!       Calculate terrain induced omega
        do j=2,jmaxm1
        do i=2,imaxm1

!           Units of dterdx are pascals/meter
            dterdx=(topo_pa(i+1,j) - topo_pa(i-1,j)) * .5/grid_spacing_m       
            dterdy=(topo_pa(i,j+1) - topo_pa(i,j-1)) * .5/grid_spacing_m

!           Units of ubar,vbar are m/s
            ubar=(u_sfc_grid(i-1,j-1) + u_sfc_grid(i,j-1)) *.5
            vbar=(v_sfc_grid(i-1,j-1) + v_sfc_grid(i-1,j)) *.5

!           Units of terrain_w are pascals/second
            terrain_w(i,j) = UBAR*DTERDX+VBAR*DTERDY

        enddo ! i
        enddo ! j

!       Fill in edges
        do i = 1,ni
            terrain_w(i,   1) = terrain_w(i,     2)
            terrain_w(i,nj)   = terrain_w(i,jmaxm1)
        enddo ! i

        do j = 1,nj
            terrain_w(1,   j) = terrain_w(2,     j)
            terrain_w(ni,j)   = terrain_w(imaxm1,j)
        enddo ! j

        do j = 1,nj
        do i = 1,ni
            k_terrain(i,j) = 
     1          max(nint(height_to_zcoord(topo(i,j),istatus)),1)

            if(istatus .ne. 1)then
                write(6,*)' Error: Bad istatus returned from '
     1                   ,'height_to_zcoord',i,j,topo(i,j)
                return
            endif

        enddo ! i
        enddo ! j


        write(6,*)'            terrain       conv       omega      beta 
     1corr'

        do k = 1,nk
            call FFLXC(ni,nj,M,SCALE
     1                ,uanl(1,1,k),vanl(1,1,k),one,conv,lat,lon
     1                ,flu,flv,sigma,r_missing_data)

            if(k.gt.1)z_interval
     1              = abs(zcoord_of_level(k) - zcoord_of_level(k-1))        

            do j = 1,nj
            do i = 1,ni

                k_terr = k_terrain(i,j)

                if(k .lt. k_terr)then !
                    wanl(i,j,k) = r_missing_data

                elseif(k .eq. k_terr)then !
                    wsum(i,j)   = terrain_w(i,j)
     1       - (conv(i,j) + vanl(i,j,k) * beta_factor(i,j)) * z_interval
                    wanl(i,j,k) = wsum(i,j)


                else ! k .gt. k_terr
                    wsum(i,j)   = wsum(i,j)
     1       - (conv(i,j) + vanl(i,j,k) * beta_factor(i,j)) * z_interval       
                    wanl(i,j,k) = wsum(i,j)

                endif

                if(abs(conv(i,j)) .gt. 1.0)then
                    ierrcnt = ierrcnt + 1
                    if(ierrcnt .lt. 20)then
                        write(6,*)' Error: Large Convergence'
     1                          ,i,j,k,k_terrain(i,j),conv(i,j)
                    endif

                    istatus = 0
                endif

                if(j .eq. 29 .and. k .le. 7 .and. i .eq. 29)then
                    write(6,111)i,j,k,terrain_w(i,j)
     1              ,conv(i,j),wanl(i,j,k),beta_factor(i,j)*vanl(i,j,k)       
111                 format(3i3,4e12.3)
                endif


            enddo ! i
            enddo ! j

        enddo ! k

        return
        end
