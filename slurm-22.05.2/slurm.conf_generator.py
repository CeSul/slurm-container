import itertools
import argparse
import subprocess
pw_fairshare=[100,1000,10000]
pw_weight_age=[100,1000,10000]
pw_weight_jobsize=[100,1000,10000]
bfwindows=[2880,4320,5760]


parser = argparse.ArgumentParser()
parser.add_argument('-s', '--simulation_id', type=int)
parser.add_argument('-f', '--slurm_conf',default="slurm.conf")
args = parser.parse_args()


conf_values = itertools.product(pw_fairshare,pw_weight_age,pw_weight_jobsize,bfwindows)
[ next(conf_values) for i in range(args.simulation_id)]

fairshare,age,jobsize,bfwindow = next(conf_values)

print(fairshare,age,jobsize,bfwindow)
fs_string=f"sed -i s/PriorityWeightFairshare=4000/PriorityWeightFairshare={fairshare}/ {args.slurm_conf}"
age_string=f"sed -i s/PriorityWeightAge=7000/PriorityWeightAge={age}/ {args.slurm_conf}"
js_string=f"sed -i s/PriorityWeightJobSize=100/PriorityWeightJobSize={jobsize}/ {args.slurm_conf}"
bf_string=f"sed -i s/bf_window=2880/bf_window={bfwindow}/ {args.slurm_conf}"

subprocess.run(fs_string.split())
subprocess.run(age_string.split())
subprocess.run(js_string.split())

subprocess.run(bf_string.split())
