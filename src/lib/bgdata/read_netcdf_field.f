      subroutine read_netcdf_real(nf_fid,fname,n1,f,istatus)
      include 'netcdf.inc'
      include 'bgdata.inc'
      implicit none

      integer n1,i, nf_fid, nf_vid,istatus,nf_status
      real f(n1) , nfmissing
      character*(*) fname

      istatus=0
      nf_status = NF_INQ_VARID(nf_fid,fname,nf_vid)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in var ', fname
        istatus = 1
        return
      endif

      nf_status = NF_GET_VAR_REAL(nf_fid,nf_vid,f)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
        print *,'in NF_GET_VAR_ ', fname
        istatus = 1
        return
      endif

      nf_status = NF_GET_ATT_REAL(nf_fid,nf_vid,'_FillValue',nfmissing)
      if(nf_status.ne.NF_NOERR) then
        print *, NF_STRERROR(nf_status)
      endif
      do i=1,n1
         if(f(i).eq.nfmissing) then
            f(i)=missingflag
            istatus=istatus-1
         endif
      enddo
      
      return
      end
