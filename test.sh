#!/bin/bash -e

rm -rf pitzDaily
cp -r "$FOAM_TUTORIALS/incompressible/simpleFoam/pitzDaily" pitzDaily
cd pitzDaily
blockMesh
simpleFoam
cd ..

rm -rf flange
cp -r "$FOAM_TUTORIALS/basic/laplacianFoam/flange" flange
cd flange
OMPI_MCA_rmaps_base_oversubscribe=1 ./Allrun-parallel
reconstructPar
cd ..

rm -rf flange_manual
cp -r "$FOAM_TUTORIALS/basic/laplacianFoam/flange" flange_manual
cd flange_manual
cp -r 0.orig 0
ansysToFoam "$FOAM_TUTORIALS/resources/geometry/flange.ans" -scale 0.001
decomposePar
mpirun -np 4 --oversubscribe laplacianFoam -parallel < /dev/null
reconstructPar
cd ..

rm -rf backwardFacingStep2D
cp -r "$FOAM_TUTORIALS/incompressible/simpleFoam/backwardFacingStep2D" backwardFacingStep2D
cd backwardFacingStep2D
./Allrun
! grep 'FOAM Warning' log.simpleFoam
cd ..

rm -rf blob
cp -r "$FOAM_TUTORIALS/mesh/foamyHexMesh/blob" blob
cd blob
./Allrun
cd ..

# https://github.com/gerlero/openfoam-app/issues/88
cartesianMesh -help
