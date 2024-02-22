#!/bin/bash 


if [ $# -ne 3 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} LABELI"
   echo ""
   echo "LABELI      :: Initial date, e.g.: 2015030600"
   echo "EXP_NAME    :: Forcing: GFS"
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
EXP=${2};            EXP=GFS
RES=${3};            RES=1024002
#-------------------------------------------------------



# Local variables--------------------------------------
start_date=${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}:00:00
OPERDIREXP=${OPERDIR}/${EXP}
BNDDIR=${OPERDIREXP}/0p25/brutos/${YYYYMMDDHHi:0:4}/${YYYYMMDDHHi:4:2}/${YYYYMMDDHHi:6:2}/${YYYYMMDDHHi:8:2}
#-------------------------------------------------------
cp -f setenv.bash ${SCRIPTS}
mkdir -p ${DATAIN}/${YYYYMMDDHHi}
mkdir -p ${HOME}/local/lib64
cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64


if [ ! -d ${BNDDIR} ]
then
   echo -e "${RED}==>${NC}Condicao de contorno inexistente !"
   echo -e "${RED}==>${NC}Check ${BNDDIR} ." 
   exit 1                     
fi

ln -sf ${DATAIN}/fixed/x1.${RES}.static.nc ${SCRIPTS}
ln -sf ${DATAIN}/fixed/Vtable.${EXP} ${SCRIPTS}/Vtable
ln -sf ${EXECS}/ungrib.exe ${SCRIPTS}
cp -f ./link_grib.csh ${SCRIPTS}
cp -rf ${BNDDIR}/gfs.t00z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2 ${DATAIN}/${YYYYMMDDHHi}



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

cd ${SCRIPTS}
. setenv.bash


rm -f GRIBFILE.* namelist.wps


sed -e "s,#LABELI#,${start_date},g;s,#PREFIX#,GFS,g" \
	${DATAIN}/namelists/namelist.wps.TEMPLATE > ./namelist.wps

./link_grib.csh ${DATAIN}/${YYYYMMDDHHi}/gfs.t00z.pgrb2.0p25.f000.${YYYYMMDDHHi}.grib2


date
time mpirun -np 1 ./ungrib.exe
date


grep "Successful completion of program ungrib.exe" ${SCRIPTS}/ungrib.log >& /dev/null

if [ \$? -ne 0 ]; then
   echo "  BUMMER: Ungrib generation failed for some yet unknown reason."
   echo " "
   tail -10 ${SCRIPTS}/ungrib.log
   echo " "
   exit 21
fi

#
# clean up and remove links
#
   mv ungrib.log ${DATAOUT}/logs/ungrib.${start_date}.log
   mv namelist.wps ${DATAOUT}/logs/namelist.${start_date}.wps
   mv GFS\:${start_date:0:13} ${DATAIN}/${YYYYMMDDHHi}

   rm -f ${SCRIPTS}/ungrib.exe 
   rm -f ${SCRIPTS}/Vtable 
   rm -f ${SCRIPTS}/x1.1024002.static.nc
   rm -f ${SCRIPTS}/GRIBFILE.AAA

echo "End of degrib Job"


EOF0
chmod a+x ${SCRIPTS}/degrib.bash

echo -e  "${GREEN}==>${NC} Executing sbatch degrib.bash...\n"
cd ${SCRIPTS}
sbatch --wait ${SCRIPTS}/degrib.bash



files_ungrib=("${EXP}:${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}_${YYYYMMDDHHi:8:2}")
for file in "${files_ungrib[@]}"; do
  if [ ! -s ${DATAIN}/${YYYYMMDDHHi}/${file} ] 
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} Degrib fails! At least the file ${file} was not generated at ${DATAIN}/${YYYYMMDDHHi}. \n"
    echo -e  "${RED}==>${NC} Check logs at ${DATAOUT}/logs/debrib.* .\n"
    echo -e  "${RED}==>${NC} Exiting script. \n"
    exit -1
  fi
done

