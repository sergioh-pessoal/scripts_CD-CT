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
   echo "${0} GFS   40962 2024010100 48"
   echo ""

   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash


# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT; mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;   mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;           mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;             mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;           mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;           mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;               mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:--------------------------------------
EXP=${1};         #EXP=GFS
RES=${2};         #RES=1024002
YYYYMMDDHHi=${3}; #YYYYMMDDHHi=2024012000
FCST=${4};        #FCST=6
#-------------------------------------------------------


# Local variables--------------------------------------
START_DATE_YYYYMMDD="${YYYYMMDDHHi:0:4}-${YYYYMMDDHHi:4:2}-${YYYYMMDDHHi:6:2}"
START_HH="${YYYYMMDDHHi:8:2}"
#-------------------------------------------------------
mkdir -p ${DATAOUT}/${YYYYMMDDHHi}/Post/logs


files_needed=("${DATAIN}/namelists/include_fields.diag" "${DATAIN}/namelists/convert_mpas.nml" "${DATAIN}/namelists/target_domain" "${EXECS}/convert_mpas" "${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc")
for file in "${files_needed[@]}"
do
  if [ ! -s "${file}" ]
  then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} [${0}] At least the file ${file} was not generated. \n"
    exit -1
  fi
done




cd  ${DATAOUT}/${YYYYMMDDHHi}/Model
for outputfile in MONAN_DIAG_*nc
#for outputfile in MONAN_DIAG_G_MOD_GFS_2024010100_2024010100.00.00.x1024002L55.nc
do
  echo ${outputfile}
  cd ${SCRIPTS}
  mkdir -p ${SCRIPTS}/dir.${outputfile}.dir
  cd ${SCRIPTS}/dir.${outputfile}.dir

  ln -sf ${DATAIN}/namelists/include_fields.diag  ${SCRIPTS}/dir.${outputfile}.dir/include_fields
  ln -sf ${DATAIN}/namelists/convert_mpas.nml ${SCRIPTS}/dir.${outputfile}.dir/convert_mpas.nml
  ln -sf ${DATAIN}/namelists/target_domain ${SCRIPTS}/dir.${outputfile}.dir/target_domain

  ln -sf ${EXECS}/convert_mpas ${SCRIPTS}/dir.${outputfile}.dir
  ln -sf ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ${SCRIPTS}/dir.${outputfile}.dir
  post_name=$(echo "${outputfile}" | sed -e "s,_MOD_,_POS_,g")
  
  rm -f ${SCRIPTS}/dir.${outputfile}.dir/post.bash 
cat << EOF0 > ${SCRIPTS}/dir.${outputfile}.dir/post.bash 
#!/bin/bash
#SBATCH --job-name=${POST_jobname}
#SBATCH --nodes=${POST_nnodes}
#SBATCH --ntasks=${POST_ncores}
#SBATCH --tasks-per-node=${POST_ncpn}
#SBATCH --partition=${POST_QUEUE}
#SBATCH --time=${POST_walltime}
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/post.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/post.bash.e%j     # File name for standard error output
##SBATCH --exclusive
#SBATCH --mem=32000


export executable=convert_mpas

ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

. ${SCRIPTS}/setenv.bash

cd ${SCRIPTS}/dir.${outputfile}.dir

rm -f latlon.nc
date
time ./\${executable} x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/${outputfile}
date
mv latlon.nc ${DATAOUT}/${YYYYMMDDHHi}/Post/${post_name}

# DE: TODO DO NOT NEED WITH NEW CONVERT_MPAS - REMOVE COMMENT
# cdo settunits,hours -settaxis,${YYYYMMDDHHi:0:8},${YYYYMMDDHHi:9:2}:00,1hour latlon.nc ${DATAOUT}/${YYYYMMDDHHi}/Post/${post_name}

rm -fr ${SCRIPTS}/dir.${outputfile}.dir

EOF0
  chmod a+x ${SCRIPTS}/dir.${outputfile}.dir/post.bash

  #echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model Post-processing and waiting for finish before exit... \n"
  #echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/logs... \n"
  echo -e  "sbatch ${SCRIPTS}/dir.${outputfile}.dir/post.bash"
  echo ""
  sbatch ${SCRIPTS}/dir.${outputfile}.dir/post.bash
  sleep 1
  echo ""
done

# DE: TODO - CONCATENATE FILES
# cdo settunits,hours -settaxis,${YYYYMMDDHHi:0:8},${YYYYMMDDHHi:9:2}:00,1hour latlon.nc diagnostics_${YYYYMMDDHHi:0:8}.nc
