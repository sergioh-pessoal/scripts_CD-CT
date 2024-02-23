#!/bin/bash

#!/bin/bash 


if [ $# -ne 2 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} LABELI"
   echo ""
   echo "LABELI      :: Initial date, e.g.: 2015030600"
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
YYYYMMDDHHi=${1};    YYYYMMDDHHi=2024012000
RES=${2};            RES=1024002
#-------------------------------------------------------


# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
GEODATA=${DATAIN}/WPS_GEOG
ncores=${INITATMOS_ncores}
#-------------------------------------------------------
cp -f setenv.bash ${SCRIPTS}


sed -e "s,#LABELI#,${start_date},g;s,#GEODAT#,${GEODATA},g" \
	 ${DATAIN}/namelists/namelist.init_atmosphere.TEMPLATE > ${SCRIPTS}/namelist.init_atmosphere

cp ${DATAIN}/namelists/streams.init_atmosphere.TEMPLATE ${SCRIPTS}/streams.init_atmosphere
#CR: verificar se existe o arq *part.${ncores}. Caso nao exista, criar um script que gere o arq necessario
ln -sf ${DATAIN}/fixed/x1.${RES}.graph.info.part.${ncores} ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.static.nc ${SCRIPTS}
ln -sf ${DATAIN}/${YYYYMMDDHHi}/GFS\:${start_date:0:13} ${SCRIPTS}
ln -sf ${EXECS}/init_atmosphere_model ${SCRIPTS}


mkdir -p ${DATAOUT}/logs
rm -f ${SCRIPTS}/initatmos.bash 
cat << EOF0 > ${SCRIPTS}/initatmos.bash 
#!/bin/bash
#SBATCH --job-name=${INITATMOS_jobname}
#SBATCH --nodes=${INITATMOS_nnodes}                         # depends on how many boundary files are available
#SBATCH --partition=${INITATMOS_QUEUE} 
#SBATCH --tasks-per-node=${INITATMOS_ncores}               # only for benchmark
#SBATCH --time=${STATIC_walltime}
#SBATCH --output=${DATAOUT}/logs/initatmos.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/logs/initatmos.bash.e%j     # File name for standard error output
#SBATCH --exclusive
##SBATCH --mem=500000

export executable=init_atmosphere_model

ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited


. $(pwd)/setenv.bash

cd ${SCRIPTS}



date
time mpirun -np \${SLURM_NTASKS} -env UCX_NET_DEVICES=mlx5_0:1 -genvall ./\${executable}
date


mv ${SCRIPTS}/log.init_atmosphere.0000.out ${DATAOUT}/logs/log.init_atmosphere.0000.x1.${RES}.init.nc.${YYYYMMDDHHi}.out
mv ${SCRIPTS}/x1.${RES}.init.nc ${DATAIN}/fixed 
#CR: esse arquivo gerado x1.${RES}.init.nc eh fixo? ou gerado a cada rodada? 
#CR: (S: veriricar se existe antes de gerar novamente; N: armazena-lo em datain/yyyymmddhh e nao em datain/fixed)
chmod a+x ${DATAIN}/fixed//x1.${RES}.init.nc 
rm -f ${SCRIPTS}/GFS:2024-01-20_00
rm -f ${SCRIPTS}/init_atmosphere_model
rm -f ${SCRIPTS}/x1.1024002.graph.info.part.32
rm -f ${SCRIPTS}/x1.1024002.static.nc
rm -f ${SCRIPTS}/log.init_atmosphere.*.err

EOF0
chmod a+x ${SCRIPTS}/initatmos.bash

echo -e  "${GREEN}==>${NC} Executing sbatch initatmos.bash...\n"
cd ${SCRIPTS}
sbatch --wait ${SCRIPTS}/initatmos.bash

if [ ! -s ${DATAIN}/fixed/x1.${RES}.init.nc ]
then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} Init Atmosphere phase fails! Check logs at ${DATAOUT}/logs/initatmos.* .\n"
  echo -e  "${RED}==>${NC} Exiting script. \n"
  exit -1
fi

