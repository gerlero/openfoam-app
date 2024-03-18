import pytest

import os
from pathlib import Path

from foamlib import AsyncFoamCase

@pytest.fixture
async def blob(tmp_path):
    case = AsyncFoamCase(Path(os.environ["FOAM_TUTORIALS"]) / "mesh" / "foamyHexMesh" / "blob")
    return await case.clone(tmp_path / case.name)

@pytest.mark.parametrize("parallel", [False, True])
@pytest.mark.asyncio_cooperative
async def test_blob(blob, parallel):
    await blob.run(parallel=parallel)
