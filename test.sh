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
cp -r 0.orig 0
ansysToFoam "$FOAM_TUTORIALS/resources/geometry/flange.ans" -scale 0.001
decomposePar
mpirun -np 4 --oversubscribe laplacianFoam -parallel < /dev/null
reconstructPar
cd ..

rm -rf flange2
cp -r "$FOAM_TUTORIALS/basic/laplacianFoam/flange" flange2
cd flange2
foamDictionary -entry numberOfSubdomains -set 2 system/decomposeParDict
$BASH -e ./Allrun-parallel
reconstructPar
cd ..

rm -rf backwardFacingStep2D
cp -r "$FOAM_TUTORIALS/incompressible/simpleFoam/backwardFacingStep2D" backwardFacingStep2D
cd backwardFacingStep2D
$BASH -e ./Allrun
! grep 'FOAM Warning' log.simpleFoam
cd ..

rm -rf blob
cp -r "$FOAM_TUTORIALS/mesh/foamyHexMesh/blob" blob
cd blob
$BASH -e ./Allrun
cd ..
