from __future__ import annotations

# Represents a collection of machines based on a set of rules
class Collection:
    def __init__(self, name: str, rules: Ruleset) -> None:
        self.name = name
        self.rules = rules

    # Determines whether the given machine is a part of this collection
    def match(self, machine: Machine) -> bool:
        return self.rules.match(machine) is not None
