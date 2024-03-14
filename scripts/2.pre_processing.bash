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
#        o Creates scripts to run the model and post-processing (CR: to be modified to phase 3 and 4)
#        o Integrates the MONAN model ((CR: to be modified to phase 3)
#        o Post-processing (netcdf for grib2, latlon regrid, crop) (CR: to be modified to phase 4)
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


# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/MONAN;   mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/MONAN;     mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;     mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;       mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;     mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;     mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;         mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         EXP=GFS
RES=${2};         RES=1024002
YYYYMMDDHHi=${3}; YYYYMMDDHHi=2024012000
FCST=${4};        FCST=24
#-------------------------------------------------------
cp -f setenv.bash ${SCRIPTS}


# Local variables--------------------------------------
# Calculating CIs and final forecast dates in model namelist format:
yyyymmddi=${YYYYMMDDHHi:0:8}
hhi=${YYYYMMDDHHi:8:2}
yyyymmddhhf=$(date +"%Y%m%d%H" -d "${yyyymmddi} ${hhi}:00 ${FCST} hours" )
final_date=${yyyymmddhhf:0:4}-${yyyymmddhhf:4:2}-${yyyymmddhhf:6:2}_${yyyymmddhhf:8:2}.00.00
#-------------------------------------------------------
# namelists files marked with TEMPLATE can be found in datain/namelists
# those files are copied from versined main diretory scripts_CD-CT/namelists
mkdir -p ${DATAIN}/namelists
cp -f $(pwd)/../namelists/* ${DATAIN}/namelists


# Untar the fixed files:
# x1.${RES}.graph.info.part.<Ncores> files can be found in datain/fixed
# *.TBL files can be found in datain/fixed
# x1.${RES}.grid.nc can be found in datain/fixed
#~12m30s
echo -e  "${GREEN}==>${NC} Copying and decompressing input data... \n"
time tar -xzvf ${DIRDADOS}/MONAN_datain.tgz -C ${DIRHOMED}


# Creating the x1.${RES}.static.nc file once, if does not exist yet:---------------
if [ ! -s ${DATAIN}/fixed/x1.${RES}.static.nc ]
then
   echo -e "${GREEN}==>${NC} Creating static.bash for submiting init_atmosphere to create x1.${RES}.static.nc...\n"
   time ./make_static.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}
else
   echo -e "${GREEN}==>${NC} File x1.${RES}.static.nc already exist in ${DATAIN}/fixed.\n"
fi
#----------------------------------------------------------------------------------



# Degrib phase:---------------------------------------------------------------------
echo -e  "${GREEN}==>${NC} Submiting Degrib...\n"
time ./make_degrib.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}


# Init Atmosphere phase:------------------------------------------------------------
echo -e  "${GREEN}==>${NC} Submiting Init Atmosphere...\n"
time ./make_initatmos.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST}


#----------------------------------------------------------------------------------




