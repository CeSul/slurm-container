#!/bin/bash

job_data='winter2025_epyc64_10days'

container_id=$(docker run --detach --rm -it -e SLURM_NUMNODES=171 carc/slurm_vc:slurm-22.05.2_winter)

#docker container cp $job_data ${container_id}:/home/spack/slurm_anon_epyc64_10days

docker container exec -w"/home/spack" $container_id python3 create_slurm_jobs.py 
