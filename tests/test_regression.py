import pytest

import os
import subprocess
from pathlib import Path

from foamlib import AsyncFoamCase

@pytest.fixture
async def step(tmp_path):
    case = AsyncFoamCase(Path(os.environ["FOAM_TUTORIALS"]) / "incompressible" / "simpleFoam" / "backwardFacingStep2D")
    return await case.clone(tmp_path / case.name)

@pytest.mark.asyncio_cooperative
async def test_step(step):
    await step.run()
    assert "FOAM Warning" not in (step.path / "log.simpleFoam").read_text()

def test_cartesian(): # https://github.com/gerlero/openfoam-app/issues/88
    subprocess.run(["cartesianMesh", "-help"], check=True)
