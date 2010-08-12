#!/bin/ksh



#Do for each domain/model/time
#!/bin/sh

echo " "
echo "Running followup_fcst.sh script" 
echo "user = "`whoami`                                    
echo "machine = "`uname -n`

# Arguments
domain=$1
model=$2
LAPS_DATA_ROOT=$3
WINDOW=$4
RESOLUTION=$5
datetime=$6
utc_hhmm=$7

echo "WINDOW = $WINDOW"
echo "RESOLUTION = $RESOLUTION"

# Hard coded stuff
# WINDOW=0.0:0.0:1.0:1.0
LAPS_ETC=/usr/nfs/common/lapb/www/fcst2d
#LAPS_ETC=/usr/nfs/common/lapb/www/fcst2d/$domain/$model
WWW_DIR=/w3/lapb/domains/$domain
latest=latest

# RESOLUTION=730x730

export EXE_DIR=$LAPSINSTALLROOT/bin
export LAPS_DATA_ROOT
export LAPS_ETC

mkdir -p $WWW_DIR/fcst2d
mkdir -p $WWW_DIR/fcst2d/$model

cd $WWW_DIR                            
if (! -e private_data) then
    mkdir -p private_data/static
    cd private_data/static
    ln -s $LAPS_DATA_ROOT/static/nest7grid.parms nest7grid.parms
fi
ls -l $WWW_DIR/private_data/static/nest7grid.parms

#if [[ $model = "wrf-nmm" || $model = "wrf-fer" ]]
#then
#    set -A products CAPE SurfaceTempWind Sfc_RelHum Precip LiftedIndex_SfcDewPt 
#else
#    set -A products CAPE SurfaceTempWind Sfc_RelHum Precip Radar Cloud LiftedIndex_SfcDewPt 
#fi

set -A products `cat $LAPS_DATA_ROOT/static/www/fcst2d/followup_hsect_prods.txt`

#Call for each product
for prod in ${products[*]}
do
  echo " "
  echo "Looping through $prod with call to laps_gifs_sub_fcst.sh"
  startdate=`date -u +%H:%M:%S`
  $LAPS_ETC/laps_gifs_sub_fcst.sh $prod $WINDOW $LAPS_ETC $WWW_DIR $model $LAPS_DATA_ROOT $latest $datetime $RESOLUTION $domain $model
  enddate=`date -u +%H:%M:%S`
  echo "Timing info for $prod: $startdate $enddate"
done
exit
