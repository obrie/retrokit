from romkit.filters.base import BaseFilter, ExactFilter, SubstringFilter
from romkit.filters.filter_set import FilterReason, FilterSet

from romkit.filters.control import ControlFilter, PlayerFilter
from romkit.filters.description import FlagFilter, KeywordFilter
from romkit.filters.emulator import EmulatorFilter, EmulatorCompatibilityFilter, EmulatorRatingFilter
from romkit.filters.favorite import FavoriteFilter
from romkit.filters.language import LanguageFilter
from romkit.filters.manual import ManualFilter
from romkit.filters.name import NameFilter, PartialNameFilter, TitleFilter
from romkit.filters.orientation import OrientationFilter
from romkit.filters.parent import CloneFilter, ParentNameFilter, PartialParentNameFilter, ParentTitleFilter
from romkit.filters.rating import RatingFilter
from romkit.filters.romset import ROMSetFilter
from romkit.filters.taxonomy import CategoryFilter, CollectionFilter, GenreFilter, TagFilter

# The order here helps in terms of performance, so we should order it based
# on which filters are most likely to reject a game
__all_filters__ = [
    CloneFilter,
    FlagFilter,
    KeywordFilter,
    ControlFilter,
    PlayerFilter,
    NameFilter,
    PartialNameFilter,
    TitleFilter,
    EmulatorFilter,
    EmulatorCompatibilityFilter,
    GenreFilter,
    CategoryFilter,
    CollectionFilter,
    TagFilter,
    RatingFilter,
    EmulatorRatingFilter,
    LanguageFilter,
    FavoriteFilter,
    ROMSetFilter,
    OrientationFilter,
    ManualFilter,
    ParentNameFilter,
    PartialParentNameFilter,
    ParentTitleFilter,
]
