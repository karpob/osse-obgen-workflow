#!/bin/csh -f
   
#SBATCH --output=osseObGenStdO.txt
#SBATCH --error=osseObGenStdE.txt
#SBATCH --account=s0818
#SBATCH --time=00:40:00
#SBATCH --nodes=1 --ntasks-per-node=40
#SBATCH --job-name=osseObGen
#SBATCH --constraint="cas&cssro"
#SBATCH --qos=debug

umask 022
limit stacksize unlimited

source /usr/share/modules/init/csh
module load python/GEOSpyD/Min4.9.2_py3.9

echo $MY_DTG
set win_start=`ndate -03 $MY_DTG`
set win_end=`ndate +03 $MY_DTG`

echo 'running ossetool/interpolating obs.'
cd /discover/nobackup/projects/gmao/obsdev/bkarpowi/osseObsGen/osse-obgen-bundle/ossetool/
./write_input_for_dtg.py --start $win_start --end $win_end
python ./main.py
##discover/nobackup/projects/gmao/obsdev/bkarpowi/osseObsGen/dawn_data/dawn.1330.{y4}{m2}{d2}_{h2}{mn2}{s2}z.nc4
module purge

cd /discover/nobackup/bkarpowi/github/dawn/ext_calc/  
echo 'running extinction calc'

#######################################################################
#           Architecture Specific Environment Variables
#######################################################################
source $HOME/.cshrc

#######################################################################
#   Move to Run Directory
#######################################################################
source setup_env
module list
##################################################################
######
######         Do Ext Calculation
######
##################################################################
set yyyy=`echo $MY_DTG |cut -b1-4`
set   mm=`echo $MY_DTG |cut -b5-6`
set   dd=`echo $MY_DTG |cut -b7-8`
set   hh=`echo $MY_DTG |cut -b9-10`

set infile=/discover/nobackup/projects/gmao/obsdev/bkarpowi/osseObsGen/dawn_data/dawn.1330.${yyyy}${mm}${dd}_${hh}0000z.nc4
set outfile=/discover/nobackup/projects/gmao/obsdev/bkarpowi/osseObsGen/dawn_data/dawn.1330.${yyyy}${mm}${dd}_${hh}0000z_bksct.nc4
ext_sampler.py -i $infile -r Aod_EOS.2000.rc -c 2058.0 -o $outfile --format NETCDF4
#now append backscatter
echo 'appending backscatter, clearing aersol junk.'
module load nco 
ncks -A -v backscat $outfile $infile
ncks -C -O -x -v PS,AIRDENS,DELP,DU005,RH,DU004,SS004,DU003,SS001,DU002,DU001,SS003,SS002,SS005,SO2,BCPHOBIC,SO4,OCPHOBIC,BCPHILIC,OCPHILIC $infile ${infile}_tmp
mv ${infile}_tmp $infile
rm $outfile
echo 'filtering lidar'
cd /discover/nobackup/projects/gmao/obsdev/bkarpowi/osseObsGen/osse-obgen-bundle/osse-obgen-lidar/
module purge 
module load python/GEOSpyD/Min4.9.2_py3.9  
./filter_g5nr_lidar.py --in $infile --out ${infile}_filtered.nc4 --nthreads 16

module purge
# load junk for bufrize
cd /discover/nobackup/projects/gmao/obsdev/bkarpowi/osseObsGen/osse-obgen-bundle/osse-obgen-bufr/build/bin
ln -s ${infile}_filtered.nc4 dawn.1330.${yyyy}${mm}${dd}_${hh}z

module use -a /discover/swdev/gmao_SIteam/modulefiles-SLES12
module load GEOSenv
setenv GEOS_WHIR /discover/nobackup/projects/gmao/obsdev/bkarpowi/osseObsGen/GEOSadas
source ${GEOS_WHIR}/@env/g5_modules

echo 'making bufr'
./mistic_to_prepob_nc.x dawn.1330.${yyyy}${mm}${dd}_${hh}z ${MY_DTG} 261
mv dawn.1330.${yyyy}${mm}${dd}_${hh}z.bufr /discover/nobackup/projects/gmao/obsdev/bkarpowi/osseObsGen/dawn_data/
rm dawn.1330.${yyyy}${mm}${dd}_${hh}z
cd /discover/nobackup/projects/gmao/obsdev/bkarpowi/osseObsGen/osse-obgen-bundle/osse-obgen-workflow/ 
setenv END_DTG 2006070100
if( $MY_DTG == $END_DTG ) then
    echo 'Done!'
    exit
endif
set the_date=`ndate +06 $MY_DTG`
sbatch --export=MY_DTG=$the_date genObs.j  
