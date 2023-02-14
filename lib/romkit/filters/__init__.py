from romkit.filters.base import BaseFilter
from romkit.filters.filter_set import FilterReason, FilterSet

from romkit.filters.age_rating import AgeRatingFilter
from romkit.filters.bios import BIOSFilter, RunnableFilter
from romkit.filters.control import ControlFilter, PlayerFilter
from romkit.filters.description import FlagFilter, DescriptionFilter
from romkit.filters.emulator import EmulatorFilter, EmulatorCompatibilityFilter, EmulatorRatingFilter
from romkit.filters.favorite import FavoriteFilter
from romkit.filters.filesystem import FilesystemFilter
from romkit.filters.language import LanguageFilter
from romkit.filters.manual import ManualFilter
from romkit.filters.mechanical import MechanicalFilter
from romkit.filters.media import MediaFilter
from romkit.filters.name import NameFilter, TitleFilter
from romkit.filters.orientation import OrientationFilter
from romkit.filters.parent import CloneFilter, ParentNameFilter, ParentTitleFilter
from romkit.filters.peripheral import PeripheralFilter
from romkit.filters.rating import RatingFilter
from romkit.filters.release import DeveloperFilter, PublisherFilter, YearFilter
from romkit.filters.romset import ROMSetFilter
from romkit.filters.system import SystemFilter
from romkit.filters.taxonomy import CategoryFilter, CollectionFilter, GenreFilter, TagFilter, SeriesFilter

# The order here helps in terms of performance, so we should order it based
# on which filters are most likely to reject a game
__all_filters__ = [
    # Each group is:
    # * Categorized by speed of the lookup
    # * Ordered by most likely to filter out a machine

    # Non-string exact filters
    CloneFilter,
    BIOSFilter,
    RunnableFilter,
    MechanicalFilter,
    EmulatorCompatibilityFilter,
    EmulatorRatingFilter,
    RatingFilter,
    PlayerFilter,
    YearFilter,
    AgeRatingFilter,
    FavoriteFilter,
    ManualFilter,
    FilesystemFilter,
    SystemFilter,

    # Typically exact string filters
    NameFilter,
    LanguageFilter,
    ControlFilter,
    EmulatorFilter,
    ROMSetFilter,
    PeripheralFilter,
    DeveloperFilter,
    PublisherFilter,
    TagFilter,
    CategoryFilter,
    OrientationFilter,
    MediaFilter,
    CollectionFilter,
    SeriesFilter,

    # Typically complex filters
    FlagFilter,
    DescriptionFilter,
    TitleFilter,
    GenreFilter,
    ParentNameFilter,
    ParentTitleFilter,
]
