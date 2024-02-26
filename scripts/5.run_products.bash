#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: run_poducts
#
# !DESCRIPTION:
#     Script to run the products of pos-processing of MONAN model .
#     
#     Performs the following tasks:
# 
#        o Check all input files before (post-processed files)
#        o Creates the submition script
#        o Submit the products scripts
#        o Veriffy all products generated
#        
#
#-----------------------------------------------------------------------------#

if [ $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} LABELI "
   echo ""
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"

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


# Input variables:--------------------------------------
YYYYMMDDHHi=${1}; YYYYMMDDHHi=2024012000
#-------------------------------------------------------
cp -f setenv.bash ${SCRIPTS}


# Local variables--------------------------------------
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Prods/logs


cat << EOGS > ${SCRIPTS}/prec.gs
'reinit'

'sdfopen ${DATAOUT}/${YYYYMMDDHHi}/Post/surface.nc'

'set display color white'
'set gxout shaded'
'set mpdset mres'
'set grads off'
'c'

'set lon -83.75 -20.05'
'set lat -55.75 14.25'
'set t 1'
'pr1=rainc+rainnc'
'set t 25'
'pr25=rainc+rainnc'
 
'set clevs 0.5 1 2 4 8 16 32 64 128'
'set ccols 0 14 11 5 13 10 7 12 2 6'

'd pr25-pr1'
'set gxout contour'

'cbar'
'draw title MONAN APCP+24h'

'printim ${DATAOUT}/${YYYYMMDDHHi}/Prods/MONAN.png'
'quit'

EOGS


cat << EOF0 > ${SCRIPTS}/prods.bash 
#!/bin/bash
#SBATCH --job-name=${PRODS_jobname}
#SBATCH --nodes=${PRODS_nnodes}
#SBATCH --ntasks=${PRODS_ncores}
#SBATCH --tasks-per-node=${PRODS_ncpn}
#SBATCH --partition=${PRODS_QUEUE}
#SBATCH --time=${PRODS_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Prods/logs/prods.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Prods/logs/prods.bash.e%j     # File name for standard error output
##SBATCH --exclusive
##SBATCH --mem=500000


ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

. $(pwd)/setenv.bash

cd ${SCRIPTS}

date
tim grads -bpcx "run prec.gs"
date


EOF0
chmod a+x ${SCRIPTS}/prods.bash

echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model Products and waiting for finish before exit... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/${YYYYMMDDHHi}/Prods/logs... \n"
echo -e  "sbatch ${SCRIPTS}//prods.bash"
sbatch --wait ${SCRIPTS}/prods.bash

