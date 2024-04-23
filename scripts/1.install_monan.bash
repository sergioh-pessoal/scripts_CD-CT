#!/bin/bash 

#-----------------------------------------------------------------------------#
# !SCRIPT: install_monan
#
# !DESCRIPTION:
#     Script to intall the MONAN model from a user github repositry.
#     
#     Performs the following tasks:
# 
#        o Clone the Monan model github repository v0.1.0 in a local directory
#        o Uses the "develop" branch
#        o Make the script make-all.sh that compiles the Atmosphere Model and the Init Atmosphere Model
#        o As alternative for advanced users, this scrpt creates a simple compile script that just compile the Atmosphere Model
#        o Clone the COnvert_mpas tool from the official repository for convert the output model files in lat-lon grid.
#        o COmpile the convert_mpas
#        o Post-processing (netcdf for grib2, latlon regrid, crop) (CR: to be modified to phase 4)
#
#-----------------------------------------------------------------------------#

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


# Standart directories variables:---------------------------------------
DIRHOMES=${DIR_SCRIPTS}/scripts_CD-CT;  mkdir -p ${DIRHOMES}  
DIRHOMED=${DIR_DADOS}/scripts_CD-CT;    mkdir -p ${DIRHOMED}  
SCRIPTS=${DIRHOMES}/scripts;            mkdir -p ${SCRIPTS}
DATAIN=${DIRHOMED}/datain;              mkdir -p ${DATAIN}
DATAOUT=${DIRHOMED}/dataout;            mkdir -p ${DATAOUT}
SOURCES=${DIRHOMES}/sources;            mkdir -p ${SOURCES}
EXECS=${DIRHOMED}/execs;                mkdir -p ${EXECS}
#----------------------------------------------------------------------


# Input variables:-----------------------------------------------------
github_link=https://github.com/monanadmin/MONAN-Model.git
#----------------------------------------------------------------------


# Local variables:-----------------------------------------------------
vlabel="0.4.0"
MONANDIR=${SOURCES}/MONAN-Model_${vlabel}
CONVERT_MPAS_DIR=${SOURCES}/convert_mpas
branch_name="develop"
#----------------------------------------------------------------------






if [ -d "${MONANDIR}" ]; then
    echo -e  "${GREEN}==>${NC} Source dir already exists, updating it ...\n"
else
    echo -e  "${GREEN}==>${NC} Cloning your fork repository...\n"
    git clone ${github_link} ${MONANDIR}
    if [ ! -d "${MONANDIR}" ]; then
        echo -e "${RED}==>${NC} An error occurred while cloning your fork. Possible causes:  wrong URL, user or password.\n"
        exit -1
    fi
fi

cd ${MONANDIR}
if git checkout "${branch_name}" 2>/dev/null; then
    git checkout tags/${vlabel} -b branch_v${vlabel}
    git pull
    echo -e "${GREEN}==>${NC} Successfully checked out and updated branch: ${BLUE}${branch_name} --> branch_v${vlabel}"
else
    echo -e "${RED}==>${NC} Failed to check out branch: ${BLUE}${branch_name}"
    echo -e "${RED}==>${NC} Please check if you have this branch. Exiting ..."
    exit -1
fi



#CR: TODO: maybe later move this make script to main scripts directory.
echo ""
echo -e  "${GREEN}==>${NC} Making compile script...\n"
cat << EOF > make-all.sh
#!/bin/bash
#Usage: make target CORE=[core] [options]
#Example targets:
#    ifort
#    gfortran
#    xlf
#    pgi
#Availabe Cores:
#    atmosphere
#    init_atmosphere
#    landice
#    ocean
#    seaice
#    sw
#    test
#Available Options:
#    DEBUG=true    - builds debug version. Default is optimized version.
#    USE_PAPI=true - builds version using PAPI for timers. Default is off.
#    TAU=true      - builds version using TAU hooks for profiling. Default is off.
#    AUTOCLEAN=true    - forces a clean of infrastructure prior to build new core.
#    GEN_F90=true  - Generates intermediate .f90 files through CPP, and builds with them.
#    TIMER_LIB=opt - Selects the timer library interface to be used for profiling the model. Options are:
#                    TIMER_LIB=native - Uses native built-in timers in MPAS
#                    TIMER_LIB=gptl - Uses gptl for the timer interface instead of the native interface
#                    TIMER_LIB=tau - Uses TAU for the timer interface instead of the native interface
#    OPENMP=true   - builds and links with OpenMP flags. Default is to not use OpenMP.
#    OPENACC=true  - builds and links with OpenACC flags. Default is to not use OpenACC.
#    USE_PIO2=true - links with the PIO 2 library. Default is to use the PIO 1.x library.
#    PRECISION=single - builds with default single-precision real kind. Default is to use double-precision.
#    SHAREDLIB=true - generate position-independent code suitable for use in a shared library. Default is false.


