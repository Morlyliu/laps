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
       subroutine read_wsi_cdf_wfo(input_name,lines,elems,
     1        Dx,Dy,valtime,image,istatus)
c
c       This routines reads the WSI NOWRAD netcdf files and
c        converts the image value to values of 0-15.
c
c       Mark E. Jackson            17-oct-1994
c       Linda Wharton              05-apr-1996
c         modified to use C version of scan_remap
c       J Smart                       sep-1996
c         modified to read conus-c nowrad netCDF data
c
c
        include 'netcdf.inc'
        include 'vrc.inc'
        character*128 dimname                   ! Must match NETCDF.INC's
        common/ncopts/ncopts                    ! NetCDF error handling flag.

        character*200 input_name
       
        integer varid,dimid,count(3),start(3)
        real*8 valtime
c       integer nrecs
c       parameter (nrecs=1)
     
        integer lines,elems
        integer image(nelems,nlines)   !,nrecs)

        integer bad_data_flag
        integer imax_image_value
        integer imin_image_value

        integer ilines,ielems
        integer istatus,cdfid
        integer attlen

        character c_atvalue*80
       
        integer icount_out,icount_bad

        real*4 Dx,Dy
 
        istatus = 0
        bad_data_flag=255
        call NCPOPT(0)

        istatus=NF_OPEN(input_name,NC_NOWRITE,cdfid)
        if (istatus .ne. 0)then
            write(*,*)' Error in opening netcdf file'
            write(*,*)' ...file not found.' 
            istatus = -1
            goto 9999 
        else
                write(*,*)' netcdf nldn file open'
        endif

        dimid = NCDID(cdfid,'x',istatus)
        CALL NCDINQ(cdfid,dimid,dimname,ielems,istatus)
        dimid = NCDID(cdfid,'y',status)
        CALL NCDINQ(cdfid,dimid,dimname,ilines,istatus)
c
c A little qc check to be sure we are reading the proper data file
c
        if(ilines.lt.nlines .or. ielems.lt.nelems)then
           write(6,*)'WARNING! '
           write(6,*)'n lines from file: ',ilines
           write(6,*)'n elems from file: ',ielems
           write(6,*)'n lines expected : ',nlines
           write(6,*)'n elems expected : ',nelems
        elseif(ilines.gt.nlines .or. ielems.gt.nelems)then
           write(6,*)'TERMINAL ERROR! '
           write(6,*)'n lines from file: ',ilines
           write(6,*)'n elems from file: ',ielems
           write(6,*)'n lines expected : ',nlines
           write(6,*)'n elems expected : ',nelems
           istatus = -1
           return
        else
           write(*,*)' Getting wsi netcdf data.. '
           write(6,*)'lines/elems from netCDF: ',ilines,ielems
        endif
 
        start(1) = 1
        start(2) = 1
        count(2) = ilines
        count(1) = ielems
        start(3) = 1
        count(3) = 1

        istatus=NF_INQ_VARID(cdfid,'image',varid)
        if(istatus.ne.0)then
           write(6,*)'Error getting varid - image'
           return
        endif
        istatus=NF_GET_VARA_INT(cdfid,varid,start,count,image)
        if(istatus.ne.0)then
           write(6,*)'Error reading variable - image'
           return
        endif

        istatus=NF_INQ_VARID(cdfid,'valtime',varid)
        if(istatus.ne.0)then
           istatus=NF_INQ_VARID(cdfid,'validTime',varid)
           if(istatus.ne.0)then
              write(6,*)'Error getting varid - valtime'
              return
           endif
        endif
           istatus=NF_GET_VAR1_DOUBLE(cdfid,varid,1,valtime)
        if(istatus.ne.0)then
           write(6,*)'Error reading variable - valtime'
           return
        endif

        istatus=NF_INQ_VARID(cdfid,'Dx',varid)
        if(istatus.ne.0)then
           write(6,*)'Error getting varid - Dx'
           return
        endif

        istatus=NF_GET_VAR1_REAL(cdfid,varid,1,Dx)
        if(istatus.ne.0)then
           write(6,*)'Error reading variable - Dx'
           return
        endif

        CALL NCAINQ(cdfid,varid,'units',itype,attlen,istatus)

        call NCAGTC(cdfid,varid,'units',c_atvalue,attlen,istatus)
        if(istatus.ne.0)then
           write(6,*)'Error getting attribute - Dx'
        endif

  
        istatus=NF_INQ_VARID(cdfid,'Dy',varid)
        if(istatus.ne.0)then
           write(6,*)'Error getting varid - Dy'
           return
        endif
        istatus=NF_GET_VAR1_REAL(cdfid,varid,1,Dy)
        if(istatus.ne.0)then
           write(6,*)'Error reading variable - Dy'
           return
        endif

        CALL NCAINQ(cdfid,varid,'units',itype,attlen,istatus)

        call NCAGTC(cdfid,varid,'units',c_atvalue,attlen,istatus)
        if(istatus.ne.0)then
           write(6,*)'Error getting attribute - Dy'
        endif

        if(c_atvalue(1:4).eq.'kilo')then
           Dx=Dx*1000.
           Dy=Dy*1000.
        endif

          Write(*,*)' closing netcdf file'
           istatus= NF_CLOSE(cdfid)
c
c for wfo data we must first rescale the values back to the original
c wsi form to properly convert to dbz.
c
      imax_image_value = 0
      imin_image_value = 255
      icount_bad=0
      icount_out=0

      do j=1,lines
         do i=1,elems
            if(image(i,j).lt.0)then
               image(i,j)=127-image(i,j)
            else
               image(i,j)=image(i,j)/16
            endif

            if(image(i,j) .gt. imax_image_value)
     +           imax_image_value = image(i,j)
            if(image(i,j) .lt. imin_image_value)
     +           imin_image_value = image(i,j)
            if(image(i,j) .ge. bad_data_flag)then
               icount_bad=icount_bad+1
               image(i,j) = bad_data_flag
            endif
  
            if((image(i,j).ge.16).or.(image(i,j).lt.0))then
               image(i,j)=bad_data_flag
c              write(6,*) i, j, i_value
            endif

         enddo
      enddo
c
      write(6,*)'Number of bad data points (> ',bad_data_flag,' )'
      write(6,*)'prior to calling c_scan_adjust: ',icount_bad
      write(6,*)'Max value found in image array: ',imax_image_value
      write(6,*)'Min value found in image array: ',imin_image_value
      write(6,*)
      write(6,*)'Data found out-of-bounds (icount_out) ',icount_out
      if(icount_out.gt.0)then
         status = -1
         return
      endif


C  new C version of scan_adjust implemented 05-apr-96
ccc      call c_scan_adjust(image,lines,elems,bad_data_flag)
c     do j=1,lines
c        do i=1,elems
c           if(image(i,j).ne.bad_data_flag)
c    +         image(i,j)=mod(image(i,j),16)
cc     +           image(i,j)=modulo(image(i,j),16)
c        enddo
c     enddo


9999  return
      end
