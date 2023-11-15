from __future__ import annotations

import logging
import shutil
from pathlib import Path

# Base class for defining adapters to handle downloading from different URI schemes
class BaseAdapter:
    # List of URI schemes this adapter is capable of handling
    schemes = []

    # Whether to download files via this adapter even if the target file already exists
    def force(self, source: str, destination: Path) -> bool:
        return False

    # Downloads from a remote source to the given local destination file path
    def download(self, source: str, destination: Path, session: Session) -> None:
        pass
