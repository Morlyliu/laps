# User options are in src/include/makefile.inc
# This Makefile is designed for gnu make version 3.75 or newer
# Please report problems to lapsbugs@fsl.noaa.gov


SRCROOT=.
include $(SRCROOT)/src/include/makefile.inc

LINK=$(SRCROOT)/util/link.pl
CWD = $(shell pwd)

MACHDEP = config.log config.status config.cache src/include/config.h

LIBDIRS = src/lib \
          src/lib/bgdata \
          src/lib/blas \
          src/lib/cloud \
          src/lib/fm \
          src/lib/goesinav \
          src/lib/goeslib \
          src/lib/lapack \
          src/lib/mthermo \
          src/lib/nav \
          src/lib/powell  \
          src/lib/radar/remap_ftn \
          src/lib/radar/wsi_ingest \
          src/lib/satellite \
          src/lib/temp   \
          src/lib/util  

EXEDIRS = src/accum \
          src/background \
          src/balance \
          src/cloud \
          src/deriv \
	  src/dprep \
          src/grid \
          src/humid \
          src/humid/optran_setup \
          src/ingest/acars \
          src/ingest/profiler \
          src/ingest/radar/ingest_rrv \
          src/ingest/radar/remap \
          src/ingest/radar/wsiremap/ln3 \
          src/ingest/radar/wsiremap/vrc \
          src/ingest/raob \
          src/ingest/rass \
          src/ingest/sao \
          src/ingest/satellite/cloud_drift \
          src/ingest/satellite/lvd \
          src/ingest/satellite/lvd/table \
          src/ingest/satellite/sounding \
          src/ingest/sfc_qc \
	  src/lapsprep \
          src/sfc \
          src/sfc/table \
          src/soil \
          src/temp \
          src/wind \
          src/WFO/post

all: exe
debug: debuglib
#
# The following targets are for building within awips 4.2
#
buildlib: lib
buildexe: exe
doc:
depend:
prebuild:



localize: mkdatadirs
	$(PERL) $(SRCROOT)/etc/laps_localization.pl --lapsroot=$(INSTALLROOT) \
               --dataroot=$(DATAROOT) --srcroot=$(SRCROOT)

exe: lib
	@for dir in $(EXEDIRS) ;\
	  do \
	  echo " ";\
	  echo Making Laps in directory $$dir ;\
	  (cd $$dir; if [ $$? != 0 ] ; then \
	        echo "Exit status from cd $$dir was $$?" ; exit 1 ; fi ;\
	  $(MAKE) all ; if [ $$? != 0 ] ; then \
	        echo "Exit status from make was $$?" ; exit 1 ; fi ;) ;\
	  done

lib:
	@for dir in $(LIBDIRS) ;\
	  do \
	  echo " ";\
	  echo Making Laps in directory $$dir ;\
	  (cd $$dir; if [ $$? != 0 ] ; then \
	        echo "Exit status from cd $$dir was $$?" ; exit 1 ; fi ;\
	  $(MAKE) all ; if [ $$? != 0 ] ; then \
	        echo "Exit status from make was $$?" ; exit 1 ; fi ;) ;\
	  done

debuglib:
	@for dir in $(LIBDIRS) ;\
	  do \
	  echo " ";\
	  echo Making Laps in directory $$dir ;\
	  (cd $$dir; if [ $$? != 0 ] ; then \
	        echo "Exit status from cd $$dir was $$?" ; exit 1 ; fi ;\
	  $(MAKE) debug ; if [ $$? != 0 ] ; then \
	        echo "Exit status from make was $$?" ; exit 1 ; fi ;) ;\
	  done

lapsplot: lib
	cd src/lapsplot; $(MAKE)

install_lapsplot: lib
	cd src/lapsplot; $(MAKE) install

ldmtools: 
	cd src/ldmtools; $(MAKE)

install_ldmtools: 
	cd src/ldmtools; $(MAKE) install