export NETCDF=${NETCDFDIR}
export PNETCDF=${PNETCDFDIR}
# PIO is not necessary for version 8.* If PIO is empty, MPAS Will use SMIOL
export PIO=


make clean CORE=atmosphere
make -j 8 gfortran CORE=atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee make-all.output

#CR: TODO: put verify here if executable was created ok
mv ${MONANDIR}/atmosphere_model ${EXECS}
mv ${MONANDIR}/build_tables ${EXECS}
make clean CORE=atmosphere

make clean CORE=init_atmosphere
make -j 8 gfortran CORE=init_atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee make-all.output

mv ${MONANDIR}/init_atmosphere_model ${EXECS}
make clean CORE=init_atmosphere


if [ -s "${EXECS}/init_atmosphere_model" ] && [ -e "${EXECS}/atmosphere_model" ]; then
    echo ""
    echo -e "${GREEN}==>${NC} Files init_atmosphere_model and atmosphere_model generated Successfully in ${EXECS} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during build. Check output"
    exit -1
fi



EOF
chmod a+x make-all.sh

cat << EOF > make.sh
#!/bin/bash
#Usage: make target CORE=[core] [options]
#Example targets:
#    ifort
#    gfortran
#    xlf
#    pgi
#Availabe Cores:
#    atmosphere
#    init_atmosphere
#    landice
#    ocean
#    seaice
#    sw
#    test
#Available Options:
#    DEBUG=true    - builds debug version. Default is optimized version.
#    USE_PAPI=true - builds version using PAPI for timers. Default is off.
#    TAU=true      - builds version using TAU hooks for profiling. Default is off.
#    AUTOCLEAN=true    - forces a clean of infrastructure prior to build new core.
#    GEN_F90=true  - Generates intermediate .f90 files through CPP, and builds with them.
#    TIMER_LIB=opt - Selects the timer library interface to be used for profiling the model. Options are:
#                    TIMER_LIB=native - Uses native built-in timers in MPAS
#                    TIMER_LIB=gptl - Uses gptl for the timer interface instead of the native interface
#                    TIMER_LIB=tau - Uses TAU for the timer interface instead of the native interface
#    OPENMP=true   - builds and links with OpenMP flags. Default is to not use OpenMP.
#    OPENACC=true  - builds and links with OpenACC flags. Default is to not use OpenACC.
#    USE_PIO2=true - links with the PIO 2 library. Default is to use the PIO 1.x library.
#    PRECISION=single - builds with default single-precision real kind. Default is to use double-precision.
#    SHAREDLIB=true - generate position-independent code suitable for use in a shared library. Default is false.


export NETCDF=${NETCDFDIR}
export PNETCDF=${PNETCDFDIR}
# PIO is not necessary for version 8.* If PIO is empty, MPAS Will use SMIOL
export PIO=


make clean CORE=atmosphere
make -j 8 gfortran CORE=atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee make-all.output

#CR: TODO: put verify here if executable was created ok
mv ${MONANDIR}/atmosphere_model ${EXECS}
mv ${MONANDIR}/build_tables ${EXECS}
make clean CORE=atmosphere

if  [ -e "${EXECS}/atmosphere_model" ]; then
    echo ""
    echo -e "${GREEN}==>${NC} Files init_atmosphere_model and atmosphere_model generated Successfully in ${EXECS} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during build. Check output"
    exit -1
fi

EOF
chmod a+x make.sh


echo ""
echo -e  "${GREEN}==>${NC} Installing init_atmosphere_model and atmosphere_model...\n"
echo ""

#CR: TODO: maybe at this point we should put our registry-file et all.
#CR: make-all.sh compile all for the first time
#CR: make.sh just compile  the A-model
. ${MONANDIR}/make-all.sh





# install convert_mpas


echo ""
echo -e  "${GREEN}==>${NC} Moduling environment for convert_mpas...\n"
module purge
module load gnu9/9.4.0
module load ohpc
module load phdf5
module load netcdf
module load netcdf-fortran
module list



echo ""
echo -e  "${GREEN}==>${NC} Cloning convert_mpas repository...\n"
cd ${SOURCES}
git clone http://github.com/mgduda/convert_mpas.git


cd ${CONVERT_MPAS_DIR}
echo ""
echo -e  "${GREEN}==>${NC} Installing convert_mpas...\n"
make clean
make  2>&1 | tee make.convert.output


#CR: TODO: put verify here if executable was created ok
mv ${CONVERT_MPAS_DIR}/convert_mpas ${EXECS}/


if [ -s "${EXECS}/convert_mpas" ] ; then
    echo ""
    echo -e "${GREEN}==>${NC} File convert_mpas generated Sucessfully in ${CONVERT_MPAS_DIR} and copied to ${EXECS} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during convert_mpas build. Check output"
    exit -1
fi



