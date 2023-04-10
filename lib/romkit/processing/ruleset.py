from __future__ import annotations

from romkit.processing.rule import Rule

from enum import Enum

class RuleMatchReason(Enum):
    ALLOW = 1
    OVERRIDE = 2


# Represents a collection of attribute rules
class Ruleset:
    # Name of the key used to identify enabled rules
    ENABLED_KEY = 'enabled'
    RESERVED_KEYS = {ENABLED_KEY}

    def __init__(self,
        default_on_empty: Optional[RuleMatchReason] = RuleMatchReason.ALLOW,
        log: bool = True,
    ) -> None:
        self.rules = []
        self.overrides = []
        self.default_on_empty = default_on_empty
        self.log = log

    # Builds a Ruleset from the given json data
    @classmethod
    def from_json(cls, json: dict, attributes: List[BaseAttribute], **kwargs) -> FilterSet:
        ruleset = cls(**kwargs)

        # Determine which configurations are actively being used
        rules = {key: json[key] for key in json if key not in cls.RESERVED_KEYS}
        enabled_rule_ids = set(json.get(cls.ENABLED_KEY, rules.keys()))

        for expression, values in rules.items():
            if values is None:
                # Explicitly disabled (e.g. {"names": null"})
                continue

            rule_id = Rule.id_for(expression)
            if rule_id not in enabled_rule_ids:
                # Not in the enabled list
                continue

            # Ensure expression is enabled (e.g. {"#names": [...]})
            rule = Rule.parse(expression, values, attributes)
            if rule.enabled:
                ruleset.add(rule)

        return ruleset

    # Merges in a new rule
    def add(self, rule: Rule) -> None:
        rule.log = self.log

        existing_rule = next(filter(lambda r: r.id == rule.id, self.rules + self.overrides), None)
        if existing_rule:
            existing_rule.merge(rule)
        elif rule.override:
            self.overrides.append(rule)
        else:
            self.rules.append(rule)

        self._optimize()

    # Whether the given machine matches
    def match(self, machine: Machine) -> Optional[RuleMatchReason]:
        if not self.overrides and not self.rules:
            return self.default_on_empty

        # Check if an override rule matches this match and which specific attributes
        # resulted in a match
        matched_by_override = False
        matched_by_override_attributes = set()
        for rule in self.overrides:
            if rule.match(machine):
                matched_by_override = True
                matched_by_override_attributes.add(rule.attribute_name)

                if rule.attribute_name == 'names':
                    break
        
        # Some rules apply even if an override is matched (e.g. emulation compatibility)
        matched = all((matched_by_override and not rule.attribute.apply_to_overrides) or rule.match(machine) for rule in self.rules)

        if matched:
            if matched_by_override and 'names' in matched_by_override_attributes:
                # Only explicit names will override everything else
                return RuleMatchReason.OVERRIDE
            else:
                # Either this was an override rule that ignored other rules or
                # all rules agreed that this machine is allowed
                return RuleMatchReason.ALLOW

    # Optimizes the ruleset processing by sorting the rules by expected performance characteristics
    def _optimize(self) -> None:
        for rules in [self.rules, self.overrides]:
            rules.sort(key=lambda r: len(r.exact_values))
            rules.sort(key=lambda r: len(r.pattern_values))
