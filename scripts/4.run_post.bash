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
export SCRIPTS=${DIRHOMES}/scripts;    mkdir -p ${SCRIPTS}
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
maxpost=30
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


# EGK: implementacao do paralelismo de MONAN-scripts/egeon_oper para a tarefa 488 pensando em 241 saidas.

# laco para checar nome dos arquivos de saida
for i in $(seq 0 $FCST)
do
   echo "i=$i"
   # add i to datai
   hh=${YYYYMMDDHHi:8:2}
   currentdate=`date -d "${YYYYMMDDHHi:0:8} ${hh}:00 ${i} hours" +"%Y%m%d%H"`
   echo "${currentdate}"
#   diag_name=diag.${currentdate:0:4}-${currentdate:4:2}-${currentdate:6:2}_${currentdate:8:2}.00.00.nc
   diag_name=MONAN_DIAG_G_MOD_GFS_${YYYYMMDDHHi}_${currentdate}.00.00.x${RES}L55.nc
   echo "diag_name=${diag_name}"
#  post_name=$(echo "${outputfile}" | sed -e "s,_MOD_,_POS_,g")
done

# cria diretorios e arquivos/links para cada saida do convert_mpas
for i in $(seq 0 $FCST)
do
  cd ${SCRIPTS}
  mkdir -p ${SCRIPTS}/dir.${i}
  cd ${SCRIPTS}/dir.${i}

  ln -sf ${DATAIN}/namelists/include_fields.diag  ${SCRIPTS}/dir.${i}/include_fields.diag
  ln -sf ${DATAIN}/namelists/convert_mpas.nml ${SCRIPTS}/dir.${i}/convert_mpas.nml
  ln -sf ${DATAIN}/namelists/target_domain ${SCRIPTS}/dir.${i}/target_domain

  rm -rf ${SCRIPTS}/dir.${i}/convert_mpas
  ln -sf ${EXECS}/convert_mpas ${SCRIPTS}/dir.${i}
  ln -sf ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ${SCRIPTS}/dir.${i}
done

cd ${SCRIPTS}

cat > PostAtmos_exe.sh <<EOF0
#!/bin/bash
#SBATCH --job-name=PostAtmos
#SBATCH --nodes=8
#SBATCH --partition=${POST_QUEUE}
#SBATCH --tasks-per-node=32
#SBATCH --time=4:00:00
#SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/post.bash.o%j    # File name for standard output
#SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/post.bash.e%j     # File name for standard error output
#SBATCH --exclusive

. ${SCRIPTS}/setenv.bash
. ${SCRIPTS}/setenv_python.bash

datai=$YYYYMMDDHHi
resolution=$RES

aux=$(echo "$FCST/2" | bc)
aux1=$(echo "$FCST/2+1" | bc)
echo "aux=\$aux"
echo "aux1=\$aux1"

