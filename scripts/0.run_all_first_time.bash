#!/bin/bash 


if [ $# -ne 5 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} GitHubUserRepo EXP_NAME RESOLUTION LABELI FCST"
   echo ""
   echo "GitHubUserRepo :: GitHub link for your personal fork, eg: https://github.com/MYUSER/MONAN-Model.git"
   echo "EXP_NAME       :: Forcing: GFS"
   echo "RESOLUTION     :: number of points in resolution model grid, e.g: 1024002  (24 km)"
   echo "LABELI         :: Initial date YYYYMMDDHH, e.g.: 2024010100"
   echo "FCST           :: Forecast hours, e.g.: 24 or 36, etc."
   echo ""
   echo "24 hour forcast example:"
   echo "${0} https://github.com/MYUSER/MONAN-Model.git GFS 1024002 2024010100 24"
   echo ""
   exit
fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash


# Standart directories variables:
DIRHOME=${DIRWORK}/../../MONAN;  rm -fr ${DIRHOME}; mkdir -p ${DIRHOME}  #CR: Remove rmdir when develope its done. (or not?)!
SCRIPTS=${DIRHOME}/scripts;      mkdir -p ${SCRIPTS}
DATAIN=${DIRHOME}/datain;        mkdir -p ${DATAIN}
DATAOUT=${DIRHOME}/dataout;      mkdir -p ${DATAOUT}
SOURCES=${DIRHOME}/sources;      mkdir -p ${SOURCES}
EXECS=${DIRHOME}/execs;          mkdir -p ${EXECS}



# Input variables:-----------------------------------------------------
github_link=${1}; #github_link=https://github.com/carlosrenatosouza2/MONAN-Model_CR.git
EXP=${2};         #EXP=GFS
RES=${3};         #RES=1024002
YYYYMMDDHHi=${4}; #YYYYMMDDHHi=2024012000
FCST=${5};        FCST=24
#----------------------------------------------------------------------


# STEP 1: Installing and compiling the A-MONAN model and utility programs:

1.install_monan.bash ${github_link}



# STEP 2: Executing the pre-processing fase. Preparing all CI/CC files needed:

2.pre_processing.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 



# STEP 3: Executing the Model run:

3.run_model.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 



# STEP 4: Executing the Post of Model run:

4.run_post.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 


# STEP 5: Executing the Products

5.run_products.bash ${EXP} ${RES} ${YYYYMMDDHHi} ${FCST} 
