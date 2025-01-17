#!/bin/bash

# installation script for triqs3 stable branch with clang OpenMPI toolchain with new spack modules

# load modules
MODULES="modules/2.0-20220630 gcc/11 flexiblas openmpi cmake gmp fftw nfft hdf5/mpi boost/libcpp-1.78.0 python/3.10 python-mpi/3.10 intel-oneapi-mkl llvm/13"
module purge
module load ${MODULES}

export CC=clang
export CXX=clang++
export CFLAGS="-march=broadwell"
export CXXFLAGS="-stdlib=libc++ -Wno-register -march=broadwell"
export FC=gfortran

export BLA_VENDOR=FlexiBLAS

# set up flexiblas:
export MKL_INTERFACE_LAYER=GNU,LP64
export MKL_THREADING_LAYER=SEQUENTIAL
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=12
NCORES=12

BUILDINFO=3_unst_nix2_llvm
BUILDDIR=/tmp/triqs${BUILDINFO}_build
INSTALLDIR=$(pwd)/installation
MODULEDIR=$(git rev-parse --show-toplevel)/modules
mkdir -p $BUILDDIR
mkdir -p $INSTALLDIR/lib/python3.10/site-packages

export ITENSOR_ROOT=${INSTALLDIR}
export TRIQS_ROOT=${INSTALLDIR}
export PATH=${INSTALLDIR}/bin:$PATH
export CPLUS_INCLUDE_PATH=${INSTALLDIR}/include:$CPLUS_INCLUDE_PATH
export LIBRARY_PATH=${INSTALLDIR}/lib:$LIBRARY_PATH
export LD_LIBRARY_PATH=${INSTALLDIR}/lib:$LD_LIBRARY_PATH
export PYTHONPATH=${INSTALLDIR}/lib/python3.10/site-packages:$PYTHONPATH
export CMAKE_PREFIX_PATH=${INSTALLDIR}/lib/cmake/triqs:$CMAKE_PREFIX_PATH
export CMAKE_PREFIX_PATH=${INSTALLDIR}/lib/cmake/cpp2py:$CMAKE_PREFIX_PATH

log=build_$(date +%Y%m%d%H%M).log
testlog="$(pwd)/${log/.log/_test.log}"
(
    cd ${BUILDDIR}

    module list

    # install triqs
    cd ${BUILDDIR}
    git clone -b unstable --depth 1 https://github.com/TRIQS/triqs triqs.src
    # fetch latest changes
    cd triqs.src && git pull && cd ..
    mkdir -p triqs.build && cd triqs.build

    cmake ../triqs.src -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -DBuild_Deps=Always
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    #################

    cd ${BUILDDIR}
    # install cthyb
    git clone -b unstable --depth 1 https://github.com/TRIQS/cthyb cthyb.src
    # fetch latest changes
    cd cthyb.src && git pull && cd ..
    mkdir -p cthyb.build && cd cthyb.build

    cmake ../cthyb.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    #################

    cd ${BUILDDIR}
    # install ctint
    git clone -b unstable --depth 1 git@github.com:TRIQS/ctint.git ctint.src
    # fetch latest changes
    cd ctint.src && git pull && cd ..
    mkdir -p ctint.build && cd ctint.build

    cmake ../ctint.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install

    ##################

    cd ${BUILDDIR}
    # install ctseg
    git clone -b unstable --depth 1 git@github.com:TRIQS/ctseg.git ctseg.src
    # fetch latest changes
    cd ctseg.src && git pull && cd ..
    mkdir -p ctseg.build && cd ctseg.build

    cmake ../ctseg.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install

    #################
    cd ${BUILDDIR}
    # install dfttools
    git clone -b unstable --depth 1 https://github.com/TRIQS/dft_tools.git dft_tools.src
    # fetch latest changes
    cd dft_tools.src && git pull && cd ..
    mkdir -p dft_tools.build && cd dft_tools.build

    cmake ../dft_tools.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    ################

    cd ${BUILDDIR}
    # install maxent
    git clone -b unstable --depth 1 https://github.com/TRIQS/maxent.git maxent.src
    # fetch latest changes
    cd maxent.src && git pull && cd ..
    mkdir -p maxent.build && cd maxent.build

    cmake ../maxent.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    ################

    cd ${BUILDDIR}
    # install TPRF
    git clone -b unstable --depth 1 https://github.com/TRIQS/tprf.git tprf.src
    # fetch latest changes
    cd tprf.src && git pull && cd ..
    mkdir -p tprf.build && cd tprf.build

    cmake ../tprf.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    ################

    cd ${BUILDDIR}
    # install hubbardI
    git clone -b unstable --depth 1 https://github.com/TRIQS/hubbardI.git hubbardI.src
    # fetch latest changes
    cd hubbardI.src && git pull && cd ..
    mkdir -p hubbardI.build && cd hubbardI.build

    cmake ../hubbardI.src
    # make / test / install
    make -j$NCORES
    ctest -j$NCORES &>> ${testlog}
    make install
    ################

    cd ${BUILDDIR}
    # install solid_dmft
    git clone -b unstable --depth 1 https://github.com/flatironinstitute/solid_dmft.git solid_dmft.src
    # fetch latest changes
    cd solid_dmft.src && git pull && cd ..
    mkdir -p solid_dmft.build && cd solid_dmft.build

    cmake ../solid_dmft.src
    # make / test / install
    make -j$NCORES
    # tests leverage MPI:
    make test &>> ${testlog}
    make install
    ################
    
    cd ${BUILDDIR}
    # install Hartree Fock
    git clone -b unstable --depth 1 https://github.com/triqs/hartree_fock.git hartree_fock.src
    # fetch latest changes
    cd hartree_fock.src && git pull && cd ..
    mkdir -p hartree_fock.build && cd hartree_fock.build

    cmake ../hartree_fock.src
    # make / test / install
    make
    make test &>> ${testlog}
    make install
    ################

    # install itensor
    git clone -b v3 --depth 1 https://github.com/ITensor/ITensor.git itensor
    # fetch latest changes
    cd itensor && git pull && make clean
    cp ${INSTALLDIR}/../options.mk.itensor ./options.mk
    make -j$NCORES
    # copying Itensor libs to triqs lib dir
    cp -r lib itensor ${TRIQS_ROOT}/
    ################

    # install ForkTPS
    cd ${BUILDDIR}
    git clone -b unstable --depth 1 git@github.com:TRIQS/forktps.git forktps.src
    # fetch latest changes
    cd forktps.src && git pull && cd ..
    mkdir -p forktps.build && cd forktps.build

    cmake ../forktps.src -DBUILD_SHARED_LIBS=ON
    # make / test / install
    make -j$NCORES
    # tests leverage MPI / OpenMP
    make test &>> ${testlog}
    make install
    ################
) &> ${log}

mkdir -p $MODULEDIR/triqs
# make the template a proper module
echo '#%Module' > $MODULEDIR/triqs/$BUILDINFO
# update module template
sed "s|REPLACEDIR|${INSTALLDIR}|g;s|MODULES|${MODULES}|g" < src.module >> $MODULEDIR/triqs/$BUILDINFO

