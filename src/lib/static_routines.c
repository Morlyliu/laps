#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "netcdf.h"

#define SYSCMD "ncgen -o %s %s"
#define LAT "lat"
#define LON "lon"

#ifdef FORTRANCAPS
#define read_cdf_static READ_CDF_STATIC
#define write_cdf_static WRITE_CDF_STATIC
#endif

#ifdef FORTRANUNDERSCORE
#define cdf_update_stat cdf_update_stat_
#define free_static_malloc free_static_malloc_
#define cdf_wrt_hdr_stat cdf_wrt_hdr_stat_
#define write_cdf_static write_cdf_static_
#define cdf_retr_grid_stat cdf_retr_grid_stat_
#define cdf_retr_hdr_stat cdf_retr_hdr_stat_
#define read_cdf_static read_cdf_static_
#define open_cdf open_cdf_
#define cdf_dim_size cdf_dim_size_
#define log_diag log_diag_
#define nstrncpy nstrncpy_
#define fstrncpy fstrncpy_
#endif

/*****************************************************************************
* CDF_UPDATE_STAT
*	Category		Product Management
*	Group			General Purpose Database
*	Module			Update the LAPS netCDF static file 
*	Purpose			To coordinate the writing of static info into
*				  the appropriate netCDF file: find the 
*				  appropriate location to write the grid, 
*				  and call the routine that does the writing.
*
*	Designer/Programmer : MarySue Schultz
*	Modifications : original 9/5/90
*			adapted for new WRITELAPSDATA 1/93 Linda Wharton
*			adapted from CDF_UPDATE_LAPS for new 
*			  WRT_LAPS_STATIC 4/93 Linda Wharton
*
*	Input :
*		s_field		A character string identifying the field:
*				    lat		latitude of grid point
*				    lon		longitude of grid point
*				    avg		average elev MSL of grid box
*				    std		std dev of elev's in box
*				    env  	avg + std
*				    zin		avg converted to mb pressure,
*						  then mapped 1100=0 to 100=20
*		gptr		A pointer to the grid (including product and data
*						headers).
*	Output :
*		None
*	Globals :		
*		NC_WRITE	A flag used to open the netCDF file for writing
*	Returns :
*		 0 if successful
*		-1 if an error occurs
***************************************************************************/
#ifdef __STDC__
int cdf_update_stat (int i_cdfid,int i_varid, char *s_field,char *gptr,
                     char *commnt, char *comm_ptr)
#else
int cdf_update_stat (i_cdfid, i_varid, s_field, gptr, commnt, comm_ptr)
int i_cdfid;
int i_varid;
char *s_field;
char *gptr;
char *commnt;
char *comm_ptr;
#endif
{
	int i_status, i_comid;
#ifdef __alpha
	long start[4], count[4], start_c[3], count_c[3];
#else
	int start[4], count[4], start_c[3], count_c[3];
#endif

	log_diag (2, "cdf_update_stat:grid name = %s\n", s_field);

/* turn off the error handling done by the netCDF routines */
        ncopts = NC_VERBOSE;

/* get the x and y dimension sizes */
        count[0] = 1;
        count[1] = 1;
	count[2] = cdf_dim_size (i_cdfid, "y");
	count[3] = cdf_dim_size (i_cdfid, "x");

/* construct the arrays needed by the netcdf write routine */
	start[0] = 0;
	start[1] = 0;
	start[2] = 0;
	start[3] = 0;

	start_c[0] = 0;
	start_c[1] = 0;
	start_c[2] = 0;
	count_c[0] = 1;
	count_c[1] = 1;
	count_c[2] = strlen(comm_ptr);

/* get the variable ids */
	log_diag (2, "Data variable name = %s\n", s_field);
	if ((i_comid = ncvarid (i_cdfid, commnt)) == (-1))
		return -1;

/* write the grid to the netcdf file */
	i_status = ncvarput (i_cdfid, i_varid, (const long *)start, 
                             (const long *)count, (void *)gptr);
	
	if (i_status == (-1)) {
		log_diag (1, "cdf_update_stat: error during cdf write\n");
		return -1;
	}
	else {
	  i_status = ncvarput (i_cdfid, i_comid, (const long *)start_c, 
                               (const long *)count_c, (void *)comm_ptr);
	  
	  if (i_status == (-1))
		log_diag (1, "cdf_update_stat: error during cdf write\n");
	  else
		log_diag (2, "cdf_update_stat: cdf write ok\n");
	}

	return i_status;
}
/*************************************************************************
*       FREE_STATIC_MALLOC
*       Category        Product Management
*       Group           General Purpose Database
*       Module          Write Static Grid data 
*       Purpose         Frees memory mallocd within write_cdf_static
*
*       Designer/Programmer : Linda Wharton
*       Modifications : original 7/97
*
*       Input:
*               prefix     String variable mallocd in write_cdf_static
*               comm_var   String variable mallocd in write_cdf_static
*               model      String variable mallocd in write_cdf_static
*               asctime    String variable mallocd in write_cdf_static
*               var        String variable mallocd in write_cdf_static
*               comment    String variable mallocd in write_cdf_static
*               fname      String variable mallocd in write_cdf_static
*       Output:
*               none
*       Globals:
*               none
*       Returns:
*               none
*****************************************************************************/
#ifdef __STDC__
        free_static_malloc(char *prefix, char *comm_var, char *model,
                           char *asctime, char *var, char *comment,
                           char *units, char *fname)
