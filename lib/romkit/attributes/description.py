from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Machine descriptions (same as name except for arcade systems)
class DescriptionsAttribute(BaseAttribute):
    rule_name = 'descriptions'
    data_type = str

    def get(self, machine: Machine) -> str:
        return f'{machine.description} ({machine.comment})'


# Machine comments
class CommentsAttribute(BaseAttribute):
    rule_name = 'comments'
    data_type = str

    def get(self, machine: Machine) -> str:
        return machine.comment


# Individual Flags (text between parens) from the description
class FlagAttribute(BaseAttribute):
    rule_name = 'flags'
    data_type = str

    def get(self, machine: Machine) -> Set[str]:
        return machine.flags


# All Flags (text between parens) from the description
class CombinedFlagAttribute(BaseAttribute):
    rule_name = 'combined_flags'
    data_type = str

    def get(self, machine: Machine) -> Set[str]:
        return machine.flags_str


# Total number of flag groups in the name
class FlagGroupsTotalAttribute(BaseAttribute):
    rule_name = 'flag_groups_total'
    data_type = int

    def get(self, machine: Machine) -> int:
        return machine.flags_str.count('(')

