import pytest

import os
from pathlib import Path

from foamlib import AsyncFoamCase

@pytest.fixture
async def blob():
    case = AsyncFoamCase(Path(os.environ["FOAM_TUTORIALS"]) / "mesh" / "foamyHexMesh" / "blob")
    async with case.clone() as clone:
        yield clone

@pytest.mark.parametrize("parallel", [False, True])
@pytest.mark.asyncio_cooperative
async def test_blob(blob, parallel):
    await blob.run(parallel=parallel)
