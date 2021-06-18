from romkit.systems import BaseSystem
from romkit.metadata import EmulatorMetadata
from romkit.systems.arcade.metadata import ArcadeEmulatorMetadata, GenreMetadata, LanguageMetadata, RatingMetadata

class ArcadeSystem(BaseSystem):
    name = 'arcade'
    supported_metadata = [cls for cls in BaseSystem.supported_metadata if cls != EmulatorMetadata] + [
      ArcadeEmulatorMetadata,
      GenreMetadata,
      LanguageMetadata,
      RatingMetadata,
    ]
