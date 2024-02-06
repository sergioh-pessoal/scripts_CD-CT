#!/bin/bash -x


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

# Standart directories variables:
DIRHOME=$(pwd)/../../MONAN;   rm -fr ${DIRHOME}; mkdir -p ${DIRHOME}
SCRIPTS=${DIRHOME}/scripts;   mkdir -p ${SCRIPTS}
DATAIN=${DIRHOME}/datain;     mkdir -p ${DATAIN}
DATAOUT=${DIRHOME}/dataout;   mkdir -p ${DATAOUT}
SOURCES=${DIRHOME}/sources;   mkdir -p ${SOURCES}
EXECS=${DIRHOME}/execs;       mkdir -p ${EXECS}

# Set environment variables exports:
. setenv.bash



# Input variables:
github_link=${1}
