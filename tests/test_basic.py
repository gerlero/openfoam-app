import pytest

import os
from pathlib import Path

from aiofoam import Case

@pytest.fixture
async def pitz_case(tmp_path):
    case = Case(Path(os.environ["FOAM_TUTORIALS"]) / "incompressible" / "simpleFoam" / "pitzDaily")
    return await case.clone(tmp_path / case.name)

@pytest.mark.asyncio_cooperative
async def test_pitz(pitz_case):
    await pitz_case.run()
