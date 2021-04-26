from __future__ import annotations

# Represents a collection of machine filters
class FilterSet:
    def __init__(self) -> None:
        self.filters = []
        self.overrides = []

    # Builds a FilterSet from the given json data
    @classmethod
    def from_json(cls, json: dict, config: dict, supported_filters: list) -> FilterSet:
        filter_set = cls()

        for filter_cls in supported_filters:
            allowlist = json.get(filter_cls.name)
            if allowlist:
                filter_set.append(filter_cls(set(allowlist), config=config))

            blocklist = json.get(f'!{filter_cls.name}')
            if blocklist:
                filter_set.append(filter_cls(set(blocklist), invert=True, config=config))

            overridelist = json.get(f'+{filter_cls.name}')
            if overridelist:
                filter_set.append(filter_cls(set(overridelist), override=True, config=config))

        return filter_set

    # Adds a new filter
    def append(self, filter):
        if filter.override:
            self.overrides.append(filter)
        else:
            self.filters.append(filter)

    # Whether the given machine is allowed by the filter set
    def allow(self, machine: Machine) -> bool:
        allowed_by_override = any(filter.override and filter.allow(machine) for filter in self.overrides)
        return all((allowed_by_override and not filter.apply_to_overrides) or filter.allow(machine) for filter in self.filters)
