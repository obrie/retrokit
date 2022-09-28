from __future__ import annotations

from enum import Enum
from typing import Optional

class FilterReason(Enum):
    ALLOW = 1
    OVERRIDE = 2

class FilterModifier(Enum):
    ALLOW = ''
    BLOCK = '!'
    OVERRIDE = '+'
    UNION = '|'

# Represents a collection of machine filters
class FilterSet:
    def __init__(self) -> None:
        self.filters = []
        self.overrides = []

    # Builds a FilterSet from the given json data
    @classmethod
    def from_json(cls, json: dict, config: dict, supported_filters: list, log: bool = True) -> FilterSet:
        filter_set = cls()

        # Determine which filter configurations are actively being used
        filter_configs = {key: json[key] for key in json if key != 'enabled'}
        enabled_filter_config_names = json.get('enabled', filter_configs.keys())

        # Combine related configurations into a single filter config (in case the
        # user is unioning through configurations like "names" / "names|extra")
        combined_filter_configs = {}
        for filter_config_name in enabled_filter_config_names:
            filter_name = filter_config_name.split(FilterModifier.UNION.value)[0]
            filter_values = filter_configs[filter_config_name]

            # We only process non-null values as null is an indication that we want
            # to ignore what was there previously
            if filter_values is not None:
                # We union the values as this is effectively what the "|" modifier means
                combined_filter_configs[filter_name] = combined_filter_configs.get(filter_name, set()) | set(filter_values)

        # Add a hash lookup for each supported filter class
        supported_filter_lookup = {filter_cls.name: filter_cls for filter_cls in supported_filters}

        # Add each filter to the set
        for filter_name, filter_values in combined_filter_configs.items():
            # Determine the filter to create.  The class name will be the name
            # without modifiers. For example, the filter class name for "!names" is "names".
            filter_modifier = filter_name[0]
            filter_options = {}
            if filter_modifier == FilterModifier.BLOCK.value:
                filter_cls_name = filter_name[1:]
                filter_options['invert'] = True
            elif filter_modifier == FilterModifier.OVERRIDE.value:
                filter_cls_name = filter_name[1:]
                filter_options['override'] = True
            else:
                filter_cls_name = filter_name

            filter_cls = supported_filter_lookup[filter_cls_name]
            filter_set.append(filter_cls(set(filter_values), config=config, log=log, **filter_options))

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
