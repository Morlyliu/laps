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



        subroutine plot_station_locations(i4time,lat,lon,ni,nj,iflag
     1                                   ,maxsta,c_field,zoom
     1                                   ,namelist_parms,atime
     1                                   ,c33_label,i_overlay)

        include 'lapsplot.inc'

!       Declarations for 'read_surface_snd', etc.
        include 'read_sfc.inc'

!       97-Aug-14     Ken Dritz     Added maxsta as dummy argument
!       97-Aug-14     Ken Dritz     Removed include of lapsparms.for
!       97-Aug-25     Steve Albers  Removed /read_sfc_cmn/.

!       This routine labels station locations on the H-sect

        real*4 lat(ni,nj),lon(ni,nj)

        character atime*24, c33_label*33
        character directory*150,ext*31,ext_lso*6
        character*255 c_filespec
        character*9 c9_string, asc_tim_9
        character*13 filename13
        character*2 c_field
        character*3 c_staname, c3_presob

!       Declarations for 'read_sfc_state' call
        real*4 pr_s(maxsta), sr_s(maxsta)
        real*4 sfct_s(maxsta)
        character c3_stations_a(maxsta)*3, c8_wx_a(maxsta)*8

!       Declarations for 'read_surface_sa' call
!       New arrays for reading in the SAO data from the LSO files
        real*4   ceil(maxsta),lowcld(maxsta),cover_a(maxsta)
     1          ,vis(maxsta),rad(maxsta)

        Integer*4   kloud(maxsta),idp3(maxsta)

        Character store_emv(maxsta,5)*1 ! ,store_amt(maxsta,5)*4

        character atype(maxsta)*6

