
 
       subroutine radar_init(i_radar,i_tilt_proc,i_last_scan,istatus)       
!                                 I       I           O         O
 
!      Open/Read Polar NetCDF file for the proper time
       integer max_files
       parameter(max_files=1000)

       character*150 path_to_radar,c_filespec,filename,directory
     1              ,c_fnames(max_files)
       character*15 path_to_vrc
       character*4 c4_radarname ! Not used in this file
       character*9 a9_time
       integer*4 i4times(max_files),i4times_lapsprd(max_files)
       character*2 c2_tilt
       character*3 ext_out, c3_radar_subdir
       character*8 radar_subdir

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
!      include 'remap_constants.dat' ! for debugging only
!      include 'remap.cmn' ! for debugging only

       call get_remap_parms(i_radar,n_radars_remap,path_to_radar       
     1                    ,c4_radarname,ext_out,c3_radar_subdir
     1                    ,path_to_vrc,istatus)       

c
c      Determine filename extension
       write(6,*)' radar_init: laps_ext = ',ext_out
       if(ext_out(1:1) .ne. 'v')then
           ext_out = 'v01'
       endif

       if(ext_out .eq. 'vrc')then 
           radar_subdir = c3_radar_subdir
           write(6,*)' radar_init: radar_subdir = ',radar_subdir
       endif

       i_last_scan = 0

       if(i_tilt_proc .lt. 10)then
           write(c2_tilt,101)i_tilt_proc
 101       format('0',i1)
       else
           write(c2_tilt,102)i_tilt_proc
 102       format(i2)
       endif

       if(i_tilt_proc .eq. 1)then
           c2_tilt = '01'

           call s_len(path_to_radar,len_path)
 
!          Get i4time of 01 elevation files
           c_filespec = path_to_radar(1:len_path)//'/*_elev'//c2_tilt       

           call get_file_times(c_filespec,max_files,c_fnames
     1                        ,i4times,i_nbr_files_out,istatus)

           write(6,*)' # of raw files = ',i_nbr_files_out
           if(istatus .ne. 1 .or. i_nbr_files_out .eq. 0)then
               istatus = 0
               return
           endif

           if(ext_out .ne. 'vrc')then
               call get_filespec(ext_out,1,c_filespec,istatus)

           else ! We should add path_to_vrc
               call get_directory('rdr',directory,len_dir)
               c_filespec = directory(1:len_dir)//radar_subdir(1:3)     

           endif


           call get_file_times(c_filespec,max_files,c_fnames
     1                   ,i4times_lapsprd,i_nbr_lapsprd_files,istatus)

           if(i_nbr_files_out .ge. 2)then
               i4time_process = i4times(i_nbr_files_out-1)
               call make_fnam_lp(i4time_process,a9_time,istatus)
               do i = 1,i_nbr_lapsprd_files
                   if(i4time_process .eq. i4times(i))then
                       write(6,*)' Product file already exists ',a9time      
                   endif
               enddo ! i
           endif

       endif

