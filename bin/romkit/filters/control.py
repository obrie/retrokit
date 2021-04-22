from __future__ import annotations

from romkit.filters.base import ExactFilter

# Filter on the input controls
class ControlFilter(ExactFilter):
    name = 'controls'

    def values(self, machine: Machine) -> set:
        return machine.controls
