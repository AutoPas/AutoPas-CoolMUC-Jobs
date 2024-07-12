# AutoPas-CoolMUC-Jobs
SLURM job scripts to test AutoPas on the LRZ Linux Cluster. This Readme is adapted from bachelor thesis *Improving OpenMP Loop Scheduling in AutoPas*, Appendix B.

## Setup

```
# Log into the linux cluster.
ssh -Y lxlogin1.lrz.de -l <username>

# Clone AutoPas and the Slurm job scripts:
cd $HOME && mkdir -p ba && cd ba \
&& git clone https://github.com/AutoPas/AutoPas-CoolMUC-Jobs.git \
&& git clone https://github.com/AutoPas/AutoPas.git \
&& cd AutoPas && git checkout feature/improving-openmp-loop-scheduling \
&& mkdir build && cd build

# Build MD-Flexible:
CC=`which clang` CXX=`which clang++` cmake -DMD_FLEXIBLE_USE_MPI=OFF \
-DAUTOPAS_LOG_ITERATIONS=ON .. && make -j8 md-flexible && cd ..

# Build master-branch-based MD-Flexible for explodingLiquid:
git checkout \
feature/improving-openmp-loop-scheduling-dynamic-vl-unloaded \
&& mkdir build-dvl-off && cd build-dvl-off

CC=`which clang` CXX=`which clang++` cmake -DMD_FLEXIBLE_USE_MPI=OFF \
-DAUTOPAS_LOG_ITERATIONS=ON .. && make -j8 md-flexible && cd ..
```

## Option 1: individual tests with salloc.

```
## Allocate a CoolMUC-2 job:
cd build/examples/md-flexible \
&& salloc --partition=cm2_inter --time=01:00:00

## Prioritize Auto4OMP's libomp.so:
export LD_LIBRARY_PATH=\
$HOME/ba/AutoPas/build/_deps/auto4omp-build/runtime/src\
:$LD_LIBRARY_PATH

## Make sure Auto4OMP's libomp.so is linked:
ldd md-flexible

## Configure OpenMP to use 28 parallel threads:
export OMP_NUM_THREADS=28

# Get the GPU frequency and pass it to Auto4OMP:
export KMP_CPU_SPEED=$(lscpu | grep "CPU max MHz" | \
tr -d ' ' | cut -d ":" -f2 | cut -d "." -f1)

# Optional: log Auto4OMP’s selection decisions.
## Beware, this worsens performance!
export KMP_TIME_LOOPS=./auto4omp.log

## Execute.
### The possible inputs are at AutoPas/examples/md-flexible/input.
### Pass the input file name without a path, as all inputs
### are copied directly under AutoPas/build/examples/md-flexible.
### This example tests the homogeneous lc_c08 small input
### with Auto4OMP's ExhaustiveSel.
srun ./md-flexible --openmp-kind exhaustiveSel \
--yaml-filename homogeneousLCC08Small.yaml

exit
```

## Option 2: submit a job script for a full test.
This takes a few hours per job, depending on the input. Beware, the jobs assume AutoPas is at ~/ba/AutoPas. For custom directories, the scripts have to be adjusted. This example tests the small homogeneous lc_c08 input.

```
## Move to the job's subdirectory so the logs are written there:
cd $HOME/ba/AutoPas-CoolMUC-Jobs/auto4omp/homogeneousLCC08Small \
&& sbatch homogeneousLCC08Small.sh && cd $HOME

## To track a submitted job:
squeue -M cm2_tiny

## To cancel a submitted job (replace <id> with the job's ID from sbatch or squeue):
scancel -M cm2_tiny <id>

## To summarize job outputs (assuming a single output exists per input):
INPUT_DIR=$HOME/ba/AutoPas-CoolMUC-Jobs/auto4omp/homogeneousLCC08Small \
&& grep $INPUT_DIR/$(ls $INPUT_DIR | grep ".out" -m 1) \
-e == -e LCC -e VCL -e VLP -e Simulate

## To summarize Auto4OMP's log (e.g., exhaustiveSel):
### (prints the number of times each scheduling technique was used.)
KMP_LOG=$INPUT_DIR/auto-3.log \
&& echo "static:" && grep -o " STATIC " $KMP_LOG | wc -l \
&& echo "dynamic:" && grep -o " SS " $KMP_LOG | wc -l \
&& echo "trapezoidal:" && grep -o " TSS " $KMP_LOG | wc -l \
&& echo "auto:" && grep -o "LLVM" $KMP_LOG | wc -l \
&& echo "guided:" && grep -o " GSS " $KMP_LOG | wc -l \
&& echo "steal:" && grep -o " Steal " $KMP_LOG | wc -l \
&& echo "fac2a:" && grep -o " mFac2 " $KMP_LOG | wc -l \
&& echo "awf_b:" && grep -o " AWF-B " $KMP_LOG | wc -l \
&& echo "awf_c:" && grep -o " AWF-C " $KMP_LOG | wc -l \
&& echo "awf_d:" && grep -o " AWF-D " $KMP_LOG | wc -l \
&& echo "awf_e:" && grep -o " AWF-E " $KMP_LOG | wc -l \
&& echo "af_a:" && grep -o " mAF " $KMP_LOG | wc -l
```
