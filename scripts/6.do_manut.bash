#!/bin/bash 
#-----------------------------------------------------------------------------#
# !SCRIPT: do_manut
#
# !DESCRIPTION:
#     Script that maintains the MONAN model suite healthy.
#     
#     Performs the following tasks:
# 
#        o Feeds public areas (FTP) with important files (figures, outputs,
#           clippings, etc.)
#        o Removes temporary files with no value that are eventually generated 
#           during integration.
#        o Performs maintenance on the area occupied by the model, moving old 
#           outputs to their destination area.
#        
#
#-----------------------------------------------------------------------------#


if [ $# -ne 0 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0}  "
   echo ""

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
#-------------------------------------------------------
cp -f setenv.bash ${SCRIPTS}


# Local variables--------------------------------------
#-------------------------------------------------------
