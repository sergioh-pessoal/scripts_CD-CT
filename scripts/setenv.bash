#!/bin/bash

# Load modules:

module purge
module load ohpc
module unload openmpi4
module load phdf5
module load netcdf 
module load netcdf-fortran 
module load mpich-4.0.2-gcc-9.4.0-gpof2pv
module load hwloc
module load phdf5
module load cdo-2.0.4-gcc-9.4.0-bjulvnd
module load opengrads-2.2.1
module list







# Set environment variables and importants directories


# MONAN-suite install root directories:
export DIRWORK=$(pwd)   # old one will not be used any more
export DIR_SCRIPTS=/mnt/beegfs/carlos.souza/repo_Monan/dirscripts
export DIR_DADOS=/mnt/beegfs/carlos.souza/repo_Monan/dirdados

# Others variables:
export OMP_NUM_THREADS=1
export OMPI_MCA_btl_openib_allow_ib=1
export OMPI_MCA_btl_openib_if_include="mlx5_0:1"
export PMIX_MCA_gds=hash
export MPI_PARAMS="-iface ib0 -bind-to core -map-by core"

# Libraries paths:
export NETCDF=/mnt/beegfs/monan/libs/netcdf
export PNETCDF=/mnt/beegfs/monan/libs/PnetCDF
export NETCDFDIR=${NETCDF}
export PNETCDFDIR=${PNETCDF}
export DIRDADOS=/mnt/beegfs/monan/dados/MONAN_v0.1.0
export OPERDIR=/oper/dados/ioper/tempo




# Submiting variables:--------------------------------------------------

# PRE-Static phase:
export STATIC_QUEUE="batch"
export STATIC_ncores=32
export STATIC_nnodes=1
export STATIC_ncpn=32
export STATIC_jobname="Pre.static"
export STATIC_walltime="02:00:00"

# PRE-Degrib phase:
export DEGRIB_QUEUE="batch"
export DEGRIB_ncores=1
export DEGRIB_nnodes=1
export DEGRIB_ncpn=1
export DEGRIB_jobname="Pre.degrib"
export DEGRIB_walltime="00:30:00"

# PRE-Init Atmosphere phase:
export INITATMOS_QUEUE="batch"
export INITATMOS_ncores=32
export INITATMOS_nnodes=1
export INITATMOS_ncpn=
export INITATMOS_jobname="Pre.InitAtmos"
export INITATMOS_walltime="01:00:00"

# Model phase:
export MODEL_QUEUE=batch
export MODEL_ncores=1024
export MODEL_nnodes=16
export MODEL_ncpn=64
export MODEL_jobname="Model.MONAN"
export MODEL_walltime="4:00:00"

# Post phase:
export POST_QUEUE="batch"
export POST_ncores=1
export POST_nnodes=1
export POST_ncpn=1
export POST_jobname="Post.MONAN"
export POST_walltime="8:00:00"


# Products phase:
export PRODS_QUEUE="batch"
export PRODS_ncores=1
export PRODS_nnodes=1
export PRODS_ncpn=1
export PRODS_jobname="Prods.MONAN"
export PRODS_walltime="8:00:00"


#-----------------------------------------------------------------------




# Colors:
export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color
export BLUE='\033[01;34m'  # Blue
