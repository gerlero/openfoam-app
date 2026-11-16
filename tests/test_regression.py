import pytest

import os
from pathlib import Path

from foamlib import AsyncFoamCase

@pytest.fixture
async def step():
    case = AsyncFoamCase(Path(os.environ["FOAM_TUTORIALS"]) / "incompressible" / "simpleFoam" / "backwardFacingStep2D")
    async with case.clone() as clone:
        yield clone

@pytest.mark.asyncio_cooperative
async def test_step(step): # https://github.com/gerlero/openfoam-app/issues/5
    await step.run()
    log = (step.path / "log.simpleFoam").read_text()
    assert "Could not load" not in log
    assert "Unknown function type" not in log
