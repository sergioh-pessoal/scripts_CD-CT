#!/bin/bash 


if [ $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} LABELI"
   echo ""
   echo "LABELI  :: Initial date, e.g.: 2015030600"
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
YYYYMMDDHHi=${1};      YYYYMMDDHHi=2024012000
#-------------------------------------------------------



# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}.00.00
#-------------------------------------------------------

mkdir -p ${DATAOUT}/logs
rm -f ${SCRIPTS}/degrib.bash 
cat << EOF0 > ${SCRIPTS}/degrib.bash 
#!/bin/bash
#SBATCH --job-name=Degrib
#SBATCH --nodes=1
#SBATCH --partition=${DEGRIB_QUEUE}
#SBATCH --tasks-per-node=1                      # ic for benchmark
#SBATCH --time=00:30:00
#SBATCH --output=${DATAOUT}/logs/debrib.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/logs/debrib.e%j     # File name for standard error output
#

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

export PMIX_MCA_gds=hash


export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64
ldd ungrib.exe

. $(pwd)/setenv.bash

cd ${SCRIPTS}

rm -f GRIBFILE.* namelist.wps


sed -e "s,#LABELI#,${start_date},g;s,#PREFIX#,GFS,g" \
	${DATAIN}/fixed/namelist.wps.TEMPLATE > ./namelist.wps

./link_grib.csh gfs.t00z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2


date
time mpirun -np 1 ./ungrib.exe
date

rm -f GRIBFILE.*
rm -f gfs.t00z.pgrb2.0p25.f000.${LABELI}.grib2


grep "Successful completion of program ungrib.exe" ${DATAOUT}/logs/ungrib.log >& /dev/null

if [ \$? -ne 0 ]; then
   echo "  BUMMER: Ungrib generation failed for some yet unknown reason."
   echo " "
   tail -10 ${DATAOUT}/logs/ungrib.log
   echo " "
   exit 21
fi

#
# clean up and remove links
#
   mv ungrib.*.log ${DATAOUT}/logs
   mv ungrib.log ${DATAOUT}/logs/ungrib.${start_date}.log
   mv Timing.degrib ${DATAOUT}/logs
   mv namelist.wps degrib_exe.sh ${DATAOUT}/logs
   rm -f link_grib.csh # CR: copiar este script para o dir scripts antes de executa-lo e posteriormente apaga-lo
   
CR: migracao parei aqui 15/02/24
exit
   
   ln -sf wpsprd/GFS\:${start_date:0:13} .
   find ${EXPDIR}/wpsprd -maxdepth 1 -type l -exec rm -f {} \;

echo "End of degrib Job"


EOF0
chmod a+x ${SCRIPTS}/degrib.bash
