import pandas as pd
import time
import os

def minutes_to_hh_mm_ss(minutes):
    hours = minutes // 60
    remaining_minutes = minutes % 60
    return f"{hours:02d}:{remaining_minutes:02d}:00"

# Read the file into a DataFrame
df = pd.read_csv('slurm_anon_epyc64_10days', sep='|')

# Convert necessary columns to datetime with error handling
df['Submit'] = pd.to_datetime(df['Submit'], errors='coerce')
df['Start'] = pd.to_datetime(df['Start'], errors='coerce')
df['End'] = pd.to_datetime(df['End'], errors='coerce')

# Calculate additional columns
df['Duration'] = (df['End'] - df['Start']).dt.total_seconds()

# Initialize TimeDiff column with zeros
df['TimeDiff'] = 0

# Calculate time differences between consecutive job submissions
for i in range(1, len(df)):
    # Time difference between current and previous row
    df.loc[i, 'TimeDiff'] = (df['Submit'].iloc[i] - df['Submit'].iloc[i-1]).total_seconds()


# Template for the SLURM job script
job_template = """#!/bin/bash
#SBATCH --time={walltime}
#SBATCH -N {nodes}
#SBATCH -n {cpus}
#SBATCH --mem={memory}
#SBATCH --account={account}

# Path to the log file where job information will be saved
LOG_FILE="./log/slurm_job_$SLURM_JOB_ID.log"

export PATH=/opt/slurm/bin:$PATH

# Simulate the actual workload (your job's commands)
#LD_PRELOAD=/usr/lib64/libfaketime/libfaketime.so.1 sleep {duration}
sleep {duration}

# After the job finishes, log additional job details
{{
    echo "Job ID: $SLURM_JOB_ID"
    echo "Job End Time: $(date)"
    echo "----------------------------------"
    echo "Full job details:"
    scontrol show job $SLURM_JOB_ID
    echo "----------------------------------"
}} >> $LOG_FILE
"""

# Create log directory if it doesn't exist
os.makedirs('./log', exist_ok=True)

# Iterate over each row in the DataFrame
for index, row in df.iterrows():
    user_id = row['User']
    account_id = row['Account']
    # Convert TimelimitRaw (minutes) to HH:MM:SS format
    walltime = minutes_to_hh_mm_ss(int(row['TimelimitRaw']))
    nodes = row['ReqNodes']
    cpus = row['ReqCPUS']
    # Extract memory from ReqTRES
    memory = next((param.split('=')[1] for param in row['ReqTRES'].split(',') 
                  if 'mem=' in param), '1G')  # Default to 1G if not found

    mem_in_KB = int(memory[:-1])*1000
    mem_per_node = mem_in_KB/nodes
    memory=str(int(mem_per_node))+'KB'
    duration = row['Duration']
    time_diff = row['TimeDiff']

    # Generate the job script content
    job_script_content = job_template.format(
        walltime=walltime,
        nodes=nodes,
        cpus=cpus,
        memory=memory,
        account=account_id,
        duration=duration
    )

    # Write the job script to a file
    job_script_filename = f"job_script_{index}.sh"
    with open(job_script_filename, 'w') as job_script_file:
        job_script_file.write(job_script_content)

    # Wait for the specified time difference
    #print(f"sleep for {time_diff}s")
    time.sleep(time_diff)

    # Submit the job using sbatch
    os.system(f"sudo -u {user_id} /opt/slurm/bin/sbatch {job_script_filename}")
    #print(f"sudo -u {user_id} /opt/slurm-22.05.2/bin/sbatch {job_script_filename}")
