#!/bin/bash

dbus-launch
sudo -u munge munged

. /usr/lib64/mpi/gcc/mpich/bin/mpivars.sh

: "${SLURM_CONF_IN=$SLURM_CONFDIR/slurm.conf.in}"
: "${SLURM_CONF=$SLURM_CONFDIR/slurm.conf}"
: "${SLURMDBD_CONF_IN=$SLURM_CONFDIR/slurmdbd.conf.in}"
: "${SLURMDBD_CONF=$SLURM_CONFDIR/slurmdbd.conf}"


# Default number of slurm nodes
: "${SLURM_NUMNODES=3}"

# Default slurm controller
: "${SLURMCTLD_HOST=$HOSTNAME}"
: "${SLURMCTLD_ADDR=127.0.0.1}"

# Default node info
: "${NODE_HOST=$HOSTNAME}"
: "${NODE_ADDR=127.0.0.1}"
: "${NODE_BASEPORT=6001}"

# Default hardware profile
: "${NODE_HW=CPUs=64 RealMemory=256000}"

# Generate node names and associated ports
NODE_NAMES=$(printf "nd[%05i-%05i]" 1 $SLURM_NUMNODES)
NODE_PORTS=$(printf "%i-%i" $NODE_BASEPORT $(($NODE_BASEPORT+$SLURM_NUMNODES-1)))


echo "INFO:"
echo "INFO: Creating $SLURM_CONF with"
echo "INFO: "
column -t <<-EOF
      INFO: SLURMCTLD_HOST=$SLURMCTLD_HOST SLURMCTLD_ADDR=$SLURMCTLD_ADDR
      INFO: NODE_HOST=$NODE_HOST NODE_ADDR=$NODE_ADDR NODE_BASEPORT=$NODE_BASEPORT
      INFO: NODE_HW=$NODE_HW
      INFO: SLURM_NUMNODES=$SLURM_NUMNODES
EOF
echo "INFO: "
echo "INFO: Derived values:"
echo "INFO:"
column -t <<-EOF
      INFO: NODE_NAMES=$NODE_NAMES
      INFO: NODE_PORTS=$NODE_PORTS
EOF
echo "INFO:"
echo "INFO: Override any of the non-derived values by setting the respective environment variable"
echo "INFO: when starting Docker."
echo "INFO:"

export PATH=$SLURM_ROOT/bin:$PATH
export LD_LIBRARY_PATH=$SLURM_ROOT/lib:$LD_LIBRARY_PATH
export MANPATH=$SLURM_ROOT/man:$MANPATH

(
    echo "NodeName=${NODE_NAMES} NodeHostname=${NODE_HOST} NodeAddr=${NODE_ADDR} Port=${NODE_PORTS} State=UNKNOWN ${NODE_HW}"
    #echo "NodeName=${NODE_NAMES} NodeHostname=${NODE_HOST} NodeAddr=${NODE_ADDR} Port=${NODE_PORTS} State=UNKNOWN"
    echo "PartitionName=dkr Nodes=ALL Default=YES MaxTime=INFINITE State=UP"
) \
| sed -e "s/SLURMCTLDHOST/${SLURMCTLD_HOST}/" \
      -e "s/SLURMCTLDADDR/${SLURMCTLD_ADDR}/" \
    $SLURM_CONF_IN - \
> $SLURM_CONF

sed -e "s/SLURMCTLDHOST/${SLURMCTLD_HOST}/" \
    -e "s/SLURMCTLDADDR/${SLURMCTLD_ADDR}/" \
    $SLURMDBD_CONF_IN  > $SLURMDBD_CONF
	
chmod 600 $SLURMDBD_CONF
chown slurm $SLURMDBD_CONF

#ls -l $SLURMDBD_CONF_IN

NODE_NAME_LIST=$(scontrol show hostnames $NODE_NAMES)

for n in $NODE_NAME_LIST
do
    echo "$NODE_ADDR       $n" 
    echo "$NODE_ADDR       $n" >> /etc/hosts
done

echo
echo "Starting Slurm services..."

echo "Launching mysqld"

mysqld_safe &
mysqladmin --silent --wait=30 ping

# libfaketime settings
PRELOAD_LIB=/usr/lib64/libfaketime/libfaketime.so.1
CACHE_DURATION=10


echo "Starting slurmdbd ..."
LD_PRELOAD=$PRELOAD_LIB \
FAKETIME_CACHE_DURATION=$CACHE_DURATION \
$SLURM_ROOT/sbin/slurmdbd

sleep 3
echo "Starting slurmctld ..."
LD_PRELOAD=$PRELOAD_LIB \
FAKETIME_CACHE_DURATION=$CACHE_DURATION \
$SLURM_ROOT/sbin/slurmctld
source /home/spack/create_slurm_users_and_accounts.sh

for n in $NODE_NAME_LIST
do
	echo "Starting slurmd on $n..."
	LD_PRELOAD=$PRELOAD_LIB \
	FAKETIME_CACHE_DURATION=$CACHE_DURATION \
	$SLURM_ROOT/sbin/slurmd -N $n
done

echo
sinfo
echo
echo

exec "$@"
