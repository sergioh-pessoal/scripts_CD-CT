#!/bin/bash 


#if [ $# -ne 1 ]
#then
#   echo ""
#   echo "Instructions: execute the command below"
#   echo ""
#   echo "${0} [G]"
#   echo ""
#   echo "G   :: GitHub link for your personal fork, eg: https://github.com/MYUSER/MONAN-Model.git"
#   exit
#fi

# Set environment variables exports:
echo ""
echo -e "\033[1;32m==>\033[0m Moduling environment for MONAN model...\n"
. setenv.bash


# Standart directories variables:
DIRHOME=${DIRWORK}/../../MONAN;   rm -fr ${DIRHOME}; mkdir -p ${DIRHOME}  #CR: Remove rmdir after all is developed (or not?)!
SCRIPTS=${DIRHOME}/scripts;   mkdir -p ${SCRIPTS}
DATAIN=${DIRHOME}/datain;     mkdir -p ${DATAIN}
DATAOUT=${DIRHOME}/dataout;   mkdir -p ${DATAOUT}
SOURCES=${DIRHOME}/sources;   mkdir -p ${SOURCES}
EXECS=${DIRHOME}/execs;       mkdir -p ${EXECS}



# Input variables:-----------------------------------------------------
# for script 1:
github_link=${1}; github_link=https://github.com/carlosrenatosouza2/MONAN-Model_CR.git

# for script 2:
EXP=${1};      EXP=GFS
RES=${2};      RES=1024002
LABELI=${3};   LABELI=2024010100 
FCST=${4};     FCST=24
#----------------------------------------------------------------------


# STEP 1: Installing and compiling the A-MONAN model and utility programs:

1.install_monan.bash ${github_link}



# STEP 2: Executing the pre-processing fase. Preparing all CI/CC files needed:

2.pre_processing.bash ${EXP} ${RES} ${LABELI} ${FCST} 