#else
        free_static_malloc(prefix, comm_var, model, asctime, var, 
                           comment, units, fname)
char *prefix; 
char *comm_var;
char *model;
char *asctime;
char *var;
char *comment;
char *units;
char *fname;
#endif

{
        if(prefix != NULL) free(prefix);
        if(comm_var != NULL) free(comm_var);
        if (model != NULL) free(model);
        if(asctime != NULL) free(asctime);
        if(var != NULL) free(var);
        if(comment != NULL) free(comment);
        if(units != NULL) free(units);
        if(fname != NULL) free(fname);
        return;
}
/*************************************************************************
*	CDF_WRT_HDR_STAT
*	Category	Product Management
*	Group		General Purpose Database
*	Module		Write header data
*	Purpose		Write header data into netCDF static file.
*
*	Designer/Programmer : Linda Wharton
*	Modifications : original 7/97
*
*	Input:
*               cdf_id          netCDF id of open file to write to
*		n_grids		Number of grids available in file  
*		grid_spacing	size of grid box in METERS
*		asctime		Ascii time file was generated
*		model		Model generating static data
*		Nx		X dimension of data in file
*		Ny		Y dimension of data in file
*               Dx		delta X in km of grid 
*               Dy              delta Y in km of grid
*               LoV             standard longitude
*               Latin1          first standard latitude
*               Latin2          second standard latitude
*               origin          site where LAPS being run
*               map_proj	map projection
*	Output:
*		none
*	Globals:
*		none
*	Returns:
*		status		Returns status to calling subroutine
**************************************************************************/
#ifdef __STDC__
#ifdef __alpha
int cdf_wrt_hdr_stat(int cdf_id, int *n_grids, float *grid_spacing,
                     char *asctime, char *model, int *nx, int *ny,
                     float *dx, float *dy, float *la1, float *lo1, 
                     float *lov, float *latin1, float *latin2, 
                     char *origin, char *map_proj, double unixtime,
                     int *status)
#else
int cdf_wrt_hdr_stat(int cdf_id, long *n_grids, float *grid_spacing,
                     char *asctime, char *model, long *nx, long *ny,
                     float *dx, float *dy, float *la1, float *lo1, 
                     float *lov, float *latin1, float *latin2, 
                     char *origin, char *map_proj, double unixtime,
                     long *status)
#endif
#else
#ifdef __alpha
int cdf_wrt_hdr_stat(cdf_id, n_grids, grid_spacing, asctime, model, nx, 
                     ny, dx, dy, la1, lo1, lov, latin1, latin2, origin, 
                     map_proj, unixtime, status)
int cdf_id; 
int *n_grids; 
float *grid_spacing;
char *asctime; 
char *model; 
int *nx; 
int *ny;
float *dx; 
float *dy; 
float *la1;
float *lo1;
float *lov; 
float *latin1;
float *latin2; 
char *origin; 
char *map_proj;
double unixtime;
int *status;
#else
int cdf_wrt_hdr_stat(cdf_id, n_grids, grid_spacing, asctime, model, nx, 
                     ny, dx, dy, la1, lo1, lov, latin1, latin2, origin, 
                     map_proj, unixtime, status)
