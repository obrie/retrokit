from romkit.metadata.base import BaseMetadata
from romkit.metadata.metadata_set import MetadataSet

from romkit.metadata.controls import ControlsMetadata
from romkit.metadata.emulation import EmulationMetadata
from romkit.metadata.genres import GenresMetadata
from romkit.metadata.languages import LanguagesMetadata
from romkit.metadata.manuals import ManualsMetadata
from romkit.metadata.media import MediaMetadata
from romkit.metadata.parents import ParentsMetadata
from romkit.metadata.players import PlayersMetadata
from romkit.metadata.rating import RatingMetadata
from romkit.metadata.renames import RenamesMetadata
from romkit.metadata.tags import TagsMetadata

__all_metadata__ = [
    ParentsMetadata,
    ControlsMetadata,
    EmulationMetadata,
    GenresMetadata,
    LanguagesMetadata,
    ManualsMetadata,
    MediaMetadata,
    PlayersMetadata,
    RatingMetadata,
    RenamesMetadata,
    TagsMetadata,
]
