import pandas as pd

# Read the slurm file
df = pd.read_csv('slurm_anon_epyc64_10days', sep='|')

# Get unique account-user pairs
account_users = df[['Account', 'User']].drop_duplicates()

# Create bash script content
bash_script = "#!/bin/bash\n\n"

# Add commands for each unique account and its users
for account in account_users['Account'].unique():
    bash_script += f"sudo groupadd {account}\n"
    users = account_users[account_users['Account'] == account]['User']
    for user in users:
        bash_script += f"sudo useradd -m -g {account} {user}\n"

# Write to bash script file
with open('create_users_and_groups.sh', 'w') as f:
    f.write(bash_script)
