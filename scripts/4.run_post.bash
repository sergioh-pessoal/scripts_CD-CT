#!/bin/bash

#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: run_post
#
# !DESCRIPTION:
#     Script to run the pos-processing of MONAN model over the forecast horizon.
#     
#     Performs the following tasks:
# 
#        o VCheck all input files before
#        o Creates the submition script
#        o Submit the post
#        o Veriffy all files generated
#        
#
#-----------------------------------------------------------------------------#

if [ $# -ne 0 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} LABELI RESOLUTION"
   echo ""
   echo "LABELI      :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "RESOLUTION  :: number of points in resolution model grid, e.g: 1024002  (24 km)"

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
RES=${2};         RES=1024002
#-------------------------------------------------------
cp -f setenv.bash ${SCRIPTS}
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}


# Local variables--------------------------------------
START_DATE_YYYYMMDD="${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}"
START_HH="${YYYYMMDDHHi:8:2}"
#-------------------------------------------------------
mkdir -p ${DATAIN}/namelists
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Post/logs
cp -f $(pwd)/../namelists/* ${DATAIN}/namelists

cp ${DATAIN}/namelists/include_fields.diag ${SCRIPTS}/include_fields
ln -sf ${EXECS}/convert_mpas ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.init.nc ${SCRIPTS}

mkdir -p ${DATAOUT}/logs
rm -f ${SCRIPTS}/post.bash 
cat << EOF0 > ${SCRIPTS}/post.bash 
#!/bin/bash
#SBATCH --job-name=${POST_jobname}
#SBATCH --nodes=${POST_nnodes}
#SBATCH --ntasks=${POST_ncores}
#SBATCH --tasks-per-node=${POST_ncpn}
#SBATCH --partition=${POST_QUEUE}
#SBATCH --time=${POST_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/post.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/post.bash.e%j     # File name for standard error output
#SBATCH --exclusive
##SBATCH --mem=500000


export executable=convert_mpas

ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

. $(pwd)/setenv.bash

cd ${SCRIPTS}

rm -f latlon.nc
date
time ./\${executable} x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/diag*nc
date

rm -f surface.nc
date
time cdo settunits,hours -settaxis,${START_DATE_YYYYMMDD},${START_HH}:00,1hour latlon.nc surface.nc
date
rm -f latlon.nc

rm -f x1.${RES}.init.nc
rm -f \${executable}
mv  include_fields ${DATAOUT}/${YYYYMMDDHHi}/Post
mv surface.nc ${DATAOUT}/${YYYYMMDDHHi}/Post

EOF0
chmod a+x ${SCRIPTS}/post.bash

echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model Post-processing and waiting for finish before exit... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/logs... \n"
echo -e  "sbatch ${SCRIPTS}/post.bash"
sbatch --wait ${SCRIPTS}/post.bash