# primeira metade das saidas
for i in \$(seq 0 \$aux)
do
   hh=\${datai:8:2}
   currentdate=\`date -d "\${datai:0:8} \${hh}:00 \${i} hours" +"%Y%m%d%H"\`
   diag_name=MONAN_DIAG_G_MOD_GFS_\${datai}_\${currentdate}.00.00.x\${resolution}L55.nc

   cd ${SCRIPTS}/dir.\${i}
   rm -f include_fields
   cp include_fields.diag include_fields
   rm -f latlon.nc

   time ./convert_mpas x1.\${resolution}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/\$diag_name  > saida.txt & 
   echo "./convert_mpas x1.\${resolution}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/\$diag_name"

done

# necessario aguardar as rodadas em background
wait

# metade final das saidas
for i in \$(seq \$aux1 $FCST)
do
   hh=\${datai:8:2}
   currentdate=\`date -d "\${datai:0:8} \${hh}:00 \${i} hours" +"%Y%m%d%H"\`
   diag_name=MONAN_DIAG_G_MOD_GFS_\${datai}_\${currentdate}.00.00.x\${resolution}L55.nc

   cd ${SCRIPTS}/dir.\${i}
   rm -f include_fields
   cp include_fields.diag include_fields
   rm -f latlon.nc

   time ./convert_mpas x1.\${resolution}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/\$diag_name  > saida.txt &
   echo "./convert_mpas x1.\${resolution}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/\$diag_name"

done

# necessario aguardar as rodadas em background
wait

for i in \$(seq 0 $FCST)
do
   cd ${SCRIPTS}/dir.\${i}
   python ${SCRIPTS}/group_levels.py ${SCRIPTS}/dir.\${i} latlon.nc latlon_\${i}.nc > saida_python.txt &
done

wait

# unload the python's environment
deactivate

cd ${DATAOUT}/${YYYYMMDDHHi}/Post/
rm -f diag* latlon*

for i in \$(seq 0 $FCST)
do
   mv ${SCRIPTS}/dir.\$i/latlon_\${i}.nc ./latlon_\$i.nc 
done

#find . -maxdepth 1 -name "latlon_*" | sort -n -t _ -k 2 | cut -c3- | sed ':a;$!N;s/\n//;ta;' | sed 's/nc/nc /g' | xargs ncrcat -o latlon.nc
find . -maxdepth 1 -name "latlon_*" | sort -n -t _ -k 2 | cut -c3- | sed ':a;$!N;s/\n//;ta;' | sed 's/nc/nc /g' | xargs -I "{}"  cdo mergetime {} latlon.nc

#cdo settunits,hours -settaxis,${START_DATE_YYYYMMDD},${START_HH}:00,1hour latlon.nc diagnostics_${START_DATE_YYYYMMDD}.nc
cdo settunits,hours -settaxis,${START_DATE_YYYYMMDD},${START_HH}:00,1hour latlon.nc MONAN_DIAG_G_POS_${EXP}_${YYYYMMDDHHi}.00.00.x${RES}L55.nc


# remove temporary latlon_i.nc files generated by group_levels.py
for i in \$(seq 0 $FCST)
do
   rm -rf ${DATAOUT}/${YYYYMMDDHHi}/Post/latlon_\${i}.nc
done

rm -rf ${SCRIPTS}/dir.* ${DATAOUT}/${YYYYMMDDHHi}/Post/latlon.nc

exit 0
EOF0


chmod +x PostAtmos_exe.sh

sbatch --wait ${SCRIPTS}/PostAtmos_exe.sh

rm -f ${SCRIPTS}/PostAtmos_exe.sh


# EGK: fim da implementacao do paralelismo de MONAN-scripts/egeon_oper para a tarefa 488.




## TODO: CR: finalizar implementacao

##how_many_nodes ${FCST} ${maxpost}
##
##cd  ${SCRIPTS}
##comando=$(ls -1 MONAN_*MOD*nc)
##nfiles=(${comando})
##
##if [ ${how_many_nodes_int} -eq 1 -a ${how_many_nodes_left} -eq 0 ]
##then  
##  maxpost=${FCST}
##fi
##
##ifi=0
##for nsubs in  $(seq 1 ${how_many_nodes_int})
##do
##  cd ${SCRIPTS}
##  iin=$(echo "${ifi}+1" | bc)
##  ifi=$(echo "${nsubs}*${maxpost}" | bc)
##  echo "nsubi = ${nsubs}, ${iin} - ${ifi}"
##
##
##rm -f ${SCRIPTS}/post_${nsubs}.bash 
##cat << EOF0 > ${SCRIPTS}/post_${nsubs}.bash 
###!/bin/bash
###SBATCH --job-name=${POST_jobname}
###SBATCH --nodes=${POST_nnodes}
###SBATCH --ntasks=${POST_ncores}
###SBATCH --tasks-per-node=${POST_ncpn}
###SBATCH --partition=${POST_QUEUE}
###SBATCH --time=${POST_walltime}
###SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/post_${nsubs}.bash.o%j    # File name for standard output
###SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/post_${nsubs}.bash.e%j     # File name for standard error output
##
##cd  ${SCRIPTS}
##comando=\$(ls -1 MONAN_*MOD*nc)
##nfiles=(\${comando})
##
##
##  for outputfile in \$(seq ${iin} ${ifi})
##  do
##    echo "     \${outputfile} :: \${nfiles[\${outputfile}]}"
##  done
##
##
##
##
##
##EOF0
##chmod a+x ${SCRIPTS}/post_${nsubs}.bash 
##sbatch ${SCRIPTS}/post_${nsubs}.bash 
##
##
##
##
##done
##
##maxpost=30
##for nsubs in  $(seq 1 ${how_many_nodes_left})
##do
##  iin=$(echo "${ifi}+1" | bc)
##  ifi=$(echo "${ifi}+${rest}" | bc)
##  echo "nsubl = ${nsubs}, ${iin} - ${ifi}"
##
##  for outputfile in $(seq ${iin} ${ifi})
##  do
##    echo "     ${outputfile} :: ${nfiles[${outputfile}]}"
##  done
##done
##
##
##
##exit
##
##
##
###for nsubs in  $(seq 1 ${how_many_nodes})
###do 
##
##  cd  ${DATAOUT}/${YYYYMMDDHHi}/Model
##for outputfile in MONAN_*MOD*nc
###for outputfile in MONAN_DIAG_G_MOD_GFS_2024010100_2024010100.00.00.x1024002L55.nc
##do
##  echo ${outputfile}
##  cd ${SCRIPTS}
##  mkdir -p ${SCRIPTS}/dir.${outputfile}.dir
##  cd ${SCRIPTS}/dir.${outputfile}.dir
##
##  ln -sf ${DATAIN}/namelists/include_fields.diag  ${SCRIPTS}/dir.${outputfile}.dir/include_fields
##  ln -sf ${DATAIN}/namelists/convert_mpas.nml ${SCRIPTS}/dir.${outputfile}.dir/convert_mpas.nml
##  ln -sf ${DATAIN}/namelists/target_domain ${SCRIPTS}/dir.${outputfile}.dir/target_domain
##
##  ln -sf ${EXECS}/convert_mpas ${SCRIPTS}/dir.${outputfile}.dir
##  ln -sf ${DATAOUT}/${YYYYMMDDHHi}/Pre/x1.${RES}.init.nc ${SCRIPTS}/dir.${outputfile}.dir
##  post_name=$(echo "${outputfile}" | sed -e "s,_MOD_,_POS_,g")
##  
##  rm -f ${SCRIPTS}/dir.${outputfile}.dir/post.bash 
##cat << EOF0 > ${SCRIPTS}/dir.${outputfile}.dir/post.bash 
###!/bin/bash
###SBATCH --job-name=${POST_jobname}
###SBATCH --nodes=${POST_nnodes}
###SBATCH --ntasks=${POST_ncores}
###SBATCH --tasks-per-node=${POST_ncpn}
###SBATCH --partition=${POST_QUEUE}
###SBATCH --time=${POST_walltime}
###SBATCH --output=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/post.bash.o%j    # File name for standard output
###SBATCH --error=${DATAOUT}/${YYYYMMDDHHi}/Post/logs/post.bash.e%j     # File name for standard error output
####SBATCH --exclusive
###SBATCH --mem=32000
##
##
##export executable=convert_mpas
##
##ulimit -c unlimited
##ulimit -v unlimited
##ulimit -s unlimited
##
##. ${SCRIPTS}/setenv.bash
##
##cd ${SCRIPTS}/dir.${outputfile}.dir
##
##rm -f latlon.nc
##date
##time ./\${executable} x1.${RES}.init.nc ${DATAOUT}/${YYYYMMDDHHi}/Model/${outputfile}
##date
##mv latlon.nc ${DATAOUT}/${YYYYMMDDHHi}/Post/${post_name}
##
### DE: TODO DO NOT NEED WITH NEW CONVERT_MPAS - REMOVE COMMENT
### cdo settunits,hours -settaxis,${YYYYMMDDHHi:0:8},${YYYYMMDDHHi:9:2}:00,1hour latlon.nc ${DATAOUT}/${YYYYMMDDHHi}/Post/${post_name}
##
##rm -fr ${SCRIPTS}/dir.${outputfile}.dir
##
##EOF0
##  chmod a+x ${SCRIPTS}/dir.${outputfile}.dir/post.bash
##
##  #echo -e  "${GREEN}==>${NC} Submitting MONAN atmosphere model Post-processing and waiting for finish before exit... \n"
##  #echo -e  "${GREEN}==>${NC} Logs being generated at ${DATAOUT}/logs... \n"
##  echo -e  "sbatch ${SCRIPTS}/dir.${outputfile}.dir/post.bash"
##  echo ""
##  sbatch ${SCRIPTS}/dir.${outputfile}.dir/post.bash
##  sleep 1
##  echo ""
##done
##
### DE: TODO - CONCATENATE FILES
### cdo settunits,hours -settaxis,${YYYYMMDDHHi:0:8},${YYYYMMDDHHi:9:2}:00,1hour latlon.nc diagnostics_${YYYYMMDDHHi:0:8}.nc
