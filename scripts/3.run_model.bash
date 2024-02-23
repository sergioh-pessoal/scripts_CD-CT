#!/bin/bash

#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: run_model
#
# !DESCRIPTION:
#     Script to run the MONAN model over the forecast horizon.
#     
#     Performs the following tasks:
# 
#        o VCheck all input files before 
#        o Creates the submition script
#        o Submit the model
#        o Veriffy all files generated
#        
#
#-----------------------------------------------------------------------------#

if [ $# -ne 4 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} EXP_NAME LABELI RESOLUTION"
   echo ""
   echo "EXP_NAME    :: Forcing: GFS"
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
EXP=${1};         EXP=GFS
YYYYMMDDHHi=${2}; YYYYMMDDHHi=2024012000
RES=${3};         RES=1024002
#-------------------------------------------------------
cp -f setenv.bash ${SCRIPTS}
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}


# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
ncores=${MODEL_ncores}
#-------------------------------------------------------



#CR: verify if input files exist before submit the model:
ln -sf ${EXECS}/atmosphere_model ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*TBL ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*DBL ${SCRIPTS}
ln -sf ${DATAIN}/fixed/*DATA ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.static.nc ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.graph.info.part.${ncores} ${SCRIPTS}
ln -sf ${DATAIN}/fixed/x1.${RES}.init.nc ${SCRIPTS}
ln -sf ${DATAIN}/fixed/Vtable.GFS ${SCRIPTS}
ln -sf ${DATAIN}/fixed/Vtable.ERA-interim.pl ${SCRIPTS}


if [ ${EXP} = "GFS" ]
then
   sed -e "s,#LABELI#,${start_date},g" \
         ${DATAIN}/namelists/namelist.atmosphere.TEMPLATE > ${SCRIPTS}/namelist.atmosphere
   cp -f ${DATAIN}/namelists/streams.atmosphere.TEMPLATE ${SCRIPTS}/streams.atmosphere
fi
cp ${DATAIN}/namelists//stream_list.atmosphere.* ${SCRIPTS}


mkdir -p ${DATAOUT}/logs
rm -f ${SCRIPTS}/model.bash 
cat << EOF0 > ${SCRIPTS}/model.bash 
#!/bin/bash
#SBATCH --job-name=${MODEL_jobname}
#SBATCH --nodes=${MODEL_nnodes}
#SBATCH --ntasks=${MODEL_ncores}
#SBATCH --tasks-per-node=${MODEL_ncpn}
#SBATCH --partition=${MODEL_QUEUE}
#SBATCH --time=${STATIC_walltime}
#SBATCH --output=${DATAOUT}/logs/model.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/logs/model.bash.e%j     # File name for standard error output
#SBATCH --exclusive
##SBATCH --mem=500000


export executable=atmosphere_model
ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

. $(pwd)/setenv.bash

cd ${SCRIPTS}


date
time mpirun -np \${SLURM_NTASKS} -env UCX_NET_DEVICES=mlx5_0:1 -genvall ./\${executable}
date

#
# move dataout, clean up and remove files/links
#

#CR: maybe put these log files into the run directory (dataout/yyyymmddhhi/logs)
mv log.atmosphere.*.out ${DATAOUT}/logs
mv log.atmosphere.*.err ${DATAOUT}/logs
cp -f namelist.atmosphere ${DATAOUT}/${YYYYMMDDHHi}
cp -f stream* ${DATAOUT}/${YYYYMMDDHHi}
mv diag* ${DATAOUT}/${YYYYMMDDHHi}
mv histor* ${DATAOUT}/${YYYYMMDDHHi}
rm -f ${SCRIPTS}/atmosphere_model
rm -f ${SCRIPTS}/*TBL 
rm -f ${SCRIPTS}/*.DBL
rm -f ${SCRIPTS}/*DATA
rm -f ${SCRIPTS}/x1.${RES}.static.nc
rm -f ${SCRIPTS}/x1.${RES}.graph.info.part.${ncores}
rm -f ${SCRIPTS}/Vtable.GFS
rm -f ${SCRIPTS}/Vtable.ERA-interim.pl




EOF0
chmod a+x ${SCRIPTS}/model.bash

echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model and waiting for finish before exit... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/logs... \n"
echo -e  "sbatch ${SCRIPTS}/model.bash"
sbatch --wait ${SCRIPTS}/model.bash


#CR: maybe put the ic date on the name of output files!
