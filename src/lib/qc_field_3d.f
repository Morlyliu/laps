

      subroutine qc_field_3d(var_2d,field_3d,ni,nj,nk,istatus)

      character(*) var_2d

      real*4 field_3d(ni,nj,nk)

      if(var_2d .eq. 'U3' .or. var_2d .eq. 'V3')then
          lower_bound = -200.
          upper_bound = +200.
      elseif(var_2d .eq. 'T3')then
          lower_bound = +173.
          upper_bound = +400.
      else
          lower_bound = -1e10
          upper_bound = +1e10
      endif

      call get_r_missing_data(r_missing_data,istatus)
      if(istatus .ne. 1)return

      do k=1,nk
      do j=1,nj
      do i=1,ni
          if(field_3d(i,j,k) .eq. r_missing_data)then
              write(6,*)' QC Error detected in ',var_2d,' at ',i,j,k
              write(6,*)' Value equals r_missing_data or '
     1                 ,r_missing_data      
              istatus = 0
              return
          endif

          if(field_3d(i,j,k) .gt. upper_bound)then
              write(6,*)' QC Error detected in ',var_2d,' at ',i,j,k
              write(6,*)' Value exceeded upper bound of '
     1                 ,upper_bound,', value = ',field_3d(i,j,k)       
              istatus = 0
              return
          endif

          if(field_3d(i,j,k) .lt. lower_bound)then
              write(6,*)' QC Error detected in ',var_2d,' at ',i,j,k
              write(6,*)' Value exceeded lower bound of '
     1                 ,lower_bound,', value = ',field_3d(i,j,k)       
              istatus = 0
              return
          endif

      enddo ! i
      enddo ! j
      enddo ! k

      istatus = 1
  
      return
      end 
