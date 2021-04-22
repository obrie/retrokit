from romkit.systems import BaseSystem
from romkit.systems.arcade.emulator_set import ArcadeEmulatorSet
from romkit.systems.arcade.filters import LanguageFilter, CategoryFilter, RatingFilter

class ArcadeSystem(BaseSystem):
    name = 'arcade'
    dynamic_filters = BaseSystem.dynamic_filters + [
        LanguageFilter,
        CategoryFilter,
        RatingFilter,
    ]
    emulator_set_class = ArcadeEmulatorSet
