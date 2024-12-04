#!/bin/bash
#SBATCH -J ExampleJob
##SBATCH -o mpi_example_%j.out
#SBATCH --time=00:05:00
#SBATCH -N 2
#SBATCH -n 8

sleep 10
