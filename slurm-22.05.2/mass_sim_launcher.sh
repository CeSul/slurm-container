#!/bin/bash

container_name_list=()
echo "Starting up containers..."
first_container_id=40
last_container_id=59
for i in `seq $first_container_id $last_container_id`
do
	
	
	echo $i
	container_name="carc/slurm_vc:slurm-22.05.2_winter_conf_changes"
	container_id=$(docker run --detach --rm -it -e SLURM_NUMNODES=78 $container_name)
	container_name_list+="$container_id "
	echo $container_id
	
done

echo "Give them a moment to start up slurm..."
#sleep 90
sleep 1
echo ""

i=$first_container_id
for container_id in $container_name_list
do
	outlog=job_log_${i}_${container_id}
	echo "Look for logs in $outlog"
	
	docker container exec $container_id /opt/slurm/bin/sinfo
	
	echo "updating slurm.conf"
	docker container exec -w"/home/spack" $container_id \
		python3 slurm.conf_generator.py -s $i -f /opt/slurm/etc/slurm.conf > $outlog
	
	# make slurm daemons reread updated slurm.conf
	echo "Reconfiguring for new slurm.conf"
	docker container exec  $container_id /opt/slurm/bin/scontrol reconfigure 
	sleep 10
	
	echo "Launching jobs"
	echo ""

	docker container exec -w"/home/spack" \
		--env LD_PRELOAD=/usr/lib64/libfaketime/libfaketime.so.1 \
		--env FAKETIME_TIMESTAMP_FILE=/etc/faketimerc \
		$container_id python3 create_slurm_jobs.py &>> $outlog &
	
	i=$((i+1))
	#time=$(date "+%Y-%m-%d %T"); echo "@$time x100" > faketimerc
	#sleep 20
	#kecho "Time to liven things up"
	#docker container cp faketimerc ${container_id}:/etc/faketimerc
done
