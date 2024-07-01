# AutoPas-CoolMUC-Jobs
SLURM job scripts to test AutoPas on the LRZ Linux Cluster.

Setup: clone AutoPas and build MD-Flexible.

To submit a job, enter the following command from the project's root directory:
cd \<test\>/\<job\> && sbatch \<job\>.sh && cd ../..

Replace \<test\> with the desired test (e.g., auto4omp), and \<job\> with the desired SLURM job name (same as the sub-directory names under <test>).

