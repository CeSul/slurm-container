#!/bin/bash

# Define the file path
CONFIG_FILE="/opt/slurm-22.05.2/etc/slurm.conf"

# Backup the original file before making any changes
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# Add 'AuthType=auth/none' above 'ClusterName=cluster'
sed -i '/ClusterName=cluster/i AuthType=auth/none' "$CONFIG_FILE"

# Find 'TaskPlugin=task/affinity' and replace it with 'TaskPlugin=task/none'
sed -i 's/TaskPlugin=task\/affinity/TaskPlugin=task\/none/' "$CONFIG_FILE"

# Confirm changes
echo "Changes made successfully. Backup of original file saved as slurm.conf.bak."

sh restart_slurmd.sh