!       Declarations for 'read_sfc_precip' call
	character filetime*9, infile*256, btime*24
        character c20_stations*20
	character dum*132

        logical l_parse

        call get_sfc_badflag(badflag,istatus)

        lun = 42

        if(c_field(1:2) .eq. 'mw')then ! Read Mesowx
            ext = 'mesowx'
            call get_directory(ext,directory,len_dir) ! Mesowx directory
            infile = 
     1      directory(1:len_dir)//'lfmpost_points.txt'

            open(lun,file=infile,status='unknown')

            i = 1
 4          read(lun,5,end=15)lat_s(i),lon_s(i)
 5          format(2x,1x,10x,1x,f8.0,f10.0)

            i = i+1

            go to 4            

 15         n_obs_b = i-1

        else ! Read LSO or LSO_QC 

            call get_filespec('lso',2,c_filespec,istatus)
            call get_file_time(c_filespec,i4time,i4time_lso)

            if(i4time_lso .eq. 0)then
                write(6,*)
     1          ' No LSO files available for station plotting'       
                return
            endif

            call make_fnam_lp(i4time_lso,asc_tim_9,istatus)

            ext = 'lso'
            call get_directory(ext,directory,len_dir) ! Returns top level directory
            if(c_field(1:1) .eq. 'q')then ! LSO_QC file
                infile = 
     1          directory(1:len_dir)//filename13(i4time_lso,ext(1:3))
     1                              //'_qc'    

                ext_lso = 'lso_qc'

            else ! Regular LSO file
                infile = 
     1          directory(1:len_dir)//filename13(i4time_lso,ext(1:3))  

                ext_lso = 'lso'

            endif

            if(ext_lso .eq. 'lso')then ! phase in call to read_surface_data
              write(6,*)' Calling read_surface_data...',ext_lso
     1                                                 ,asc_tim_9      
              call read_surface_data(i4time,atime_s,n_obs_g,n_obs_b, !regular LSO
     &         obstime,wmoid,stations,provider,wx_s,reptype,autostntype,       
     &         lat_s,lon_s,elev_s,t_s,td_s,rh_s,dd_s,ff_s,ddg_s,ffg_s,
     &         alt_s,pstn_s,pmsl_s,delpch,delp,vis_s,solar_s,sfct,sfcm,
     &         pcp1,pcp3,pcp6,pcp24,snow,kloud_s,max24t,min24t,t_ea,
     &         td_ea,rh_ea,dd_ea,ff_ea,alt_ea,p_ea,vis_ea,solar_ea,
     &         sfct_ea,sfcm_ea,pcp_ea,snow_ea,store_amt,store_hgt,mxstn,
     &         istatus)
            else
              write(6,*)' Calling read_surface_dataqc...',ext_lso
     1                                                 ,asc_tim_9      
              call read_surface_dataqc(i4time,atime_s,n_obs_g,n_obs_b, !regular LSO
     &         obstime,wmoid,stations,provider,wx_s,reptype,autostntype,       
     &         lat_s,lon_s,elev_s,t_s,td_s,rh_s,dd_s,ff_s,ddg_s,ffg_s,
     &         alt_s,pstn_s,pmsl_s,delpch,delp,vis_s,solar_s,sfct,sfcm,
     &         pcp1,pcp3,pcp6,pcp24,snow,kloud_s,max24t,min24t,t_ea,
     &         td_ea,rh_ea,dd_ea,ff_ea,alt_ea,p_ea,vis_ea,solar_ea,
     &         sfct_ea,sfcm_ea,pcp_ea,snow_ea,store_amt,store_hgt,mxstn,
     &         istatus)

            endif

            write(6,*)'     n_obs_g:',n_obs_g,'      n_obs_b:',n_obs_b       

            if(ext_lso .eq. 'lso')then ! this routine may not yet work for QC obs?
                write(6,*)' Calling read_surface_sa...',infile,atime
                call read_surface_sa(infile,maxsta,atime,n_obs_g,
     &             n_obs_b,c3_stations_a,reptype,atype,lat_s,lon_s,      
     &             elev_s,c8_wx_a,t_s,td_s,dd_s,ff_s,ddg_s,ffg_s,pstn_s,      
     &             pmsl_s,alt_s,kloud,ceil,lowcld,cover_a,
     &             rad,sfct_s,idp3,           
     &             store_emv,store_amt,store_hgt,vis_s,obstime,istatus)

            else                       ! QC case
                if(n_obs_g .eq. 0)n_obs_g = n_obs_b         ! Bug recovery

            endif

            write(6,*)'     n_obs_g:',n_obs_g,'      n_obs_b:',n_obs_b       

            if(n_obs_b .gt. maxsta .or. istatus .ne. 1)then
                write(6,*)' Too many stations, or no file present'
                istatus = 0
                return
            endif

            if(.true.)then
	      call read_sfc_snd(i4time,atime_s,n_obs_g,n_obs_b, ! regular SND
     &         obstime,wmoid,stations,provider,wx_s,reptype,autostntype,       
     &         lat_s,lon_s,elev_s,t_s,td_s,rh_s,dd_s,ff_s,ddg_s,ffg_s,
     &         alt_s,pstn_s,pmsl_s,delpch,delp,vis_s,solar_s,sfct,sfcm,
     &         pcp1,pcp3,pcp6,pcp24,snow,kloud_s,max24t,min24t,t_ea,
     &         td_ea,rh_ea,dd_ea,ff_ea,alt_ea,p_ea,vis_ea,solar_ea,
     &         sfct_ea,sfcm_ea,pcp_ea,snow_ea,store_amt,store_hgt,mxstn,
     &         istatus)
            endif

            write(6,*)'     n_obs_g:',n_obs_g,'      n_obs_b:',n_obs_b       

            if(n_obs_b .gt. maxsta)then
                write(6,*)' Too many stations'
                istatus = 0
                return
            endif

            i_rh_convert = 0
	    do i=1,n_obs_b ! Preprocess the obs
!               Convert RH to dewpoint if dewpoint is missing 
                if(t_s(i) .ne. badflag .and. td_s(i) .eq. badflag 
     1                                 .and. rh_s(i) .ne. badflag )then       
                    t_c = f_to_c(t_s(i))
                    dwpt_c = dwpt(t_c,rh_s(i))
                    td_s(i) = c_to_f(dwpt_c)
                    i_rh_convert = i_rh_convert + 1
                endif
            enddo ! i

            if(i_rh_convert .gt. 0)then
                write(6,*)'# of dewpoints converted from RH = '
     1                   ,i_rh_convert       
            endif

        endif ! Mesowx or LSO

        size = 0.5
        call getset(mxa,mxb,mya,myb,umin,umax,vmin,vmax,ltype)
        du = float(ni) / 300.

        zoom_eff = zoom / 3.0

