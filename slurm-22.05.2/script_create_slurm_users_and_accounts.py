import pandas as pd

# Read the slurm file
df = pd.read_csv('slurm_anon_epyc64_10days', sep='|')

# Get unique account-user pairs
account_users = df[['Account', 'User']].drop_duplicates()

# startup script
slurm_script = """#!/bin/bash
export PATH=/opt/slurm-22.05.2/bin:/opt/slurm-22.05.2/sbin:${PATH}
# Add/modify QOS
sacctmgr -i modify QOS set normal Priority=0
sacctmgr -i add QOS Name=supporters Priority=100

# Add cluster
sacctmgr -i add cluster Name=cluster Fairshare=1 QOS=normal,supporters

# Add user
sacctmgr -i add user name=admin DefaultAccount=account0 MaxSubmitJobs=1000 AdminLevel=Administrator

"""

# Add commands for each unique account and its users
for account in account_users['Account'].unique():
    slurm_script += f"sacctmgr -i add account name={account} Fairshare=100\n"
    users = account_users[account_users['Account'] == account]['User']
    for user in users:
        slurm_script += f"sacctmgr -i add user name={user} DefaultAccount={account} MaxSubmitJobs=1000\n"

# Write to bash script file
with open('create_slurm_users_and_accounts.sh', 'w') as f:
    f.write(slurm_script)
