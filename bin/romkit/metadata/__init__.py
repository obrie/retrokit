from romkit.metadata.external import ExternalMetadata
from romkit.metadata.metadata_set import MetadataSet

from romkit.metadata.emulator import EmulatorMetadata
from romkit.metadata.manual import ManualMetadata
from romkit.metadata.parent import ParentMetadata
from romkit.metadata.rename import RenameMetadata
from romkit.metadata.scraper import ScraperMetadata

__all_metadata__ = [
    ParentMetadata,
    EmulatorMetadata,
    ManualMetadata,
    RenameMetadata,
    ScraperMetadata,
]
