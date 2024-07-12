#!/bin/bash
#SBATCH -J hetvlp08
#SBATCH -o ./%x.%j.%N.out
#SBATCH -D ./
#SBATCH --get-user-env
#SBATCH --clusters=cm2_tiny
#SBATCH --nodes=1
#SBATCH --mail-type=end
#SBATCH --mail-user=<!!! user email here !!!>
#SBATCH --export=ALL
#SBATCH --time=07:20:00
module load slurm_setup gcc llvm cmake ninja python doxygen graphviz automake sqlite hwloc cuda

# Variables:

AUTOPAS_BUILD=\
$HOME/ba/AutoPas/build

AUTOPAS_MD_FLEXIBLE=\
$AUTOPAS_BUILD/examples/md-flexible/md-flexible

AUTOPAS_YAML_INPUT=\
heterogeneousVLPC08

AUTOPAS_YAML_FILENAME=\
$AUTOPAS_BUILD/examples/md-flexible/$AUTOPAS_YAML_INPUT.yaml

AUTOPAS_MD_FLEXIBLE_COMMAND=\
"srun $AUTOPAS_MD_FLEXIBLE --openmp-kind runtime --log-level info --no-progress-bar true --yaml-filename $AUTOPAS_YAML_FILENAME"

AUTOPAS_AUTO4OMP_LOG=\
$HOME/ba/AutoPas-CoolMUC-Jobs/auto4omp/$AUTOPAS_YAML_INPUT

# List of dynamic chunk sizes to test [1].
declare -a AUTOPAS_CHUNK_SIZES=\
("1" "2" "4" "8" "16" "32" "64" "128" "256" "512" "1024" "2048" "4096")

# List of Auto4OMP selection methods to test [1].
declare -a AUTOPAS_AUTO4OMP_METHODS=\
("2" "3" "4" "5")

# Preparation:

export LD_LIBRARY_PATH=$AUTOPAS_BUILD/_deps/auto4omp-build/runtime/src:$LD_LIBRARY_PATH
export OMP_NUM_THREADS=28
mkdir -p $AUTOPAS_AUTO4OMP_LOG

# Get the GPU frequency and pass it to Auto4OMP.
CPU_MAX_MHZ=$(lscpu | grep "CPU max MHz" | tr -d ' ' | cut -d ":" -f2 | cut -d "." -f1)
export KMP_CPU_SPEED=$CPU_MAX_MHZ
echo "KMP_CPU_SPEED:"
printenv KMP_CPU_SPEED

ldd $AUTOPAS_MD_FLEXIBLE
echo ""
echo "========================================================"
echo "$AUTOPAS_YAML_INPUT input config"
echo "========================================================"
cat $AUTOPAS_YAML_FILENAME

# Testing:

# Test dynamic scheduling with the different chunk sizes.
for AUTOPAS_CHUNK in "${AUTOPAS_CHUNK_SIZES[@]}"
do
    echo ""
    echo "========================================================"
    echo "$AUTOPAS_YAML_INPUT: dynamic,$AUTOPAS_CHUNK"
    echo "========================================================"
    OMP_SCHEDULE=dynamic,$AUTOPAS_CHUNK $AUTOPAS_MD_FLEXIBLE_COMMAND --output-suffix $AUTOPAS_YAML_INPUT-dynamic$AUTOPAS_CHUNK
done

# Test standard OpenMP's auto scheduling.
echo ""
echo "========================================================"
echo "$AUTOPAS_YAML_INPUT: auto,1"
echo "========================================================"
OMP_SCHEDULE=auto,1 $AUTOPAS_MD_FLEXIBLE_COMMAND --output-suffix $AUTOPAS_YAML_INPUT-auto1

# Test Auto4OMP's selection methods.
for AUTOPAS_CHUNK in "${AUTOPAS_AUTO4OMP_METHODS[@]}"
do
    echo ""
    echo "========================================================"
    echo "$AUTOPAS_YAML_INPUT: auto,$AUTOPAS_CHUNK"
    echo "========================================================"
    OMP_SCHEDULE=auto,$AUTOPAS_CHUNK $AUTOPAS_MD_FLEXIBLE_COMMAND --output-suffix $AUTOPAS_YAML_INPUT-auto$AUTOPAS_CHUNK
done

# Test and log Auto4OMP's selection methods. Logging performs worse, so do separately.
for AUTOPAS_CHUNK in "${AUTOPAS_AUTO4OMP_METHODS[@]}"
do
    echo ""
    echo "========================================================"
    echo "$AUTOPAS_YAML_INPUT: log auto,$AUTOPAS_CHUNK"
    echo "========================================================"
    OMP_SCHEDULE=auto,$AUTOPAS_CHUNK KMP_TIME_LOOPS=$AUTOPAS_AUTO4OMP_LOG/auto-$AUTOPAS_CHUNK.log $AUTOPAS_MD_FLEXIBLE_COMMAND --output-suffix $AUTOPAS_YAML_INPUT-logauto$AUTOPAS_CHUNK
done

# Sources:
## [1] https://stackoverflow.com/a/8880633
