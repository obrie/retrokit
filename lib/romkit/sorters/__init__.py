from romkit.sorters.sortable_set import SortableSet

from romkit.sorters.description import FlagSorter, FlagsCountSorter, FlagGroupsTotalSorter, KeywordSorter, VersionSorter
from romkit.sorters.name import NameSorter, NameLengthSorter, TitleSorter, TitleLengthSorter
from romkit.sorters.group import IsGroupTitleSorter
from romkit.sorters.parent import IsParentSorter
from romkit.sorters.romset import ROMSetSorter

__all_sorters__ = [
    FlagSorter,
    FlagsCountSorter,
    FlagGroupsTotalSorter,
    KeywordSorter,
    VersionSorter,
    NameSorter,
    NameLengthSorter,
    TitleSorter,
    TitleLengthSorter,
    IsGroupTitleSorter,
    IsParentSorter,
    ROMSetSorter,
]