!       At zoom=1-3, make the obs plot larger if there are few obs
        if(zoom_eff .lt. 1.0 .and. n_obs_g .gt. 30)then
            zoom_eff = 1.0
        endif

        du2 = du / zoom_eff

!       call setusv_dum(2HIN,11)

        if(c_field(2:2) .eq. 'v')then ! Ceiling & Visibility
            iflag_cv = 1
        elseif(c_field(2:2) .eq. 'p')then     ! Precip
            write(6,*)' Reading precip obs'
	    call read_sfc_precip(i4time,btime,n_obs_g,n_obs_b,
     &        stations,provider,lat_s,lon_s,elev_s,
     &        pcp1,pcp3,pcp6,pcp24,snow,       
     &        maxsta,jstatus)
            iflag_cv = 2
        elseif(c_field(2:2) .eq. 'g')then ! Soil/Water Temp & Solar Radiation
            iflag_cv = 3
        else
            iflag_cv = 0
        endif

        write(6,*)' plot_station_locations... ',iflag

        c3_presob = '   '

        if(iflag .ge. 1)then
            if(iflag_cv .eq. 0)then
                write(6,13)
13              format(' Select type of pressure ob [msl,alt,stn]'
     1                ,4x,'default=none      ? ',$)
                read(5,14)c3_presob
14              format(a)
            endif

            if(c_field(1:1) .eq. 'q')then ! LSO_QC file
                c33_label = 'Sfc QC Obs   ('//c3_presob//' pres)'
            else
                c33_label = 'Sfc Obs      ('//c3_presob//' pres)'
            endif

            if(iflag_cv .eq. 1)then
                c33_label(14:33) =  '          Ceil & Vis'
            elseif(iflag_cv .eq. 2)then
                c33_label(13:33) = '1Hr Pcp/Snw Dpth (in)'
            elseif(iflag_cv .eq. 3)then
                c33_label(14:33) =  '   Sfc T & Solar Rad'
            endif

            call set(.00,1.0,.00,1.0,.00,1.0,.00,1.0,1)
            call write_label_lplot(ni,nj,c33_label,asc_tim_9
     1                            ,namelist_parms,i_overlay,'hsect')       

        endif

        call get_border(ni,nj,x_1,x_2,y_1,y_2)
        call set(x_1,x_2,y_1,y_2,1.,float(ni),1.,float(nj),1)

        call get_r_missing_data(r_missing_data,istatus)
        call get_sfc_badflag(badflag,istatus)

!       Plot Stations
        do i = 1,n_obs_b ! num_sfc
            wx_s(i) = c8_wx_a(i)

            call latlon_to_rlapsgrid(lat_s(i),lon_s(i),lat,lon
     1                          ,ni,nj,xsta,ysta,istatus)

            if(xsta .lt. 1. .or. xsta .gt. float(ni) .OR.
     1         ysta .lt. 1. .or. ysta .gt. float(nj)          )then       
                    goto80
            endif
!           call supcon(lat_s(i),lon_s(i),usta,vsta)

!           IFLAG = 0        --        Station locations only
!           IFLAG = 1        --        FSL Mesonet only (for WWW)
!           IFLAG = 2        --        All Sfc Obs

            if(iflag .ge. 1)then

                w1 = dd_s(i)
                w2 = ff_s(i)
                w3 = ffg_s(i)

                if(iflag .eq. 1)call setusv_dum(2HIN,14)

                c20_stations = stations(i)

                len_sta_plot = 3 ! maximum station name length allowed in plot

                call left_justify(c20_stations)
                call s_len(c20_stations,len_sta)

                if(len_sta .eq. 4 .and. len_sta_plot .eq. 3)then
                    c_staname = c20_stations(len_sta-2:len_sta)
                else
                    c_staname = c20_stations(1:len_sta_plot)
                endif

                charsize = .0040 / zoom_eff

                if(iflag_cv .eq. 0 .and. atype(i) .ne. 'CUM')then
