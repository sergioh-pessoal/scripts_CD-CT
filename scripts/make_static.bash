#!/bin/bash 


if [ $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} RESOLUTION"
   echo ""
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
RES=${1};      RES=1024002
#-------------------------------------------------------
cp -f setenv.bash ${SCRIPTS}


# Local variables--------------------------------------
GEODATA=${DATAIN}/WPS_GEOG
cores=${STATIC_ncores}
#-------------------------------------------------------


#CR: TODO: important verify if exist each file below:
ln -sf ${DATAIN}/fixed/*.TBL ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*.GFS ${SCRIPTS}
ln -sf ${DATAIN}/fixed/Vtable.ERA-interim.pl ${SCRIPTS}
ln -sf ${EXECS}/init_atmosphere_model ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.graph.info.part.${cores} ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.grid.nc ${SCRIPTS}

sed -e "s,#GEODAT#,${GEODATA},g;s,#RES#,${RES},g" \
   ${DATAIN}/namelists/namelist.init_atmosphere.STATIC \
   > ${SCRIPTS}/namelist.init_atmosphere

sed -e "s,#RES#,${RES},g" \
   ${DATAIN}/namelists/streams.init_atmosphere.STATIC \
   > ${SCRIPTS}/streams.init_atmosphere



mkdir -p ${DATAOUT}/logs
rm -f ${SCRIPTS}/static.bash 
cat << EOF0 > ${SCRIPTS}/static.bash 
#!/bin/bash
#SBATCH --job-name=${STATIC_jobname}
#SBATCH --nodes=${STATIC_nnodes} 
#SBATCH --ntasks=${STATIC_ncores}             
#SBATCH --tasks-per-node=${STATIC_ncpn}  
#SBATCH --partition=${STATIC_QUEUE}
#SBATCH --time=${STATIC_walltime}        
#SBATCH --output=${DATAOUT}/logs/static.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/logs/static.bash.e%j     # File name for standard error output
#SBATCH --exclusive
##SBATCH --mem=500000


executable=init_atmosphere_model

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

. $(pwd)/setenv.bash

cd ${SCRIPTS}

date
time mpirun -np \${SLURM_NTASKS} -env UCX_NET_DEVICES=mlx5_0:1 -genvall ./\${executable}
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

mv log.init_atmosphere.0000.out ${DATAOUT}/logs/log.init_atmosphere.0000.x1.${RES}.static.nc.out


EOF0
chmod a+x ${SCRIPTS}/static.bash


echo -e  "${GREEN}==>${NC} Executing sbatch static.bash...\n"
cd ${SCRIPTS}
sbatch --wait ${SCRIPTS}/static.bash

if [ -s ${SCRIPTS}/x1.${RES}.static.nc ]
then
   mv ${SCRIPTS}/x1.${RES}.static.nc ${DATAIN}/fixed
fi

find ${SCRIPTS} -maxdepth 1 -type l -exec rm -f {} \;
rm -f ${SCRIPTS}/log.init_atmosphere.*

