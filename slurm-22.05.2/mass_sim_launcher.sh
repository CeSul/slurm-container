#!/bin/bash

#for i in `seq 0 81`
for i in `seq 0 1`
do

container_name="carc/slurm_vc:slurm-22.05.2_winter_conf_changes"
container_id=$(docker run --detach --rm -it -e SLURM_NUMNODES=78 $container_name)
outlog=job_log_${i}_${container_id}
echo "Look for logs in $outlog"

sleep 20
echo "Container started"
docker container exec $container_id /opt/slurm/bin/sinfo

echo "updating slurm.conf"
docker container exec -w"/home/spack" $container_id \
python3 slurm.conf_generator.py -s $i -f /opt/slurm/etc/slurm.conf > $outlog

# make slurm daemons reread updated slurm.conf
docker container exec  $container_id /opt/slurm/bin/scontrol reconfigure 
sleep 10

echo "Launching jobs"
docker container exec -w"/home/spack" \
--env LD_PRELOAD=/usr/lib64/libfaketime/libfaketime.so.1 \
--env FAKETIME_TIMESTAMP_FILE=/etc/faketimerc \
$container_id python3 create_slurm_jobs.py &>> $outlog &

#time=$(date "+%Y-%m-%d %T"); echo "@$time x100" > faketimerc
#sleep 20
#kecho "Time to liven things up"
#docker container cp faketimerc ${container_id}:/etc/faketimerc
done
