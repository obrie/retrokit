from __future__ import annotations

from romkit.models.machine import Machine
from romkit.processing.rule import Rule, RuleTransform
from romkit.util.dict_utils import slice_only

import logging
from collections import defaultdict
from enum import Enum
from functools import partial
from typing import List

class SortOrder(Enum):
    ASCENDING = 'ascending'
    DESCENDING = 'descending'


# Represents a sortable collection of machines
class SortableSet:
    # A set of keys that have been reserved for special use in configuring
    # a sortable set.
    RESERVED_KEYS = {'group_by', 'order'}

    def __init__(self,
        # The list of properties to group by
        group_by: List[str] = [],
    ) -> None:
        self.group_by = group_by

        # Tracks machines associated with a specific group name
        self.groups = defaultdict(list)

        # Tracks overridden groups
        self.overrides = defaultdict(list)

        # Sorting rules to follow
        self.rules = []
        self.sort_keys = {}

    # Builds a SortableSet from the given json data
    @classmethod
    def from_json(cls, json: dict, attributes: List[BaseAttribute], **kwargs) -> SortableSet:
        sortable_set = cls(**slice_only(json, {'group_by'}), **kwargs)

        rules = {key: json[key] for key in json if key not in cls.RESERVED_KEYS}
        enabled_rule_ids = json.pop('order', rules.keys())

        for expression, values in rules.items():
            if values is None:
                continue

            rule_id = Rule.id_for(expression)
            if rule_id not in enabled_rule_ids:
                continue

            # Handle value-based sorting rather than index-based
            if isinstance(values, str):
                sort_order = SortOrder(values)
                values = []
            else:
                sort_order = None

            # Add the rule
            rule = Rule.parse(expression, values, attributes)
            if rule.enabled:
                sortable_set.add_rule(rule, sort_order)

        # Sort rules according to the order provided
        sortable_set.rules.sort(key=lambda rule: enabled_rule_ids.index(rule.id))

        return sortable_set

    # Adds a new sorting rule
    def add_rule(self, new_rule: Rule, sort_order: Optional[SortOrder] = None) -> None:
        if new_rule in self.rules:
            existing_rule = next(rule for rule in self.rules if rule == new_rule)
            existing_rule.merge(new_rule)
        else:
            self.rules.append(new_rule)

            # Determine how we're going to sort values with this rule
            if sort_order:
                sort_key = self._coalesce_machine_value_fn(new_rule)
                if sort_order == SortOrder.DESCENDING:
                    new_rule.invert = True
            elif new_rule.transform == RuleTransform.MATCH_COUNT:
                sort_key = new_rule.count_matches
            else:
                sort_key = new_rule.first_match_index

            self.sort_keys[new_rule] = sort_key

    # Clears the current list of groups being tracked
    def clear(self) -> None:
        self.groups.clear()
        self.overrides.clear()

    # Associates the machine with the given group name
    def add(self, machine: Machine) -> None:
        self.groups[machine.group_name].append(machine)

    # Ignores all prioritization rules and prioritizes a machine within the
    # given group
    def override(self, machine: Machine) -> None:
        self.add(machine)
        self.overrides[machine.group_name].append(machine)

    # Returns the list of all machines
    def all(self) -> List[Machine]:
        return [machine for machines in self.groups.values() for machine in machines]

    # Finalizes the prioritized set of machiens by performing any additional
    # post-processing, such as restricting the list of machines to prevent
    # multiple with the same title
    def prioritize(self) -> List[Machine]:
        if 'group' in self.group_by:
            machines = []
            groups = self.groups.copy()

            # Add overrides, ignoring anything else that was in the same
            # override group
            for group_name, override_machines in self.overrides.items():
                machines.extend(override_machines)
                del groups[group_name]

            # Add remaining prioritized groups
            machines.extend(self._prioritize_groups(groups))
        else:
            machines = self.all()

        for property_name in self.group_by:
            if property_name != 'group':
                machines = self._prioritize_by_property(machines, property_name)

        return machines

    # Reduce a list of machines further by only allowing a single machine/playlist
    # with a certain property value
    def _prioritize_by_property(self, machines: List[Machine], property_name: str) -> List[Machine]:
        groups_by_value = defaultdict(list)
        for machine in machines:
            value = Machine.normalize(getattr(machine, property_name))
            groups_by_value[value].append(machine)

        return self._prioritize_groups(groups_by_value)

    # Generates a list of prioritized machines for the given machine groupings.
    # 
    # If the highest prioritized machine is not part of a playlist, then only a
    # single machine from the group will be selected.
    # 
    # If the highest prioritized machine *is* part of a playlist, then only those
    # machines from the playlist will be selected.  Additionally, only a single
    # machine per disc will be selected for that playlist.
    def _prioritize_groups(self, groups: dict, process_playlists: bool = True) -> List[Machine]:
        machines = []

        # Sort and add machines
        for group in groups.values():
            # Short-circuit if we're working with a group of 1 (no need to sort)
            if len(group) == 1:
                machines.extend(group)
                continue

            group = self._sort(group)
            top_machine = group[0]

            if process_playlists and top_machine.has_playlist:
                groups_by_disc_title = defaultdict(list)

                # Filter for machines with the same playlist name
                for machine in group:
                    if machine.has_playlist and machine.playlist_name == top_machine.playlist_name:
                        groups_by_disc_title[machine.disc_title].append(machine)
                    else:
                        logging.debug(f'[{machine.name}] Skip (PriorityFilter)')

                # Add only a single machine for each disc within the playlist
                machines.extend(self._prioritize_groups(groups_by_disc_title, False))
            else:
                # Add just the top machine
                machines.append(top_machine)
                for machine in group[1:]:
                    logging.debug(f'[{machine.name}] Skip (PriorityFilter)')

        return machines

    # Sorts the list of machines based on the sorting rules in the order they
    # were defined
    def _sort(self, machines: List[Machine]) -> List[Machine]:
        for rule in reversed(self.rules):
            machines.sort(key=self.sort_keys[rule], reverse=rule.invert)

        return machines

    # Generates a function that coalesces machine values for the given rule to avoid
    # sorting issues when we have both null and non-null values.
    def _coalesce_machine_value_fn(self, rule: Rule) -> Callable:
        if rule.attribute.data_type == str:
            # Empty strings are the closest we can get to interpreting None
            default_value = ''
        elif rule.attribute.data_type == bool:
            # We can't guarantee None values to be sorted last with booleans,
            # but we can make it at least close to last
            default_value = not(rule.invert)
        elif rule.attribute.data_type == int or rule.attribute.data_type == float:
            # None should always be sorted last -- so we use infinite to represent that
            if rule.invert:
                default_value = float('-inf')
            else:
                default_value = float('inf')
        else:
            # Anything else should break so that we can properly handle it
            default_value = None

        return partial(self._coalesce_machine_value, rule, default_value)

    # Coaleces the resulting value from the sort key for the rule
    def _coalesce_machine_value(self, rule: Rule, default_value: Any, machine: Machine) -> Callable:
        value = rule.raw_machine_value(machine)
        if value is None:
            value = default_value

        return value