!                   Plot station name & Wx String
                    CALL PCLOQU(xsta, ysta-du2*3.5, c_staname, 
     1                          charsize,ANGD,CNTR)
                    CALL PCLOQU(xsta+du2*1.1, ysta-du2*1.1, wx_s(i),        
     1                              charsize,ANGD,-1.0)
                endif

                relsize = 1.1

                if(iflag .eq. 1)call setusv_dum(2HIN,11)

                if(iflag_cv .eq. 1)then ! Ceiling & Visibility
                    if(vis_s(i) .ne. badflag)then
                        dewpoint = vis_s(i)
                    else
                        dewpoint = badflag
                    endif

                    nlyr = kloud(i)

                    if(nlyr .ge. 1)then
                        CALL PCLOQU(xsta, ysta-du2*3.5, c_staname, 
     1                              charsize,ANGD,CNTR)
                    endif

                    pressure = float(nlyr)        ! number of cloud layers
                    w1       = store_hgt(i,1)     ! height of 1st layer
                    if(nlyr .ge. 2)w2 = store_hgt(i,2)      ! 2nd layer
                    if(nlyr .ge. 3)w3 = store_hgt(i,3)      ! 3rd layer

                    if(nlyr .ge. 1)then                    
                        if(l_parse(store_amt(i,nlyr),'CLR'))then
                            temp = 0.0
                        elseif(l_parse(store_amt(i,nlyr),'SKC'))then
                            temp = 0.0
                        elseif(l_parse(store_amt(i,nlyr),'FEW'))then
                            temp = 0.1
                        elseif(l_parse(store_amt(i,nlyr),'SCT'))then
                            temp = 0.3
                        elseif(l_parse(store_amt(i,nlyr),'BKN'))then
                            temp = 0.7
                        elseif(l_parse(store_amt(i,nlyr),'OVC'))then
                            temp = 1.0
                        else
                            write(6,*)' Unrecognized cloud fraction'
     1                               ,store_amt(i,nlyr)
                            temp = 0.0
                        endif
                    endif

                elseif(iflag_cv .eq. 2)then ! Precip
                    temp = badflag
                    if(pcp1(i) .ne. badflag)then
                        dewpoint = pcp1(i)
                        write(6,*)' Precip ob ',i,pcp1(i)
                    else
                        dewpoint = badflag
                    endif

                    if(snow(i) .ne. badflag)then
                        temp = snow(i)
                        write(6,*)' Snow ob ',i,snow(i)
                    else
                        temp = badflag
                    endif

                    pressure = r_missing_data

                    call s_len(wx_s(i),lenwx)

!                   Plot Weather String
                    if(lenwx .gt. 0)then
                        CALL PCLOQU(xsta-du2*0.9, ysta-du2*1.5
     1                        , wx_s(i)(1:lenwx), charsize,ANGD,+1.0)
                    endif

!                   Plot name and Station Location
                    if(pcp1(i) .ne. badflag .or. 
     1                 snow(i) .ne. badflag .or. lenwx .gt. 0)then
                        CALL PCLOQU(xsta, ysta-du2*3.5, c_staname, 
     1                              charsize,ANGD,CNTR)

                        call line(xsta,ysta+du2*0.5,xsta,ysta-du2*0.5)        
                        call line(xsta+du2*0.5,ysta,xsta-du2*0.5,ysta)

                    endif

                elseif(iflag_cv .eq. 3)then ! Soil/Water T (& solar radiation)
                    iplotsta = 0
                    temp = sfct_s(i)
                    dewpoint = badflag
                    pressure = badflag

                    if(temp .ne. badflag)then
                        write(6,*)' Sfc T = ',i,temp,c_staname
                        iplotsta = 1
                    endif

                    if(solar_s(i) .ne. badflag .and.
     1                 solar_s(i) .ge. 0.            )then
                        write(6,*)' Solar Rad = ',i,solar_s(i),c_staname       
                        pressure = solar_s(i)
                        iplotsta = 1
                    endif
                  
                    if(iplotsta .eq. 1)then
