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

        subroutine laps_accum(i4time,
     1                        NX_L,NY_L,NZ_L,
     1                        i_diag,
     1                        n_prods,
     1                        iprod_number,
     1                        j_status)

!       1991            Steve Albers
!       1996 May        Steve Albers  Call 'get_laps_cycle_time'
!                                     Use 'ilaps_cycle_time' to calculate
!                                     'precip_reset_thresh'.
!       1997 Mar        Steve Albers  Added calls to 'move' to replace 
!                                     equivalencing.
!       1997 Jun        Ken Dritz     Made NX_L, NY_L, NZ_L dummy arguments,
!                                     making non-dummy arrays dimensioned
!                                     therewith dynamic (automatic).
!       1997 Jun        Ken Dritz     Changed include of lapsparms.for to
!                                     include of laps_static_parameters.inc.

        integer  ss_normal,rtsys_bad_prod,rtsys_no_data
     1                                     ,rtsys_abort_prod
        parameter (ss_normal        =1, ! success
     1             rtsys_bad_prod   =2, ! inappropriate data, insufficient data
     1             rtsys_no_data    =3, ! no data
     1             rtsys_abort_prod =4) ! failed to make a prod

        include 'laps_static_parameters.inc'

        integer i4time,i_diag,n_prods

        real*4 lat(NX_L,NY_L),lon(NX_L,NY_L)
        real*4 topo(NX_L,NY_L)

        real*4 snow_2d(NX_L,NY_L)
        real*4 snow_2d_tot(NX_L,NY_L)

        real*4 precip_2d(NX_L,NY_L)
        real*4 precip_2d_tot(NX_L,NY_L)

        real*4 field_2d(NX_L,NY_L,4)

        real*4 precip_type_2d(NX_L,NY_L)

        character*9 filename, filename_start

c       character*13 filename13

        character*31  radarext_3d_accum

c       character var*3,comment*125,directory*150,ext*31,units*10
        character var*3,directory*150,ext*31,units*10

        character*125 comment_s,comment_r

c       character*80 c80_domain_file

        integer j_status(20),iprod_number(20)

        character*40 c_vars_req
        character*180 c_values_req

        ISTAT = INIT_TIMER()

        write(6,*)
     1         ' Welcome to the LAPS gridded snow/precip accum analysis'       

        c_vars_req = 'radarext_3d_accum'

        call get_static_info(c_vars_req,c_values_req,1,istatus)

        if(istatus .eq. 1)then
            radarext_3d_accum = c_values_req(1:3)
        else
            write(6,*)' Error getting radarext_3d_accum'
            return
        endif

        write(6,*)' radarext_3d_accum = ',radarext_3d_accum

c read in laps lat/lon and topo
        call get_laps_domain(NX_L,NY_L,LAPS_DOMAIN_FILE,lat,lon,topo
     1                      ,istatus)
        if(istatus .eq. 0)then
            write(6,*)' Error getting LAPS domain'
            return
        endif

        icen = NX_L/2 + 1
        jcen = NY_L/2 + 1
        call get_grid_spacing_actual(lat(icen,jcen),lon(icen,jcen)
     1                              ,grid_spacing_cen_m,istatus)
        if(istatus .eq. 1)then
            write(6,*)' Actual grid spacing in domain center = '
     1                              ,grid_spacing_cen_m
        else
            return
        endif

        call get_laps_cycle_time(ilaps_cycle_time,istatus)
        if(istatus .eq. 1)then
            write(6,*)' ilaps_cycle_time = ',ilaps_cycle_time
        else
            write(6,*)' Error getting laps_cycle_time'
            return
        endif

        n_prods = 1

        do i = 1,n_prods
            j_status(i) = rtsys_abort_prod
        enddo

        n_l1s = 1

        ext = 'l1s'

        if(ext(1:3) .ne. 'l1s')then
            iprod_number(n_l1s) = 36352 ! L1S
        else
            iprod_number(n_l1s) = 27280 ! S1S
        endif

