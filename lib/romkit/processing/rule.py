from __future__ import annotations

import logging
import re
from enum import Enum
from typing import Any, Pattern

class RuleLogicModifier(Enum):
    ALLOW = ''
    COMMENT = '#'
    INVERT = '!'
    OVERRIDE = '+'


class RuleGroupModifier(Enum):
    UNION = '|'
    SUBGROUP = '/'
    TRANSFORM = '.'


class RuleValueModifier(Enum):
    COMMENT = '#'
    REGEX = '/'


class RuleTransform(Enum):
    DEFAULT = '', True, lambda value: value
    LENGTH = 'length', False, lambda value: len(value) if value else 0
    MATCH_COUNT = 'match_count', True, lambda value: value

    def __new__(cls, *args, **kwds):
        obj = object.__new__(cls)
        obj._value_ = args[0]
        return obj

    def __init__(self, _: str, normalize: bool, function: Callable) -> None:
        self.normalize = normalize
        self.apply = function


# Provides a base class for reducing the set of machines to install
class Rule:
    def __init__(self,
        id: str,
        attribute: BaseAttribute,
        values: set = set(),
        enabled: bool = True,
        invert: bool = False,
        override: bool = False,
        transform: RuleTransform = RuleTransform.DEFAULT,
        log: bool = True,
    ) -> None:
        self.id = id
        self.attribute = attribute
        self.enabled = enabled
        self.invert = invert
        self.override = override
        self.transform = transform
        self.log = log

        self.values = []
        self.exact_values = set()
        self.pattern_values = set()

        # Normalize values and split based on exact/regex matches to optimize performance
        for match_value in attribute.normalize(values):
            target_values = self.exact_values

            if isinstance(match_value, str) and match_value:
                modifier = match_value[0]
                if modifier == RuleValueModifier.COMMENT.value:
                    # Skip values being used as comments
                    continue
                elif modifier == RuleValueModifier.REGEX.value:
                    # Compile to regular expression
                    target_values = self.pattern_values
                    match_value = re.compile(match_value[1:])

            self.values.append(match_value)
            target_values.add(match_value)

    # Identifies the rule id from the given expression
    @classmethod
    def id_for(self, expression: str) -> str:
        return expression.split(RuleGroupModifier.UNION.value, 1)[0]

    # Builds a new rule from the given expression / values
    @classmethod
    def parse(self, expression: str, values: List[Any], attributes: List[BaseAttribute]) -> Rule:
        attributes_lookup = {attribute.rule_name: attribute for attribute in attributes if attribute.rule_name}

        # Determine what logic we're applying to the attribute
        options = {}
        logic_modifier = expression[0]
        if logic_modifier == RuleLogicModifier.COMMENT.value:
            attribute_name = expression[1:]
            options['enabled'] = False
        elif logic_modifier == RuleLogicModifier.INVERT.value:
            attribute_name = expression[1:]
            options['invert'] = True
        elif logic_modifier == RuleLogicModifier.OVERRIDE.value:
            attribute_name = expression[1:]
            options['override'] = True
        else:
            attribute_name = expression

        # Determine what attribute we're matching with
        attribute_name, *_ = attribute_name.split(RuleGroupModifier.UNION.value, 1)
        attribute_name, *_ = attribute_name.split(RuleGroupModifier.SUBGROUP.value, 1)
        attribute_name, *transform = attribute_name.split(RuleGroupModifier.TRANSFORM.value, 1)
        attribute = attributes_lookup[attribute_name]

        if transform:
            options['transform'] = RuleTransform(transform[0])

        return Rule(self.id_for(expression), attribute, values, **options)

    # The name of the attribute for use in rules
    @property
    def attribute_name(self) -> str:
        return self.attribute.rule_name

    # Merges the given rule's settings into this one
    def merge(self, rule: Rule) -> None:
        for value in rule.values:
            if value not in self.values:
                self.values.append(value)

        self.exact_values.update(rule.exact_values)
        self.pattern_values.update(rule.pattern_values)

    # Does this match the given machine?
    def match(self, machine: Machine) -> bool:
        if self.invert:
            matched = not self.has_match(machine)
        else:
            matched = self.has_match(machine)

        if not matched and self.log:
            logging.debug(f'[{machine.name}] Skip ({self.id})')

        return matched

    # Get the attribute value for the given machine
    def raw_machine_value(self, machine: Machine) -> Any:
        return self.transform.apply(self.attribute.get(machine))

    # Get the attribute value for the given machine, wrapping (if necessary) in a Set
    def machine_values(self, machine: Machine) -> set:
        # Transform machine value
        machine_value = self.raw_machine_value(machine)
        if self.transform.normalize:
            machine_value = self.attribute.normalize(machine_value)

        # Force to enumerable
        if isinstance(machine_value, list):
            machine_values = set(machine_value)
        elif isinstance(machine_value, set):
            machine_values = machine_value
        else:
            machine_values = {machine_value}

        if not machine_values:
            machine_values = {None}

        return machine_values

    # Whether there's a matching value in the given machine
    def has_match(self, machine: Machine) -> set:
        machine_values = self.machine_values(machine)

        if not self.exact_values.isdisjoint(machine_values):
            # Exact value matched
            return True
        elif self.pattern_values:
            # Look for pattern
            for machine_value in machine_values:
                if machine_value and any(pattern.search(machine_value) for pattern in self.pattern_values):
                    return True

        return False

    # Finds all matching values in the machine
    def find_matches(self, machine: Machine) -> set:
        machine_values = self.machine_values(machine)
        matches = set()

        if self.exact_values:
            matches.update(self.exact_values.intersection(machine_values))

        if self.pattern_values:
            for machine_value in machine_values:
                if machine_value and any(pattern.search(machine_value) for pattern in self.pattern_values):
                    matches.add(machine_value)

        return matches

    # Counts the number of matches in the machine
    def count_matches(self, machine: Machine) -> int:
        return len(self.find_matches(machine))

    # Generates the key to use for sorting the machine with this sorter
    # 
    # If the sorter is ordered, then this is just the value associated with
    # the machine.  Otherwise, it'll be based on the index of the value within
    # the sorter setting.
    def first_match_index(self, machine: Machine) -> Any:
        machine_values = self.machine_values(machine)

        for index, match_value in enumerate(self.values):
            for machine_value in machine_values:
                if isinstance(match_value, Pattern):
                    if machine_value is not None and match_value.search(machine_value):
                        # Found pattern match
                        return index
                        break
                elif machine_value == match_value:
                    # Found exact match
                    return index

        # Default index is lowest
        return len(self.values)

    # Equality based on ID
    def __eq__(self, other) -> bool:
        if isinstance(other, Rule):
            return self.id == other.id
        return False

    # Hash based on ID
    def __hash__(self) -> str:
        return hash(self.id)

    # Object description
    def __str__(self) -> str:
        return f'Rule({self.id})'