!                       Plot name and Station Location
                        CALL PCLOQU(xsta, ysta-du2*3.5, c_staname, 
     1                              charsize,ANGD,CNTR)
                        call line(xsta,ysta+du2*0.5,xsta,ysta-du2*0.5)
                        call line(xsta+du2*0.5,ysta,xsta-du2*0.5,ysta)
                    endif

                elseif(c_field(2:2) .ne. 'c')then ! Fahrenheit
                    temp = t_s(i)
                    dewpoint = td_s(i)

                else                          ! Celsius
                    if(t_s(i) .ne. badflag)then
                        temp = f_to_c(t_s(i))
                    else
                        temp = badflag
                    endif

                    if(td_s(i) .ne. badflag)then
                        dewpoint = f_to_c(td_s(i))
                    else
                        dewpoint = badflag
                    endif
                endif

                if(iflag_cv .eq. 0)then
                    if(c3_presob .eq. 'msl')then
                        pressure = pmsl_s(i)
                    elseif(c3_presob .eq. 'alt')then
                        pressure = alt_s(i)
                    elseif(c3_presob .eq. 'stn')then 
                        pressure = pstn_s(i)
                    else
                        pressure = r_missing_data
                    endif

                endif

                if(atype(i) .ne. 'CUM')then ! exclude CWB precip stations
                    call plot_mesoob(w1,w2,w3
     1                 ,temp,dewpoint
     1                 ,pressure,xsta,ysta
     1                 ,lat,lon,ni,nj,relsize,zoom,n_obs_g,11,du2
     1                 ,wx_s(i)
     1                 ,iflag,iflag_cv)
                endif

                if(iflag .eq. 1)call setusv_dum(2HIN,33)

            else ! Write station location only
                if(c_field(1:2) .eq. 'mw')then ! Set Mesowx Red Color
                    call setusv_dum(2hIN,3)
                endif

                call line(xsta,ysta+du2*0.5,xsta,ysta-du2*0.5)
                call line(xsta+du2*0.5,ysta,xsta-du2*0.5,ysta)

            endif

80      enddo ! i

        if(iflag .eq. 1)then ! special mesonet label 
            call setusv_dum(2hIN,2)
            call cv_i4tim_asc_lp(i4time,atime,istatus)
            atime = atime(1:14)//atime(16:17)//' '
            ix = 590
            iy = 270
            call pwrity(cpux(ix),cpux(iy),atime(1:17),17,-1,0,-1)
        endif

        call sflush

        return
        end

c
c
        subroutine plot_mesoob(dir,spd,gust,t,td,p,ri,rj
     1                        ,lat,lon,imax,jmax,relsize_in,zoom,nobs
     1                        ,icol_in,du2,wx,iflag,iflag_cv)

        include 'lapsparms.cmn'

        real*4 lat(imax,jmax),lon(imax,jmax)
        character*3 t1,td1,p1
        character*4 c4_pcp
        character*(*)wx

        call getset(mxa,mxb,mya,myb,umin,umax,vmin,vmax,ltype)
!       write(6,1234) mxa,mxb,mya,myb,umin,umax,vmin,vmax,ltype
 1234   format(1x,4i5,4e12.4,i4)

        zoom_eff = zoom / 3.0

!       At zoom=1-3, make the obs plot larger if there are few obs
        if(zoom_eff .lt. 1.0 .and. nobs .gt. 30)then
            zoom_eff = 1.0
        endif

        relsize = relsize_in / zoom_eff

        du_b=(imax)/300. * relsize

        jsize = nint(0.4 * relsize) - 1

        write(6,*)' relsize,du_b,jsize,zoom = ',relsize,du_b,jsize,zoom       

        call get_border(imax,jmax,x_1,x_2,y_1,y_2)
        call set(x_1,x_2,y_1,y_2,1.,float(imax),1.,float(jmax))

!       rot = (standard_longitude - lon(nint(ri),nint(rj))) / 57.295

        rot = projrot_latlon(lat(nint(ri),nint(rj))
     1                      ,lon(nint(ri),nint(rj)),istatus) / 57.295

