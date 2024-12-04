import pandas as pd
import time
import os

# Read the file into a DataFrame
df = pd.read_csv('slurm_anon_epyc64_10days', sep='|')

# Convert necessary columns to datetime with error handling
df['Submit'] = pd.to_datetime(df['Submit'], errors='coerce')
df['Start'] = pd.to_datetime(df['Start'], errors='coerce')
df['End'] = pd.to_datetime(df['End'], errors='coerce')

# Calculate additional columns
df['Duration'] = (df['End'] - df['Start']).dt.total_seconds()
df['RequestedWalltime'] = df['TimelimitRaw'] * 60

# Get the reference time (first submit time)
reference_time = df['Submit'].iloc[0]

# Initialize the TimeDiff column
df['TimeDiff'] = 0.0

# Calculate time difference for each row
for i in range(len(df)):
    if i == 0:
        # First row: Time difference from the reference time
        df.loc[i, 'TimeDiff'] = (df['Submit'].iloc[i] - reference_time).total_seconds()
    else:
        # For all other rows: Time difference from the previous row's Submit time
        df.loc[i, 'TimeDiff'] = (df['Submit'].iloc[i] - df['Submit'].iloc[i-1]).total_seconds()

# Template for the SLURM job script
job_template = """#!/bin/bash
#SBATCH --time={walltime}
#SBATCH -N {nodes}
#SBATCH -n {cpus}
#SBATCH --account={account}

# Path to the log file where job information will be saved
LOG_FILE="./log/slurm_job_$SLURM_JOB_ID.log"

export PATH=/opt/slurm-22.05.2/bin:$PATH

# Simulate the actual workload (your job's commands)
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

# Iterate over each row in the DataFrame
for index, row in df.iterrows():
    user_id = row['User']
    account_id = row['Account']
    walltime = time.strftime('%H:%M:%S', time.gmtime(row['RequestedWalltime']))
    nodes = row['ReqNodes']
    cpus = row['ReqCPUS']
    duration = row['Duration']
    time_diff = row['TimeDiff']

    # Generate the job script content
    job_script_content = job_template.format(
        walltime=walltime,
        nodes=nodes,
        cpus=cpus,
        account=account_id,
        duration=duration
    )

    # Write the job script to a file
    job_script_filename = f"job_script_{index}.sh"
    with open(job_script_filename, 'w') as job_script_file:
        job_script_file.write(job_script_content)

    # Wait for the specified time difference
    print(f"waiting for {time_diff} seconds before submitting the next job")
    time.sleep(time_diff)

    # Submit the job using sbatch
    os.system(f"sudo -u {user_id} /opt/slurm-22.05.2/bin/sbatch {job_script_filename}")
