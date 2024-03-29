import pytest

import os
import shutil
from pathlib import Path

from foamlib import AsyncFoamCase

@pytest.fixture
async def flange(tmp_path):
    case = AsyncFoamCase(Path(os.environ["FOAM_TUTORIALS"]) / "basic" / "laplacianFoam" / "flange")
    return await case.clone(tmp_path / case.name)

@pytest.mark.asyncio_cooperative
async def test_serial(flange):
    await flange.run(parallel=False)

@pytest.mark.asyncio_cooperative
async def test_parallel(flange):
    await flange.run(parallel=True)
    await flange.run(["reconstructPar"])

@pytest.mark.asyncio_cooperative
async def test_parallel_manual(flange):
    shutil.copytree(flange.path / "0.orig", flange.path / "0")
    await flange.run(["ansysToFoam", Path(os.environ["FOAM_TUTORIALS"]) / "resources" / "geometry" / "flange.ans", "-scale", "0.001"])
    await flange.run(script=False, parallel=True)
    await flange.run(["reconstructPar"])

@pytest.mark.asyncio_cooperative
async def test_parallel_manual_shell(flange):
    await flange.run("cp -r 0.orig 0")
    await flange.run("ansysToFoam \"$FOAM_TUTORIALS/resources/geometry/flange.ans\" -scale 0.001")
    await flange.run("decomposePar")
    await flange.run(flange.application, parallel=True)
    await flange.run("reconstructPar")
