import pytest

import os
from pathlib import Path

from foamlib import AsyncFoamCase

@pytest.fixture
async def pitz():
    case = AsyncFoamCase(Path(os.environ["FOAM_TUTORIALS"]) / "incompressible" / "simpleFoam" / "pitzDaily")
    async with case.clone() as clone:
        yield clone

@pytest.mark.asyncio_cooperative
async def test_pitz(pitz):
    await pitz.run()
