#!/bin/bash

# run tedlium tests as batched jobs
for f in `ls /vagrant/db/TEDLIUM_release1/test/sph/*.sph`; do
  filename=$(basename "$f")
  basename="${filename%.*}"
  folder=$(dirname "$f")
  # copy stm file to same folder as sph
  cp $folder/../stm/$basename.stm $folder

  sbatch scripts/slurm-score.sh $f
done
