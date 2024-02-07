#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: pre_processing
#
# !DESCRIPTION:
#     Script to prepare boundary and initials conditions for MONAN model.
#     
#     Performs the following tasks:
# 
#        o Creates topography, land use and static variables
#        o Ungrib GFS data
#        o Interpolates to model the grid
#        o Creates initial and boundary conditions
#        o Creates scripts to run the model and post-processing (CR: to be modified to fase 3 and 4)
#        o Integrates the MONAN model ((CR: to be modified to fase 3)
#        o Post-processing (netcdf for grib2, latlon regrid, crop) (CR: to be modified to fase 4)
#
#-----------------------------------------------------------------------------#

if [ $# -ne 4 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP_NAME RESOLUTION LABELI FCST"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
   echo "            :: Others options to be added later..."
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST        :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} GFS 1024002 2024010100 24"
   echo ""

#   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash


# Standart directories variables:----------------------
DIRHOME=${DIRWORK}/../../MONAN;  mkdir -p ${DIRHOME}
SCRIPTS=${DIRHOME}/scripts;      mkdir -p ${SCRIPTS}
DATAIN=${DIRHOME}/datain;        mkdir -p ${DATAIN}
DATAOUT=${DIRHOME}/dataout;      mkdir -p ${DATAOUT}
SOURCES=${DIRHOME}/sources;      mkdir -p ${SOURCES}
EXECS=${DIRHOME}/execs;          mkdir -p ${EXECS}
#-------------------------------------------------------



# Local variables--------------------------------------
# from script 1:--- (keep it only if was usefull) -----
vlabel="v0.1.0"
MONANDIR=${SOURCES}/MONAN-Model_${vlabel}
CONVERT_MPAS_DIR=${SOURCES}/convert_mpas
branch_name="develop"
#-------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};      EXP=GFS
RES=${2};      RES=1024002
LABELI=${3};   LABELI=2024010100 
FCST=${4};     FCST=24
#-------------------------------------------------------

# Calculating CIs and final forecast dates in model namelist format:
yyyymmddhhi=${LABELI}
yyyymmddi=${yyyymmddhhi:0:8}
hhi=${yyyymmddhhi:8:2}
yyyymmddhhf=$(date +"%Y%m%d%H" -d "${yyyymmddi} ${hhi}:00 ${FCST} hours" )
final_date=${yyyymmddhhf:0:4}-${yyyymmddhhf:4:2}-${yyyymmddhhf:6:2}_${yyyymmddhhf:8:2}.00.00

# Creating the some importants directories:
# Pre-processing input dir:
#
# Pre-processing output dir:
#


# Untar the fixed files:
# x1.${RES}.graph.info.part.<Ncores> files can be found in datain/fixed
# *.TBL files can be found in datain/fixed
# namelists files marked with TEMPLATE can be found in datain/namelists
# x1.${RES}.grid.nc can be found in datain/fixed
echo -e  "${GREEN}==>${NC} Copying and decompressing input data... \n"
tar -xzvf ${DIRDADOS}/MONAN_datain.tgz -C ${DIRHOME}



# Creating the x1.${RES}.static.nc file: -----------------------------------------------
#CR: maybe put this part in a separete script, and just use it if so
echo -e "${GREEN}==>${NC} Creating static.bash for submiting init_atmosphere...\n"
cores=32
mkdir -p ${DATAOUT}/logs
rm -f ${SCRIPTS}/static.bash 
cat << EOF0 > ${SCRIPTS}/static.bash 
#!/bin/bash
#SBATCH --job-name=static
#SBATCH --nodes=1 
#SBATCH --ntasks=${cores}             
#SBATCH --tasks-per-node=${cores}  
#SBATCH --partition=${STATIC_QUEUE}
#SBATCH --time=02:00:00        
#SBATCH --output=${DATAOUT}/logs/static.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/logs/static.bash.e%j     # File name for standard error output
#SBATCH --mem=500000


executable=init_atmosphere_model

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

. ${SCRIPTS}/setenv.bash

cd ${SCRIPTS}

date
time mpirun -np \$SLURM_NTASKS -env UCX_NET_DEVICES=mlx5_0:1 -genvall ./\${executable}
date

grep "Finished running" log.init_atmosphere.0000.out >& /dev/null
if [ \$? -ne 0 ]; then
   echo "  BUMMER: Static generation failed for some yet unknown reason."
   echo " "
   tail -10 ${STATICPATH}/log.init_atmosphere.0000.out
   echo " "
   exit 21
fi

echo "  ####################################"
echo "  ### Static completed - \$(date) ####"
echo "  ####################################"
echo " "

#
# clean up and remove links
#

mv log.init_atmosphere.0000.out ${DATAOUT}/logs

#find ${STATICPATH} -maxdepth 1 -type l -exec rm -f {} \;

#CR: parei aqui. Proximo passo: tasnformar a fase do static num script separado e usa-lo nesse ponto.
Dai precisa refazer os links do velho static.sh no novo script separado.


EOF0
chmod a+x ${SCRIPTS}/static.bash
#-------------------------------------------------------