!       Get Incremental Accumulations from Radar Data & Update Storm Totals
        i4time_now = i4time_now_gg()
        i_wait = (i4time + (35*60) - i4time_now) / 60
        write(6,*)' Number of potential wait cycles = ',i_wait

        istatus_inc = 1

        i4time_end = i4time
        i4time_beg = i4time_end - ilaps_cycle_time

        minutes = ilaps_cycle_time / 60

        write(6,*)' Getting Snow/Precip Accumulation over ',minutes
     1           ,' min'
50      call get_precip_accum(i4time_beg,i4time_end,NX_L,NY_L,NZ_L
     1          ,lat,lon,topo,ilaps_cycle_time,grid_spacing_cen_m
     1          ,radarext_3d_accum                     ! Input
     1          ,snow_2d,precip_2d,frac_sum,istatus_inc)

        if(istatus_inc .ne. 1)then ! Decide whether to wait for radar data
            if(i_wait .gt. 0 .and. frac_sum .ge. 0.30)then
                write(6,*)' Waiting 1 min for possible radar data'
     1                    ,frac_sum
                call snooze_gg(60.0,istat_snooze)
                i_wait = i_wait - 1
                goto50

            else ! Will not wait for radar data
                write(6,*)' WARNING: Insufficient data for accum'
                write(6,*)' No accum output being generated'
                return

            endif
        endif

        comment_r = '           Null Comment'
        comment_s = '           Null Comment'

!       Get storm total from previous analysis cycle
        if(istatus_inc .eq. 1)then
            write(6,*)' Getting Previous Storm Total Accumulations'
            ext = 'l1s'
            var = 'STO'
            call get_laps_2d(i4time-ilaps_cycle_time,ext,var,units
     1                    ,comment_s,NX_L,NY_L,snow_2d_tot,istatus_tot)

            if(istatus_tot .eq. 1)then
                var = 'RTO'
                call get_laps_2d(i4time-ilaps_cycle_time,ext,var,units
     1                  ,comment_r,NX_L,NY_L,precip_2d_tot,istatus_tot)
            endif

            if(istatus_tot .ne. 1)then
                write(6,*)' WARNING: could not read previous storm'
     1                   ,' total accumulations'
            endif
        endif

!       Set rate threshold based on length of storm total so far 
        rate_thresh = .0001
        filename_start = comment_r(1:9)

        if(istatus_tot .eq. 1)then
            call i4time_fname_lp(filename_start, i4time_start_tot
     1                         , istatus)       
        else
            istatus = 0
        endif

        if(istatus .ne. 1)then
            write(6,*)' Could not get start time for storm total'
     1                 ,comment_r
            i4_prev_total = 0
            istatus_tot = 0

        else ! Valid storm total start time in comment
            i4_prev_total = i4time_beg - i4time_start_tot
            if(i4_prev_total .gt. 48*3600)then
                rate_thresh = .0015   
            endif
        endif

        write(6,*)i4_prev_total/3600,' hour previous storm total,'       
     1                              ,' rate_thresh = ',rate_thresh

!       Decide whether to reset Storm Total based on insignificant precip over
!       current cycle time
        i_suff_pcp = 0

        precip_reset_thresh = 
     1                  rate_thresh * float(ilaps_cycle_time) / 3600.

        if(istatus_inc .eq. 1 .and. istatus_tot .eq. 1)then
            precip_max = 0.
            do j = 1,NY_L
            do i = 1,NX_L
                precip_max = max(precip_max,precip_2d(i,j))
                if(precip_2d(i,j) .gt. precip_reset_thresh)then    
                    i_suff_pcp = 1
                endif
            enddo ! i
            enddo ! j
            write(6,*)' Max precip over domain = ',precip_max
            if(i_suff_pcp .eq. 0)then
                write(6,*)' Resetting due to insufficient precip'
            else
                write(6,*)
     1          ' We have sufficient precip to continue storm total'
            endif
        endif


