from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on the input controls
class ControlFilter(BaseFilter):
    name = 'controls'

    def values(self, machine: Machine) -> Set[str]:
        return machine.controls

class PlayerFilter(BaseFilter):
    name = 'players'
    normalize_values = False

    def values(self, machine: Machine) -> Set[int]:
        if machine.players is not None:
          return {machine.players}
        else:
          return self.empty
