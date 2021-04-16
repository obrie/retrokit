from romkit.systems import BaseSystem
from romkit.filters.arcade import LanguageFilter, CategoryFilter, RatingFilter, EmulatorFilter

class ArcadeSystem(BaseSystem):
    name = 'arcade'
    dynamic_filters = BaseSystem.dynamic_filters + [
        LanguageFilter,
        CategoryFilter,
        RatingFilter,
    ]
    static_filters = BaseSystem.static_filters + [
        EmulatorFilter,
    ]