!       Add current hour snow accumulation to storm total
        if(istatus_inc .eq. 1 .and. istatus_tot .eq. 1
     1                        .and. i_suff_pcp  .eq. 1)then
            write(6,*)' Adding latest increment for new Storm Total '
     1               ,'Accumulation'
            call add(snow_2d,  snow_2d_tot,  snow_2d_tot,  NX_L,NY_L)
            call add(precip_2d,precip_2d_tot,precip_2d_tot,NX_L,NY_L)

        elseif(istatus_inc .eq. 1)then
            write(6,*)' Resetting Storm Total Accumulations to '
     1               ,minutes,' min values'

!           Put the new reset time in the file header
            call make_fnam_lp(i4time-ilaps_cycle_time,filename,istatus)
            comment_s = filename//
     1                  ' Time that storm total snow begins at.'
            comment_r = filename//
     1                  ' Time that storm total precip begins at.'

            call move(snow_2d  ,snow_2d_tot  ,NX_L,NY_L)
            call move(precip_2d,precip_2d_tot,NX_L,NY_L)

        endif ! Valid continuation of storm total

        if(istatus_inc .eq. 1)then
            write(6,*)' Writing Incr / Storm Total Accumulations'
            write(6,*)comment_r(1:80)
            write(6,*)comment_s(1:80)
            ext = 'l1s'
            call get_directory(ext,directory,len_dir)
            units = 'M'

            call move(snow_2d,      field_2d(1,1,1),NX_L,NY_L)
            call move(snow_2d_tot,  field_2d(1,1,2),NX_L,NY_L)
            call move(precip_2d,    field_2d(1,1,3),NX_L,NY_L)
            call move(precip_2d_tot,field_2d(1,1,4),NX_L,NY_L)

            call put_precip_2d(i4time,directory,ext,var,units
     1       ,comment_s,comment_r,NX_L,NY_L,field_2d,ilaps_cycle_time
     1       ,istatus)
            if(istatus .eq. 1)j_status(n_l1s) = ss_normal

        else
            write(6,*)' Not Writing Incr / Storm Total Accumulations'
            j_status(n_l1s) = rtsys_no_data

        endif

        I4_elapsed = ishow_timer()

999     continue

        return
        end


        subroutine put_precip_2d(i4time,DIRECTORY,EXT,var,units,
     1                  comment_s,comment_r,imax,jmax,field_2dsnow
     1                                          ,ilaps_cycle_time
     1                                                  ,istatus)

        integer nfields
        parameter (nfields = 4)

        character*(*) DIRECTORY
        character*31 EXT

        character*125 comment_s,comment_r,comment_2d(nfields)
        character*10 units,units_2d(nfields)
        character*3 var,var_2d(nfields)
        integer LVL,LVL_2d(nfields)
        character*4 LVL_COORD,LVL_COORD_2d(nfields)

        real*4 field_2dsnow(imax,jmax,nfields)

        lend = len(directory)
        write(6,11)directory(1:lend),ext(1:5)
11      format(' Writing 2d Snow/Precip ',a,1x,a5,1x,a3)

        lvl = 0
        lvl_coord = 'MSL'

        var_2d(1) = 'S01'
        var_2d(2) = 'STO'
        var_2d(3) = 'R01'
        var_2d(4) = 'RTO'

        minutes = ilaps_cycle_time/60

        write(comment_2d(1),21)minutes
21      format('LAPS',i3,' Minute Snow Accumulation')

        comment_2d(2) = comment_s

        write(comment_2d(3),22)minutes
22      format('LAPS',i3,' Minute Precip Accumulation')

        comment_2d(4) = comment_r

        do k = 1,nfields
            LVL_2d(k) = LVL
            LVL_Coord_2d(k) = LVL_Coord
            UNITS_2d(k) = 'M'
        enddo

        CALL WRITE_LAPS_DATA(I4TIME,DIRECTORY,EXT,imax,jmax,
     1  nfields,nfields,VAR_2D,LVL_2D,LVL_COORD_2D,UNITS_2D,
     1                     COMMENT_2D,field_2dsnow,ISTATUS)

        return
        end