!       Convert ri and rj to x1 and y1 (U and V)
!       call supcon(alat,alon,x1,y1)
        x1 = umin + (umax - umin) * (ri-1.) / float(imax-1)
        y1 = vmin + (vmax - vmin) * (rj-1.) / float(jmax-1)

        xsta=ri
        ysta=rj

        u = ri
        v = rj

        if(iflag .eq. 3)then ! Plot on top of station location for 'tmg'
            du = 0.
        else
            du = du_b
        endif

        dv   = 1.2 * du
        du_t = 3.0 * du
        du_p = 3.0 * du

        charsize = .0040 / zoom_eff

        if(iflag_cv .eq. 0)then ! Normal obs plot
            if(dir .ge. 0.  .and. spd .ge. 0. .and.
     1         dir .le. 360 .and. spd .le. 200.       )then
                call barbs(spd,dir,ri,rj,du_b,rot
     1                    ,-1e10,+1e10,-1e10,+1e10)
                if(spd .ge. 1.0)then
                    call line(xsta,ysta+du2*0.5,xsta,ysta-du2*0.5)
                    call line(xsta+du2*0.5,ysta,xsta-du2*0.5,ysta)
                endif
            else
                call line(xsta,ysta+du2*0.5,xsta,ysta-du2*0.5)
                call line(xsta+du2*0.5,ysta,xsta-du2*0.5,ysta)
            endif

!           Plot Temperature       
            if(t.gt.-75. .and. t.lt.140.) then 
               write(t1,100,err=20) nint(t)
!              call pwrity(u-du_t,v+dv,t1,3,jsize,0,0)
               CALL PCLOQU(u-du_t,v+dv,t1,charsize,ANGD,CNTR)
            endif
 100        format(i3)
 20         continue

!           Plot Dew Point
            if(td.gt.-75. .and. td.lt.100.) then
               write(td1,100,err=30) nint(td)
               CALL PCLOQU(u-du_t,v-dv,td1,charsize,ANGD,CNTR)
            endif
 30         continue
 
!           Plot Pressure
            if(p .gt. 0. .and. p .lt. 10000.) then
               if(p .ge. 1000.) p = p - 1000.
               ip = ifix( p )
               write(p1,101,err=40) ip
 101           format(i3.3)
!              call pwrity(u+du_p,v+dv,p1,3,jsize,0,0)
               CALL PCLOQU(u+du_p,v+dv,p1,charsize,ANGD,CNTR)
            endif

!           Plot Gusts (FSL WWW)
            if(iflag .eq. 1)then 
               if(gust .gt. 40)then
                   ig = int(gust)
                   write(p1,102,err=40) ig
                   call setusv_dum(2HIN,4)
                   dg = 3.0 * du
!                  call pwrity(u,v+dg,p1,3,jsize,0,0)          ! On Top
!                  call pwrity(u+du_p,v-dv,p1,3,jsize,0,0)     ! Lower Right
 102               format('G',i2)
                   call setusv_dum(2HIN,icol_in)
               endif
            endif           

        elseif(iflag_cv .eq. 1)then ! C&V plot
!           Plot outer circle (use p for the number of layers?)
            if(p .ge. 1.0)then
                call plot_circle(u,v,du*0.8) 

!               Plot cloud cover (using t to hold the variable)
                call plot_circle_fill(u,v,du*0.8,t)

            endif ! number of layers

!           Plot Visibility (using td to hold the variable)
            if(td.gt.-75. .and. td.lt.100.) then
               write(td1,100,err=31) nint(td)
               call left_justify(td1)
               CALL PCLOQU(u+du_t,v-dv,td1,charsize,ANGD,CNTR)
            endif
 31         continue

        elseif(iflag_cv .eq. 2)then ! Precip obs plot
!           Plot 1hr Precip Ob
            if(td.gt.-75. .and. td.lt.100.) then
               write(c4_pcp,103,err=32) td
 103           format(f4.2)
               call left_justify(c4_pcp)
               CALL PCLOQU(u+du_t,v-dv,c4_pcp,charsize,ANGD,CNTR)
            endif
 32         continue

        elseif(iflag_cv .eq. 3)then ! Sfc T & Solar Radiation plot
!           Plot Temperature       
            if(t.gt.-75. .and. t.lt.140.) then 
               write(t1,100,err=40) nint(t)
               CALL PCLOQU(u-du_t,v+dv,t1,charsize,ANGD,CNTR)
            endif

!           Plot Solar Radiation (pressure variable)
            if(p .gt. 0. .and. p .lt. 10000.) then
               if(p .ge. 1000.) p = p - 1000.
               ip = ifix( p )
               write(p1,201,err=40) ip
 201           format(i3.3)
               CALL PCLOQU(u+du_p,v+dv,p1,charsize,ANGD,CNTR)
            endif

        endif
c
 40     continue

        call sflush

        return
        end
