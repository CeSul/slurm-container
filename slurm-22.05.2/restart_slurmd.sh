sudo pkill slurmd
sudo pkill slurmctld
sudo /opt/slurm-22.05.2/sbin/slurmd 
sudo /opt/slurm-22.05.2/sbin/slurmctld

for i in $(seq 1 171); do
    /opt/slurm-22.05.2/sbin/slurmd -N nd$(printf "%05d" "$i")
done
