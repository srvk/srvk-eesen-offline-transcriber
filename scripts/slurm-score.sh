#!/bin/bash

#SBATCH -s
#SBATCH -n 1
#SBATCH -o /vagrant/log/%j.log
#SBATCH -D /home/vagrant/bin
#SBATCH --get-user-env
# runs slurm-score.sh as a SLURM batch job

filename=$(basename "$1")
basename="${filename%.*}"

echo "Starting at `date`, in `pwd`"
echo "input file is" ${1}
~/bin/run-scored.sh ${1}

echo "Done ($?) at `date`, ran on $SLURM_NODELIST ($SLURM_NNODES, $SLURM_NPROCS)"