int cdf_id; 
long *n_grids; 
float *grid_spacing;
char *asctime; 
char *model; 
long *nx; 
long *ny;
float *dx; 
float *dy; 
float *la1;
float *lo1;
float *lov; 
float *latin1;
float *latin2; 
char *origin; 
char *map_proj;
double unixtime;
long *status;
#endif
#endif
{

    int i_varid;
    long start[1], edges[1];
    long start_map[2], edges_map[2];
    short nx_in, ny_in;
    const long zero = 0L;

/* store n_grids */
    if ((i_varid = ncvarid (cdf_id, "n_grids")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }

    ncvarput1(cdf_id, i_varid, (const long *) &zero, (void *)n_grids);

/* store imax */
    if ((i_varid = ncvarid (cdf_id, "imax")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput1(cdf_id, i_varid, (const long *) &zero, (void *)nx);

/* store jmax */
    if ((i_varid = ncvarid (cdf_id, "jmax")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput1(cdf_id, i_varid, (const long *) &zero, (void *)ny);

  /* store grid_spacing */
    if ((i_varid = ncvarid (cdf_id, "grid_spacing")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput1(cdf_id, i_varid, (const long *) &zero, (void *)grid_spacing);
      
    start[0] = 0;

/* store asctime */
    edges[0] = strlen(asctime);
    if ((i_varid = ncvarid (cdf_id, "asctime")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput(cdf_id, i_varid, (const long *)start, (const long *)edges, 
             (void *)asctime);
 
  /* store model */
    edges[0] = strlen(model);
    if ((i_varid = ncvarid (cdf_id, "process_name")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }

    ncvarput(cdf_id, i_varid, start, edges, (void *)model);

    edges[0] = 1;
/* store Nx */
    if ((i_varid = ncvarid (cdf_id, "Nx")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    nx_in = (short)*nx;
    ncvarput(cdf_id, i_varid, start, edges, (void *)&nx_in);
      
/* store Ny */
    if ((i_varid = ncvarid (cdf_id, "Ny")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ny_in = (short)*ny;
    ncvarput(cdf_id, i_varid, start, edges, (void *)&ny_in);
      
/* store Dx */
    if ((i_varid = ncvarid (cdf_id, "Dx")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput(cdf_id, i_varid, start, edges, (void *)dx);
      
/* store Dy */
    if ((i_varid = ncvarid (cdf_id, "Dy")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput(cdf_id, i_varid, start, edges, (void *)dy);
      
/* store La1 */
    if ((i_varid = ncvarid (cdf_id, "La1")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput(cdf_id, i_varid, start, edges, (void *)la1);
      
/* store Lo1 */
    if ((i_varid = ncvarid (cdf_id, "Lo1")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput(cdf_id, i_varid, start, edges, (void *)lo1);
      
/* store LoV */
    if ((i_varid = ncvarid (cdf_id, "LoV")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput(cdf_id, i_varid, start, edges, (void *)lov);
      
/* store Latin1 */
    if ((i_varid = ncvarid (cdf_id, "Latin1")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput(cdf_id, i_varid, start, edges, (void *)latin1);

/* store Latin2 */
    if ((i_varid = ncvarid (cdf_id, "Latin2")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput(cdf_id, i_varid, start, edges, (void *)latin2);

/* store valtime */
    if ((i_varid = ncvarid (cdf_id, "valtime")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput(cdf_id, i_varid, start, edges, (void *)&unixtime);

/* store reftime */
    if ((i_varid = ncvarid (cdf_id, "reftime")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }
    ncvarput(cdf_id, i_varid, start, edges, (void *)&unixtime);

/* store origin */
    edges[0] = strlen(origin);
    if ((i_varid = ncvarid (cdf_id, "origin_name")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }

    ncvarput(cdf_id, i_varid, start, edges, (void *)origin);

/* store map_proj */
    start_map[0] = 0;
    start_map[1] = 0;
    edges_map[0] = 1;
    edges_map[1] = strlen(map_proj);
    if ((i_varid = ncvarid (cdf_id, "grid_type")) == (-1)) {
      *status = -5;	/* returns "error writing header" */
      return;
    }

    ncvarput(cdf_id, i_varid, start_map, edges_map, (void *)map_proj);

    return 0;
}
/*************************************************************************
*	WRITE_CDF_STATIC
*	Category	Product Management
*	Group		General Purpose Database
*	Module		Write Grid data
*	Purpose		Write grid data into netCDF static file.
*
*	Designer/Programmer : Linda Wharton
*	Modifications : original 4/93
*
*	Input:
*		filname		NetCDF filename to open
*		asctime		Ascii time of file
*		var		Array of LAPS variables to write out
*		comment		Comments for each level to write
*		imax		X dimension of data in file
*		jmax		Y dimension of data in file
*		n_grids		Number of grids available in file & 
*		 		  dimension  of the VAR and COMMENT
*				  in the calling program
*		data		3D grid containing data to write
*		zin		Grid for AVS applications
*		model		Model generating static data
*		grid_spacing	size of grid box in M
*	Output:
*		status		Returns status to calling subroutine
*	Globals:
*		none
*	Returns:
*		none
*****************************************************************************/
#ifdef __STDC__
#ifdef __alpha
void write_cdf_static(char *filname, short *s_length, char *f_asctime,
                      char *f_cdl_dir, int *cdl_len, char *f_var, int *var_len,
                      char *f_comment, int *com_len, char *f_ldf,
                      int *ldf_len, int *imax, int *jmax, int *n_grids,
                      int *nx_lp, int *ny_lp, float *data, char *f_model, 
                      float *grid_spacing, float *dx, float *dy, float *lov, 
                      float *latin1, float *latin2, char *f_origin, 
                      int *origin_len, char *f_map_proj, int *map_len, 
                      int *unixtime, int *status)
#else
void write_cdf_static(char *filname, short *s_length, char *f_asctime,
                      char *f_cdl_dir, long *cdl_len, char *f_var, long *var_len,
                      char *f_comment, long *com_len, char *f_ldf,
                      long *ldf_len, long *imax, long *jmax, long *n_grids,
                      long *nx_lp, long *ny_lp, float *data, char *f_model, 
                      float *grid_spacing, float *dx, float *dy, float *lov, 
                      float *latin1, float *latin2, char *f_origin, 
                      long *origin_len, char *f_map_proj, long *map_len, 
                      long *unixtime, long *status)
#endif
#else
#ifdef __alpha
void write_cdf_static(filname, s_length, f_asctime, f_cdl_dir, cdl_len,
                      f_var, var_len, f_comment, com_len, f_ldf, ldf_len,
                      imax, jmax, n_grids, nx_lp, ny_lp, data, f_model, 
                      grid_spacing, dx, dy, lov, latin1, latin2, f_origin, 
                      origin_len, f_map_proj, map_len, unixtime, status)
char *filname;
short *s_length;
char *f_asctime;
char *f_cdl_dir;
int *cdl_len;
char *f_var;
int *var_len;
char *f_comment;
int *com_len;
char *f_ldf;
int *ldf_len;
int *imax;
int *jmax;
int *n_grids;
int *nx_lp;
int *ny_lp;
float *data;
char *f_model;
float *grid_spacing;
float *dx;
float *dy;
float *lov;
float *latin1;
float *latin2;
char *f_origin;
int *origin_len;
char *f_map_proj;
int *map_len;
int *unixtime;
int *status;
#else
void write_cdf_static(filname, s_length, f_asctime, f_cdl_dir, cdl_len,
                      f_var, var_len, f_comment, com_len, f_ldf, ldf_len,
                      imax, jmax, n_grids, nx_lp, ny_lp, data, f_model, 
                      grid_spacing, dx, dy, lov, latin1, latin2, f_origin, 
                      origin_len, f_map_proj, map_len, unixtime, status)

char *filname;
short *s_length;
char *f_asctime;
char *f_cdl_dir;
long *cdl_len;
char *f_var;
long *var_len;
char *f_comment;
long *com_len;
char *f_ldf;
long *ldf_len;
long *imax;
long *jmax;
long *n_grids;
long *nx_lp;
long *ny_lp;
float *data;
char *f_model;
float *grid_spacing;
float *dx; 
float *dy;
float *lov;
float *latin1;
float *latin2;
char *f_origin;
long *origin_len;
char *f_map_proj;
long *map_len;
long *unixtime;
long *status;
#endif
#endif
{

	char *prefix, *comm_var, *model, *asctime, *fname, *map_proj;
	char *var, *comment, *ldf, *p_var, *pf_var, *p_com, *pf_com;
        char *origin, *units;
	int mod_len, asc_len, c_var_len, c_com_len;
	int out_file, istat, i_varid, i, process_vr, count;
        int lat_index, lon_index, hdr_status;
        int xdimid, ydimid;
        static char *syscmd, *cdlfile;
        float la1, lo1;
        double d_unixtime;
#ifdef __alpha
        int nx_cdl, ny_cdl;
#else
        long nx_cdl, ny_cdl;
#endif

/* turn off the error handling done by the netCDF routines */
        ncopts = NC_VERBOSE;

/* malloc space for c-strings */
        c_var_len = *var_len + 1;
	prefix = malloc(c_var_len * sizeof(char));
	comm_var = malloc((c_var_len+8) * sizeof(char));
        mod_len = strlen(f_model);
	model = malloc(((mod_len)+1) * sizeof(char));
        asc_len = strlen(f_asctime);
	asctime = malloc(((asc_len)+1) * sizeof(char));
        map_proj = malloc(((*map_len)+1) * sizeof(char));
        origin = malloc(((*origin_len)+1) * sizeof(char));
        var = malloc(c_var_len * (*n_grids) * sizeof(char));
        c_com_len = *com_len + 1;
	comment = malloc(c_com_len * (*n_grids) * sizeof(char));
	fname = malloc(((*s_length)+1) * sizeof(char));

/* convert fortran string f_var to c string var */
 
        for (i = 0; i < *n_grids; i++) {
          p_var = var + (i * c_var_len);
          pf_var = f_var + (i * (*var_len));
          nstrncpy(p_var, pf_var, *var_len);
          downcase_c(p_var,p_var);
          p_com = comment + (i * c_com_len);
          pf_com = f_comment + (i * (*com_len));
          fstrncpy(p_com,pf_com, *com_len);
        }

        fstrncpy(model,f_model,mod_len);
        fstrncpy(asctime,f_asctime,asc_len);
        fstrncpy(map_proj,f_map_proj,*map_len);
        fstrncpy(origin,f_origin,*origin_len);

/* convert fortran file_name into C fname  */
        nstrncpy(fname,filname,s_length);

/* allocate space for syscmd and cdlfile and fill up */
        /* cdl file contains domain name + ".cdl\0" */
        cdlfile = malloc(((*cdl_len)+(*ldf_len)+5) * sizeof(char));
        nstrncpy(cdlfile,f_cdl_dir,*cdl_len);
        ldf = malloc(((*ldf_len) + 1) * sizeof(char));
        nstrncpy(ldf,f_ldf,*ldf_len);
        strcat(cdlfile,ldf,*ldf_len);
        free(ldf);
        strcat(cdlfile,".cdl");
        *cdl_len = strlen(cdlfile);
 
        /* SYSCMD contains "ncgen -o %s %s\0" which
           is 16 char, cdlfile, and fname  + 10 extra  */
        syscmd = malloc((strlen(SYSCMD)+*cdl_len+*s_length+10) * sizeof(char));
        sprintf(syscmd,SYSCMD, fname, cdlfile);
        free(cdlfile);
 
/* create output file */
        system(syscmd);
        free(syscmd);
        out_file = ncopen(fname,NC_WRITE);
        if (out_file == -1) {
          *status = -2; /* error in file creation */
          free_static_malloc(prefix, comm_var, model, asctime, var, 
                             comment, NULL, fname);
          return;
        }

/* get x and y dimensions from output file and make sure they are the same
   as nx_lp and ny_lp  */
        xdimid = ncdimid(out_file,"x");
        ydimid = ncdimid(out_file,"y");
        ncdiminq(out_file,xdimid, (char *) 0, &nx_cdl);
        ncdiminq(out_file,ydimid, (char *) 0, &ny_cdl);

        if ((nx_cdl == *nx_lp) && (ny_cdl == *ny_lp)) {
        } else
        {
          *status = -6; /* nest7grid.cdl & nest7grid.parms disagree */
          free_static_malloc(prefix, comm_var, model, asctime, var, 
                             comment, NULL, fname);
          return;
        }

/* get La1 and Lo1 (first lat and lon) from data array */
        lat_index = -1; 
        lon_index = -1;
        for (i = 0; i < *n_grids; i++) {
          p_var = var + (i * c_var_len);
          if (strcmp(p_var, LAT) == 0) lat_index = i;
          if (strcmp(p_var, LON) == 0) lon_index = i;
        }

        if (lat_index == (-1)) {
          la1 = -999.99;
        }
        else {
          la1 = *(data + (lat_index*(*imax)*(*jmax)));
          if (la1 < 0.0) la1 = 360.0 + la1;
        }

        if (lon_index == (-1)) {
          lo1 = -999.99;
        }
        else {
          lo1 = *(data + (lon_index*(*imax)*(*jmax)));
          if (lo1 < 0.0) lo1 = 360.0 + lo1;
        }

/* write header info to output file */
        d_unixtime = (double)*unixtime;
        hdr_status = cdf_wrt_hdr_stat(out_file, n_grids, grid_spacing, 
                                      asctime, model, imax, jmax, dx, dy, 
                                      &la1, &lo1, lov, latin1, latin2, 
                                      origin, map_proj,d_unixtime, status);
        if (hdr_status != 0) {
          *status = hdr_status;
          free_static_malloc(prefix, comm_var, model, asctime, var,
                             comment, NULL, fname);
          return;
        }

/* write data to grid and write out comment */
	count = 0;
        for (i = 0; i < *n_grids; i++) {
          p_var = var + (i * c_var_len);
          p_com = comment + (i * c_com_len);
          strcpy(prefix,p_var);
          strcpy(comm_var,p_var);
          strcat(comm_var,"_comment");
	  if ((i_varid = ncvarid (out_file , prefix)) == (-1)) {
	    printf("write_cdf_static: no variable %s in file.\n", prefix);
          }
          else {
            istat = cdf_update_stat(out_file,i_varid, prefix,
               	 		    (void *)(data + (i*(*imax)*(*jmax))),
                	 	    comm_var,p_com);
            if (istat == -1) {
              *status = -4;
              ncclose(out_file);
              return;
            }
            count++;
          }
        }
        
        *status = count;  /* returns number of grids written */
        
        ncclose(out_file);          	
        return;
}
/*****************************************************************************
*	CDF_RETR_GRID_STAT
*	Category		Product Management
*	Group			General Purpose Database
*	Module			Retrieve Grid Data
*	Purpose			To retrieve a specified grid from a netcdf file
*
*	Designer/Programmer : MarySue Schultz
*	Modifications : original 9/12/90
*			modified for new READLAPSDATA 1/93 Linda Wharton
*
*	Input :
*		i_cdfid		NetCDF file id for file to be read
*		s_field		A character string identifying the field
*		gptr		Pointer to location in data array to write data.
*		cptr		Pointer to location in data array to write comments
*		uptr		Pointer to location in data array to write units.
*	Output :
*		none
*	Globals:
*		NC_NOWRITE	A NetCDF global that opens the NetCDF file for reading
*						only.
*	Returns:
*		0 if normal return
*		-1 if an error occurs
*****************************************************************************/

#ifdef __STDC__
int cdf_retr_grid_stat(int i_cdfid, int i_varid, char *s_field, float *gptr,
		       char *cptr, int c_com_len, char *uptr,
                       int c_unit_len)
#else
int cdf_retr_grid_stat(i_cdfid, i_varid, s_field, gptr, cptr, c_com_len, 
                       uptr, c_unit_len)

int i_cdfid;
int i_varid;
char *s_field;
float *gptr;
char *cptr;
int c_com_len;
char *uptr;
int c_unit_len;
#endif
{
	int i_status, j;
        char units[132], *p_unit;
#ifdef __alpha
	long start[4],count[4],start_c[3],count_c[3];
#else
	int start[4],count[4],start_c[3],count_c[3];
#endif
	char var_name[13];

/*	printf("cdf_ret_grd: level = %d   fctime = %d   field = %s\n",
		i_level, i_fctime, s_field);  */

/* turn off the error handling done by the netCDF routines */
	ncopts = NC_VERBOSE;

/* get the x and y dimension sizes */
        count[0] = 1;
        count[1] = 1;
        count[2] = cdf_dim_size (i_cdfid, "y");
        count[3] = cdf_dim_size (i_cdfid, "x");
        start[0] = 0;
        start[1] = 0;
        start[2] = 0;
        start[3] = 0;

/* read the grid from the netcdf file */
	i_status = ncvarget (i_cdfid, i_varid, (const long *)start, 
                             (const long *)count, (void *)gptr);

	if (i_status == (-1)) {
	   printf("cdf_retrieve_laps: error retrieving data %s grid.\n", 
		 	 *s_field);
	   return -1;
	}

/* retrieve units */
	i_status = ncattget (i_cdfid, i_varid, "LAPS_units", units);
	if (i_status == (-1)) {
	   printf("cdf_retrieve_laps: error retrieving LAPS_units.\n");
	   return -1;
	}
        strncpy(uptr,units,(c_unit_len-1));
        p_unit = uptr + c_unit_len - 1;
        p_unit = '\0';

/* setup to read the comment from the netcdf file */

	sprintf(var_name, "%s%s", s_field, "_comment");	
	if ((i_varid = ncvarid (i_cdfid, var_name)) == (-1)) {
	   printf("cdf_retrieve_laps: no comment field available.\n");
	   return -1;
	}

/* construct the arrays needed to read the grid */
	start_c[0] = 0;
	start_c[1] = 0;
	start_c[2] = 0;
	count_c[0] = 1;
	count_c[1] = 1;
	count_c[2] = c_com_len;
	i_status = ncvarget (i_cdfid, i_varid, (const long *)start_c, 
                             (const long *)count_c, (void *)cptr);

	if (i_status == (-1)) {
	   printf("cdf_retrieve_laps: error retrieving comment.\n");
	   return -1;
	}
	   
/* normal return */

	return 0;
}
/*****************************************************************************
*	CDF_RETR_HDR_STAT
*	Category		Product Management
*	Group			General Purpose Database
*	Module			Retrieve Static Grid
*	Purpose			To retrieve header info from a netcdf file
*
*	Designer/Programmer : Linda Wharton
*	Modifications : original 4/93
*
*	Input :
*		i_cdfid		NetCDF file id for file to be read
*	Output :
*		imaxn		number of x gridpoints
*		jmaxn		number of y gridpoints
*		kmaxn		number of grids in the file
*		laps_dom_file	name of laps domain for this file
*	Globals:
*		NC_NOWRITE	A NetCDF global that opens the NetCDF file for
*				    reading only.
*	Returns:
*		-1 if an error occurs
*****************************************************************************/

#ifdef __STDC__
#ifdef __alpha
int cdf_retr_hdr_stat(int i_cdfid,int *imaxn, int *jmaxn, int *n_grids_n,
		      float *grid_spacing_n)
#else
int cdf_retr_hdr_stat(int i_cdfid,long *imaxn, long *jmaxn, long *n_grids_n,
		      float *grid_spacing_n)
#endif
#else
#ifdef __alpha
int cdf_retr_hdr_stat(i_cdfid,imaxn,jmaxn,n_grids_n,grid_spacing_n)
int i_cdfid;                               
int *imaxn;
int *jmaxn;
int *n_grids_n;
float *grid_spacing_n;
#else
int cdf_retr_hdr_stat(i_cdfid,imaxn,jmaxn,n_grids_n,grid_spacing_n)
int i_cdfid;                               
long *imaxn;
long *jmaxn;
long *n_grids_n;
float *grid_spacing_n;
#endif
#endif
{
	int i_status, i_varid, i, temp, str_len;
#ifdef __alpha
        long mindex[1], start[1], count_asc[1], count_long[1];
#else
        int mindex[1], start[1], count_asc[1], count_long[1];
#endif
	static char c_ver[5];
	char *t_ptr;

/* turn off the error handling done by the netCDF routines */
	ncopts = NC_VERBOSE;

	mindex[0] = 0;
	start[0] = 0;
	count_asc[0] = 18;
	count_long[0] = 132;
	
/* get the data variable id */
	log_diag (2, "cdf_read_grid: data variable name = %s\n", "imax");
	if ((i_varid = ncvarid (i_cdfid, "imax")) == (-1))
		return -1;

/* read the var from the netcdf file */
	i_status = ncvarget1 (i_cdfid, i_varid, (const long *)mindex, 
                              (void *)imaxn);
	if (i_status == (-1))
	   return -1;

/* get the data variable id */
	log_diag (2, "cdf_read_grid: data variable name = %s\n", "jmax");
	if ((i_varid = ncvarid (i_cdfid, "jmax")) == (-1))
		return -1;

/* read the var from the netcdf file */
	i_status = ncvarget1 (i_cdfid, i_varid, (const long *)mindex, 
                              (void *)jmaxn);
	if (i_status == (-1))
	   return -1;

/* get the data variable id */
	log_diag (2, "cdf_read_grid: data variable name = %s\n", "n_grids");
	if ((i_varid = ncvarid (i_cdfid, "n_grids")) == (-1))
		return -1;

/* read the var from the netcdf file */
	i_status = ncvarget1 (i_cdfid, i_varid, (const long *)mindex, 
                              (void *)n_grids_n);
	if (i_status == (-1))
	   return -1;

/* get the data variable id */
	log_diag (2, "cdf_read_grid: data variable name = %s\n",
		  "grid_spacing");
	if ((i_varid = ncvarid (i_cdfid, "grid_spacing")) == (-1))
		return -1;

/* read the var from the netcdf file */
	i_status = ncvarget1 (i_cdfid, i_varid, (const long *)mindex, 
                              (void *)grid_spacing_n);
	if (i_status == (-1))
	   return -1;

/* normal return */

	return 0;
}

/*************************************************************************
*	READ_CDF_STATIC
*	Category	Product Management
*	Group		General Purpose Database
*	Module		write_cdf-Read_cdf_file
*	Purpose		Read LAPS data from netCDF format static file.
*
*	Designer/Programmer : Linda Wharton
*	Modifications : original 4/93
*
*	Input:
*		filname		NetCDF filename to open
*               s_length 	length of the filname string
*		f_var		Array of static variables to retrieve 
*               var_len		length of one f_var string
*               f_comment	Array to hold comment info retrieved
*               com_len		length of one f_comment string
*		f_units		Array to hold units info retrieved
*               unit_len	length of one f_units string
*		imax      	Expected X dimension of data
*		jmax      	Expected Y dimension of data
*		n_grids		Dimension  of the f_var, comment,
*		data		3D grid containing data requested
*				  otherwise contains 0
*				  and units arrays in the calling program
*	Output:
*		imax_n		Actual X dimension of data in file
*		jmax_n		Actual Y dimension of data in file
*		status		Returns status to calling subroutine
*	Globals:
*		none
*	Returns:
*		count of requested variables that were not retrieved
*************************************************************************/
#ifdef __STDC__
#ifdef __alpha
void read_cdf_static(char *filname, short *s_length,char *f_var,
		     int *var_len, char *f_comment,int *com_len, 
                     char *f_units, int *unit_len, int *imax,int *jmax,
		     int *n_grids,float *data,float *grid_spacing,
		     int *no_laps_diag,int *status)
#else
void read_cdf_static(char *filname, short *s_length,char *f_var,
		     long *var_len, char *f_comment, long *com_len,
                     char *f_units,long *unit_len, long *imax,long *jmax,
		     long *n_grids,float *data,float *grid_spacing,
		     long *no_laps_diag,long *status)
#endif
#else
#ifdef __alpha
void read_cdf_static(filname,s_length,f_var,var_len,f_comment,com_len,
                     f_units,unit_len,imax,jmax, n_grids,data,
                     grid_spacing,no_laps_diag,status)
char *filname;
short *s_length;
char *f_var;
int *var_len;
char *f_comment;
int *com_len;
char *f_units;
int *unit_len;
int *imax;
int *jmax;
int *n_grids;
float *data;
float *grid_spacing;
int *no_laps_diag;
int *status;
#else
void read_cdf_static(filname,s_length,f_var,var_len,f_comment,com_len,
                     f_units,unit_len,imax,jmax, n_grids,data,
                     grid_spacing,no_laps_diag,status)
char *filname;
short *s_length;
char *f_var;
int *var_len;
char *f_comment;
int *com_len;
char *f_units;
int *unit_len;
long *imax;
long *jmax;
long *n_grids;
float *data;
float *grid_spacing;
long *no_laps_diag;
long *status;
#endif
#endif
{		   

/*char model[132], asctime[18], origin[132], version[5]; */

        char *var, *comment, *units, *prefix, *fname;
        char *p_var, *pf_var, *p_com, *pf_com, *p_unit, *pf_unit;
        char *comm_var, *model, *asctime;
        float *p_data;
	int istat, i, j, unconv_var, process_vr, cdfid, varid;
        int c_var_len, c_com_len, c_unit_len, s_len;
#ifdef __alpha
	int imaxn, jmaxn, n_grids_n;
#else
	long imaxn, jmaxn, n_grids_n;
#endif
	
/* turn off the error handling done by the netCDF routines */
        ncopts = NC_VERBOSE;

/* malloc space for c-strings */
        c_var_len = *var_len + 1;
        prefix = malloc(c_var_len * sizeof(char));
        var = malloc(c_var_len * (*n_grids) * sizeof(char));
        c_com_len = *com_len + 1;
        comment = malloc(c_com_len * (*n_grids) * sizeof(char));
        c_unit_len = *unit_len + 1;
        units = malloc(c_unit_len * (*n_grids) * sizeof(char));
        fname = malloc(((*s_length)+1) * sizeof(char));


/* null out arrays for units,comment before using   */
/* convert fortran string f_var to c string var and downcase */
 
        for (i = 0; i < *n_grids; i++) {
          p_unit = units + (i * c_unit_len);
          p_unit = '\0';
          p_com = comment + (i * c_com_len);
          p_com = '\0';
          p_var = var + (i * c_var_len);
          pf_var = f_var + (i * (*var_len));
          nstrncpy(p_var, pf_var, *var_len);
          downcase_c(p_var,p_var);
        }

/* convert fortran filname into C fname */
        nstrncpy(fname,filname,s_length);
 
/* open file for reading */	
	cdfid = open_cdf(NC_NOWRITE,fname,no_laps_diag);
	if (cdfid == -1) {
		*status = -1;	/* error opening file */
                free_static_malloc(prefix, NULL, NULL, NULL, 
                                   var, comment, units, fname);
		return;
	}

/* get header info */
	istat = cdf_retr_hdr_stat(cdfid,&imaxn,&jmaxn,&n_grids_n,
				  grid_spacing);
	if (istat == -1) {
	   *status = -5;
	   ncclose(cdfid);
           free_static_malloc(prefix, NULL, NULL, NULL, 
                              var, comment, units, fname);
	   return;
	}
	if (imaxn > *imax || jmaxn > *jmax ) {
	   *status = -3;
	   ncclose(cdfid);
           free_static_malloc(prefix, NULL, NULL, NULL, 
                              var, comment, units, fname);
	   return;
	}
	
	unconv_var = 0;
	for (i = 0; i < *n_grids; i++) {
          p_var = var + (i * c_var_len);
          p_com = comment + (i * c_com_len);
          p_unit = units + (i * c_unit_len);
          p_data = data + (i*(*imax)*(*jmax));
          strcpy(prefix,p_var);
          if ((varid = ncvarid (cdfid , prefix)) == (-1)) {
            printf("write_cdf_static: no variable %s in file.\n", prefix);
            unconv_var += 1;
          }
          else  {
            istat = cdf_retr_grid_stat(cdfid,varid,prefix,p_data,
                                       p_com,c_com_len,p_unit,
                                       c_unit_len);
            if (istat == -1) {
              *status = -4;
              ncclose(cdfid);
              free_static_malloc(prefix, NULL, NULL, NULL, 
                                 var, comment, units, fname);
              return;
            }
          }
        }
   
        ncclose(cdfid);

        for (i = 0; i < *n_grids; i++) {
          p_com = comment + (i * c_com_len);
          pf_com = f_comment + (i * (*com_len));
          s_len = strlen(p_com);
          strncpy(pf_com, p_com, s_len);
          pf_com += s_len;
          if (s_len < (*com_len)) {
            for ( j = 0; j < (*com_len - s_len); j++) {
              *pf_com = ' ';
              pf_com++;
            }
          }
          p_unit = units + (i * c_unit_len);
          pf_unit = f_units + (i * (*unit_len));
          s_len = strlen(p_unit);
          strncpy(pf_unit, p_unit, s_len);
          pf_unit += s_len;
          if (s_len < (*unit_len)) {
            for ( j = 0; j < (*unit_len - s_len); j++) {
              *pf_unit = ' ';
              pf_unit++;
            }
          }
        }

        free_static_malloc(prefix, NULL, NULL, NULL, 
                           var, comment, units, fname);
        *status = unconv_var;
        return;
}

