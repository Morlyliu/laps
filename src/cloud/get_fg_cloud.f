
        subroutine get_modelfg(cf_modelfg,t_modelfg                      ! O
     1                        ,default_clear_cover                       ! I
     1                        ,temp_3d,heights_3d,cld_hts                ! I
     1                        ,i4time_needed,ilaps_cycle_time            ! I
     1                        ,ni,nj,klaps,KCLOUD                        ! I
     1                        ,istatus)                                  ! O

!       Obtain model first guess cloud cover and temperature fields
!       This should probably be free of very small scale horizontal structures
!       for best results when combining with the satellite data

!                Steve Albers   Use model first guess info to guess cloud cover
!       1994     Steve Albers   Read in SH from model background (instead of
!                                                                         RH)
!       1995 Dec Steve Albers   QC check to prevent cf_modelfg > 1.0
!       1999     Steve Albers   Added in LWC/ICE model first guess
!                               Simple usage for the moment.

        real*4 heights_3d(ni,nj,klaps)       ! Input
        real*4 temp_3d(ni,nj,klaps)          ! Input
        real*4 cf_modelfg(ni,nj,KCLOUD)      ! Output
        real*4 t_modelfg(ni,nj,KCLOUD)       ! Output
        real*4 cld_hts(KCLOUD)               ! Input

        real*4 model_q_3d(ni,nj,klaps)       ! Local

        real*4 model_lwc_3d(ni,nj,klaps)     ! Local
        real*4 model_ice_3d(ni,nj,klaps)     ! Local

        real*4 make_rh,lwc_modelfg,ice_modelfg

        character*31 ext
        character*3 var_2d

        write(6,*)
        write(6,*)' Getting first guess cloud cover'

!       Initialize model first guess cover field with default value
        do k = 1,KCLOUD
        do j = 1,nj
        do i = 1,ni
            cf_modelfg(i,j,k) = default_clear_cover
            t_modelfg(i,j,k) = 0.
        enddo
        enddo
        enddo

        i_hum_high = 0
        i_hum_low = 0
        i_hum_ok = 0

        i_condensate = 0

        istat_sh  = 0
        istat_lwc = 0
        istat_ice = 0

        write(6,*)' Getting MODEL LWC background'

!       Get Model First Guess LWC
        var_2d = 'LWC'
        call get_modelfg_3d(i4time_needed,var_2d,ni,nj,klaps
     1                     ,model_lwc_3d,istat_lwc)

        if(istat_lwc .ne. 1)then
            write(6,*)' No first guess available for ',var_2d
        endif

        write(6,*)' Getting MODEL ICE background'

!       Get Model First Guess ICE
        var_2d = 'ICE'
        call get_modelfg_3d(i4time_needed,var_2d,ni,nj,klaps
     1                     ,model_ice_3d,istat_ice)

        if(istat_ice .ne. 1)then
            write(6,*)' No first guess available for ',var_2d
        endif

!       Get Model First Guess SH
        if(istat_lwc .ne. 1 .or. istat_ice .ne. 1)then
            write(6,*)' Getting MODEL SH background'

!           Get Model First Guess SH
            var_2d = 'SH'
            call get_modelfg_3d(i4time_needed,var_2d,ni,nj,klaps
     1                         ,model_q_3d,istat_sh)

            if(istat_sh .ne. 1)then
                write(6,*)' No first guess available for ',var_2d
                return
            endif

        endif ! Good status for MODEL data


!       Remap to cloud height grid and convert to cloud cover
        t_ref = 0.

        do k = 1,KCLOUD
        do j = 1,nj
        do i = 1,ni

!           Find the model pressure at this location in the cloud height grid
            if(i-1 .eq. (i-1)/10*10)then ! Update every 10th grid point
                z_laps = height_to_zcoord2(cld_hts(k),heights_3d
     1                  ,ni,nj,klaps,i,j,istatus)
                if(istatus .ne. 1)then
!                   Determine if cloud height grid is above pressure grid
                    if(cld_hts(k) .gt. heights_3d(i,j,klaps))then
                        i_grid_high = i_grid_high + 1
                        cf_modelfg(i,j,k) = default_clear_cover
                        go to 1000
                    else
                        write(6,*)' Error: Bad status from '
     1                           ,'height_to_zcoord2'
                        return
                    endif
                endif

                z_laps = max(1.,min(z_laps,float(klaps)-.001))
                iz_laps = int(z_laps)
                frac = z_laps - iz_laps

                p_modelfg =  pressure_of_level(iz_laps) * (1. - frac)
     1                    +  pressure_of_level(iz_laps+1)  * frac

                p_modelfg_mb = p_modelfg * .01

            endif

!           Find the model temp at this location in the cloud height grid
            t_modelfg(i,j,k) =  temp_3d(i,j,iz_laps)    * (1. - frac)
     1                       +  temp_3d(i,j,iz_laps+1)  * frac

            t_modelfg_c = t_modelfg(i,j,k) - 273.15


            if(istat_lwc .eq. 1 .and. istat_lwc .eq. 1)then
                lwc_modelfg =  model_lwc_3d(i,j,iz_laps)   * (1. - frac)
     1                      +  model_lwc_3d(i,j,iz_laps+1)       * frac

                ice_modelfg =  model_ice_3d(i,j,iz_laps)   * (1. - frac)
     1                      +  model_ice_3d(i,j,iz_laps+1)       * frac

                condensate_fg = lwc_modelfg + ice_modelfg
                if(condensate_fg .gt. 0.)then
                    cf_modelfg(i,j,k) = 1.
                    i_condensate = i_condensate + 1
                else
                    cf_modelfg(i,j,k) = default_clear_cover
                endif

            elseif(istat_sh .eq. 1)then
!               Find the model sh at this location in the cloud height grid
                q_modelfg =  model_q_3d(i,j,iz_laps)    * (1. - frac)       
     1                    +  model_q_3d(i,j,iz_laps+1)  * frac

                q_modelfg_gkg = q_modelfg * 1000.

                rh_modelfg = make_rh(p_modelfg_mb              ! fractional rh
     1                     ,t_modelfg_c,q_modelfg_gkg,t_ref)

!               QC the rh
                rh_qc = rh_modelfg                             ! fractional rh

                if(rh_qc .gt. 1.0)then
                    rh_qc = 1.0
                    i_hum_high = i_hum_high + 1
                elseif(rh_qc .lt. 0.0)then
                    rh_qc = 0.0
                    i_hum_low = i_hum_low + 1
                else
                    i_hum_ok = i_hum_ok + 1
                endif

                if(cld_hts(k) .gt. 11000.)rh_qc = .01   ! set upper lvls to dry
                                                        ! counters model (ruc) 
                                                        ! moist bias

                cf_modelfg(i,j,k) = rh_to_cldcv(rh_qc)  ! fractional_rh

            else
                write(6,*)' Code error in get_modelfg, STOP'
                stop
!               istatus = 0
!               return

            endif

 1000   enddo ! i
        enddo ! j
        enddo ! k (cloud height array level)

        write(6,*)' # RH values QCed  high/low/ok'
     1            ,i_hum_high,i_hum_low,i_hum_ok
        write(6,*)' # cloud height grids above pressure grid'
     1            ,i_grid_high
        write(6,*)' # points set to cloud based on condensate = '
     1           ,i_condensate

        return
        end
