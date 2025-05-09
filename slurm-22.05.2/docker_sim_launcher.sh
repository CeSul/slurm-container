#!/bin/bash

#job_data='winter2025_epyc64_10days'

container_id=$(docker run --detach --rm -it -e SLURM_NUMNODES=171 carc/slurm_vc:slurm-22.05.2_winter)

sleep 60

echo "Container started"
docker container exec $container_id /opt/slurm-22.05.2/bin/sinfo

#docker container cp $job_data ${container_id}:/home/spack/slurm_anon_epyc64_10days

sleep 60

echo "Launching jobs"
docker container exec -w"/home/spack" \
--env LD_PRELOAD=/usr/lib64/libfaketime/libfaketime.so.1 \
--env FAKETIME_TIMESTAMP_FILE=/etc/faketimerc \
$container_id python3 create_slurm_jobs.py > joblog_${container_id} &

#time=$(date "+%Y-%m-%d %T"); echo "@$time x100" > faketimerc
#sleep 20
#kecho "Time to liven things up"
#docker container cp faketimerc ${container_id}:/etc/faketimerc