!      Pull in housekeeping data from 1st tilt

       filename = path_to_radar(1:len_path)//'/'//a9_time//'_elev'
     1            //c2_tilt
       write(6,*)' radar_init: we will read this file... '
       write(6,*)filename(1:len_path+20)

       call get_tilt_netcdf_data(filename
     1                               ,radarName
     1                               ,siteLat                        
     1                               ,siteLon                        
     1                               ,siteAlt                        
     1                               ,elevationAngle
     1                               ,numRadials
     1                               ,elevationNumber
     1                               ,VCP
     1                               ,r_nyquist
     1                               ,radialAzim
     1                               ,Z
     1                               ,V
     1                               ,resolutionV
     1                               ,gateSizeV,gateSizeZ
     1                               ,firstGateRangeV,firstGateRangeZ
     1                               ,MAX_VEL_GATES, MAX_REF_GATES
     1                               ,MAX_RAY_TILT
     1                               ,istatus)

       if(istatus .eq. 1
     1             .AND.
     1     .not. (ext_out .eq. 'vrc' .and. i_tilt_proc .gt. 1)
     1                                                         )then
           if(i_tilt_proc .eq. 1)then
               write(6,201)elevationNumber, i_tilt_proc
 201           format(' elevationNumber, i_tilt_proc',2i4)
           else
               write(6,202)elevationNumber, i_tilt_proc
 202           format(' elevationNumber, i_tilt_proc',2i4
     1               ,' (upcoming tilt)')
           endif

       else
           write(6,*)' Could not read tilt # ',i_tilt_proc
           i_last_scan = 1

       endif

       write(6,*)

       istatus = 1
       return
       end
 
       function get_altitude()
       integer get_altitude          ! Site altitude (meters)

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       get_altitude = nint(siteAlt)

       return
       end
 
 
       function get_latitude()
       integer get_latitude          ! Site latitude (degrees * 100000)

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       get_latitude = nint(siteLat*100000)
       return
       end
 
 
       function get_longitude()
       integer get_longitude         ! Site longitude (degrees * 100000)

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'

       get_longitude = nint(siteLon*100000)
       return
       end

       subroutine get_radarname(c4_radarname,istatus)

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
       character*4 c4_radarname

       c4_radarname = radarName
       call upcase(c4_radarname,c4_radarname)
       write(6,*)' c4_radarname = ',c4_radarname

       istatus = 1
       return
       end
       
 
       function get_field_num(c3_field)
       integer get_field_num
       character*3 c3_field
 
       if(c3_field .eq. 'DBZ')get_field_num = 1
       if(c3_field .eq. 'VEL')get_field_num = 2
 
       return
       end
 
 
       function read_radial()
 
       read_radial = 0
       return
       end
 
 
       function get_status()
       integer get_status
 
       get_status = 0
       return
       end
 
 
       function get_fixed_angle()
       integer get_fixed_angle     ! Beam tilt angle (degrees * 100)

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       get_fixed_angle = nint(elevationAngle * 100.)
       return
       end
 
 
       function get_scan()
       integer get_scan            ! Scan #

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       get_scan = elevationNumber
       return
       end
 
 
       function get_tilt()
       integer get_tilt            ! Tilt #

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       get_tilt = elevationNumber
       return
       end
 
 
       function get_num_rays()
       integer get_num_rays

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       get_num_rays = numRadials
       return
       end
 
 
       subroutine get_volume_time(i4time_process_ret)

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       i4time_process_ret = i4time_process
       return
       end
 
 
       function get_vcp()
       integer get_vcp

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       get_vcp = VCP
       return
       end
 
 
       function get_azi(iray) ! azimuth * 100.
       integer get_azi

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       get_azi = nint(radialAzim(iray)*100.)
       return
       end
 
 
       function get_nyquist()
       integer get_nyquist        ! Nyquist velocity of the radial (M/S*100)

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       get_nyquist = nint(r_nyquist*100.)
       return
       end
 
 
       function get_number_of_gates(index)
       integer get_number_of_gates
 
       get_number_of_gates = 0
       return
       end
 
 
       subroutine get_first_gate(index,first_gate_m,gate_spacing_m)

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       if(index .eq. 1)then
           first_gate_m = firstGateRangeZ
           gate_spacing_m = gateSizeZ
       elseif(index .eq. 2)then
           first_gate_m = firstGateRangeV
           gate_spacing_m = gateSizeV
       endif

       return
       end
 
 
       function get_data_field(index, data, n_ptr, n_gates
     1                                           , b_missing_data)
       integer get_data_field

       include 'remap_dims.inc'
       include 'netcdfio_radar_common.inc'
 
       real*4 data(n_gates)

       if(index .eq. 1)then ! reflectivity
           do i = 1,n_gates
               data(i) = Z(n_ptr + (i-1))

!              Convert from signed to unsigned
               if(data(i) .gt. 127.) then
                   print *, 'error in Reflectivity: ',i,data(i)
                   stop
               endif
               if(data(i) .lt. 0.) then
                   data(i) = 256. + data(i)
               endif

               if(data(i) .ne. b_missing_data)then ! Scale
                   data(i) = (data(i) - 2.)/2.0 - 32.
               endif

           enddo

       elseif(index .eq. 2)then ! velocity
           do i = 1,n_gates
               data(i) = V(n_ptr + (i-1))

!              Convert from signed to unsigned
               if(data(i) .gt. 127.) then
                   print *, 'error in Velocity: ',i,data(i)
                   stop
               endif
               if(data(i) .lt. 0.) then
                   data(i) = 256. + data(i)
               endif

               if(data(i) .eq. 1. .or. data(i) .eq. 0.)then 
                   data(i) = b_missing_data  ! Invalid Measurement
               endif

               if(resolutionV .eq. 0.)then ! QC Check
                   data(i) = b_missing_data
               endif

               if(data(i) .ne. b_missing_data)then ! Scale valid V
                   data(i) = (data(i) - 129.) * resolutionV
               endif

           enddo

       endif

       get_data_field = 1
       return
       end
 
 
       function cvt_fname_data()
 
       cvt_fname_data = 0
       return
       end
 
 