ridds: 	
	cd $(SRCROOT)/src/lib/radar/nexrad_nssl; $(MAKE)
	cd $(SRCROOT)/src/lib/radar/a2io; $(MAKE)
	cd $(SRCROOT)/src/ingest/radar/circbuff_to_nc; $(MAKE)

install: mkdirs mkdatadirs
	@for dir in $(LIBDIRS) $(EXEDIRS);\
	  do \
	  echo " ";\
	  echo Making Laps in directory $$dir ;\
	  (cd $$dir; if [ $$? != 0 ] ; then \
	        echo "Exit status from cd $$dir was $$?" ; exit 1 ; fi ;\
	  $(MAKE) install ; if [ $$? != 0 ] ; then \
	        echo "Exit status from make was $$?" ; exit 1 ; fi ;) ;\
	  done

mkdirs:
	mkdir -p $(INSTALLROOT)
	ls -l  $(SRCROOT)/util; cp -r $(SRCROOT)/util $(INSTALLROOT) ; ls -l $(INSTALLROOT)/util 
	ls -l  $(SRCROOT)/etc;  cp -r $(SRCROOT)/etc  $(INSTALLROOT) ; ls -l $(INSTALLROOT)/etc 

mkdatadirs:
	$(PERL) $(SRCROOT)/etc/makedatadirs.pl --srcroot=$(SRCROOT) --installroot=$(INSTALLROOT) \
                         --dataroot=$(DATAROOT)


clean:
	$(RM) *~ *# *.o 
	cd src/include; $(RM) *~ *# *.o 
	@for dir in $(EXEDIRS);\
	  do \
	  echo " ";\
	  echo Making LAPS clean in directory $$dir ;\
	  (cd $$dir; if [ $$? != 0 ] ; then \
	        echo "Exit status from cd $$dir was $$?" ; exit 1 ; fi ;\
	  $(MAKE) clean ; if [ $$? != 0 ] ; then \
	        echo "Exit status from make was $$?" ; exit 1 ; fi ;) ;\
	  done

realclean: clean
	@for dir in $(LIBDIRS);\
	  do \
	  echo " ";\
	  echo Making LAPS clean in directory $$dir ;\
	  (cd $$dir; if [ $$? != 0 ] ; then \
	        echo "Exit status from cd $$dir was $$?" ; exit 1 ; fi ;\
	  $(MAKE) clean ; if [ $$? != 0 ] ; then \
	        echo "Exit status from make was $$?" ; exit 1 ; fi ;) ;\
	  done

distclean: realclean cleandirs
	@for dir in $(LIBDIRS) $(EXEDIRS);\
	  do \
	  echo " ";\
	  echo Making LAPS distclean in directory $$dir ;\
	  (cd $$dir; if [ $$? != 0 ] ; then \
	        echo "Exit status from cd $$dir was $$?" ; exit 1 ; fi ;\
	  $(MAKE) distclean ; if [ $$? != 0 ] ; then \
	        echo "Exit status from make was $$?" ; exit 1 ; fi ;) ;\
	  done
	$(RM) $(MACHDEP) \
	      ./util/cronfile ./etc/*.pl ./etc/*.csh ; \
	$(RM) -r ./bin ./log

cleandirs:
	$(PERL) $(SRCROOT)/etc/makedatadirs.pl --srcroot=$(SRCROOT) --installroot=$(INSTALLROOT) \
                         --dataroot=$(DATAROOT) --cleandirs
links:
	$(LINK) $(CWD) $(SRCROOT) $(INSTALLROOT)/lib $(MACHDEP)
	@for dir in $(LIBDIRS) $(EXEDIRS);\
	  do \
	  echo " ";\
	  echo Making LAPS links in directory $$dir ;\
	  (cd $$dir; if [ $$? != 0 ] ; then \
	        echo "Exit status from cd $$dir was $$?" ; exit 1 ; fi ;\
	  $(MAKE) links ; if [ $$? != 0 ] ; then \
	        echo "Exit status from make was $$?" ; exit 1 ; fi ;) ;\
	  done

