#!/bin/bash
#SBATCH --job-name="SVO-QE-cRPA"
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --ntasks-per-core=1
#SBATCH --partition=ccq
#SBATCH --constraint=rome
#SBATCH --output=out.%j
#SBATCH --error=err.%j

#======START=====

module purge
module load slurm
module load quantum_espresso/7.1_nix2_ompi_respack

export OMP_NUM_THREADS=16
export OMP_STACKSIZE=512
ulimit -s unlimited

echo "QE scf step"
mpirun --map-by socket:pe=$OMP_NUM_THREADS pw.x -pd .true. < SrVO3.scf.in > SrVO3.scf.out

echo "QE nscf step"
mpirun --map-by socket:pe=$OMP_NUM_THREADS pw.x -pd .true. < SrVO3.nscf.in > SrVO3.nscf.out

echo "pre-process"
wan2respack.py -pp conf.toml

echo "wannier90 run"
mpirun --map-by socket:pe=$OMP_NUM_THREADS pw.x -pd .true. < SrVO3.nscf_wannier.in > SrVO3.nscf_wannier.out

mpirun wannier90.x -pp SrVO3

mpirun --map-by socket:pe=$OMP_NUM_THREADS pw2wannier90.x < SrVO3.pw2wan.in > SrVO3.pw2wan.out
$WAN90_DIR/wannier90.x SrVO3

mpirun wannier90.x -pp SrVO3

echo "wannier90 results to RESPACK inputs"
wan2respack.py conf.toml

echo "run respack"
mpirun --map-by socket:pe=$OMP_NUM_THREADS calc_chiqw < SrVO3.crpa.in > SrVO3.crpa.out

echo "calc screened U / J in Wannier basis"
mpirun -n 1 calc_w3d < SrVO3.crpa.in > SrVO3.w3d.out
mpirun -n 1 calc_j3d < SrVO3.crpa.in > SrVO3.j3d.out

#=====END====