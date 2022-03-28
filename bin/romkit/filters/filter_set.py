from __future__ import annotations

from enum import Enum
from typing import Optional

class FilterReason(Enum):
    ALLOW = 1
    OVERRIDE = 2

# Represents a collection of machine filters
class FilterSet:
    def __init__(self) -> None:
        self.filters = []
        self.overrides = []

    # Builds a FilterSet from the given json data
    @classmethod
    def from_json(cls, json: dict, config: dict, supported_filters: list, log: bool = True) -> FilterSet:
        filter_set = cls()

        enabled_filters = json.get('enabled', supported_filters)

        for filter_cls in enabled_filters:
            allowlist = json.get(filter_cls.name)
            if allowlist is not None:
                filter_set.append(filter_cls(set(allowlist), config=config, log=log))

            blocklist = json.get(f'!{filter_cls.name}')
            if blocklist is not None:
                filter_set.append(filter_cls(set(blocklist), invert=True, config=config, log=log))

            overridelist = json.get(f'+{filter_cls.name}')
            if overridelist is not None:
                filter_set.append(filter_cls(set(overridelist), override=True, config=config, log=log))

        return filter_set

    # Adds a new filter
    def append(self, filter):
        if filter.override:
            self.overrides.append(filter)
        else:
            self.filters.append(filter)

    # Whether the given machine is allowed by the filter set
    def allow(self, machine: Machine) -> Optional[FilterReason]:
        allowed_by_override = False
        for filter in self.overrides:
            if filter.allow(machine):
                allowed_by_override = True
                allowed_by_override_filter = filter.name
                break
        
        allowed = all((allowed_by_override and not filter.apply_to_overrides) or filter.allow(machine) for filter in self.filters)

        if allowed:
            if allowed_by_override and allowed_by_override_filter == 'name':
                # Only explicit names will override everything else, including 1G1R
                return FilterReason.OVERRIDE
            else:
                # Either this was an override filter that ignored other filters or
                # all filters agreed that this machine is allowed
                return FilterReason.ALLOW
