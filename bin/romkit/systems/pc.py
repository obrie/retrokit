from __future__ import annotations

from romkit.systems import BaseSystem

class PCSystem(BaseSystem):
    name = 'pc'

    def enable(self, machine: Machine, system_dir: SystemDir) -> None:
        # TODO: Create configuration file
        pass
