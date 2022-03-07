from romkit.systems import BaseSystem
from romkit.metadata import EmulatorMetadata
from romkit.systems.arcade.metadata import GenreMetadata, LanguageMetadata, RatingMetadata

class ArcadeSystem(BaseSystem):
    name = 'arcade'
    supported_metadata = BaseSystem.supported_metadata + [
      GenreMetadata,
      LanguageMetadata,
      RatingMetadata,
    ]
