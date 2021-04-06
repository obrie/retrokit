from romkit.systems import BaseSystem
from romkit.filters.arcade import LanguageFilter, CategoryFilter, RatingFilter, EmulatorFilter

class ArcadeSystem(BaseSystem):
    name = 'arcade'
    user_filters = BaseSystem.user_filters + [
        LanguageFilter,
        CategoryFilter,
        RatingFilter,
    ]
    auto_filters = BaseSystem.auto_filters + [
      EmulatorFilter,
    ]
