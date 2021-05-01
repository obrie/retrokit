from __future__ import annotations

from romkit.models import File
from romkit.resources.actions import BaseAction, Copy
from romkit.resources.resource_path import ResourcePath
from romkit.util import Downloader

from pathlib import Path
from typing import Optional, Set
from urllib.parse import quote
from urllib.parse import urlparse

class Resource:
    def __init__(self,
        source_url: str,
        target_path: Optional[Path],
        download_path: Optional[Path],
        install_action: BaseAction,
        file_identifier: str,
        downloader: Downloader,
    ) -> None:
        self.source_url = source_url

        # If locally sourced and we're not defining an explicit target, use the source
        # as the target path.  Note a target must be defined if not locally sourced.
        if not target_path:
            if self.is_locally_sourced:
                # Source is rom local filesystem: target path should be the same
                target_path = self.source_url_path
            else:
                # Source is remote: user must explicitly provide a target
                raise Exception(f'Target path must be provided for {source_url}')
        self.target_path = ResourcePath.from_path(self, target_path)

        if not download_path:
            if self.is_locally_sourced:
                # Source is from local filesystem: download path should be the same
                download_path = self.source_url_path
            else:
                # Source is remote: download path is same as target
                download_path = target_path
        self.download_path = ResourcePath.from_path(self, download_path)

        self.install_action = install_action
        self.file_identifier = file_identifier
        self.downloader = downloader

    # The path of the source url, intended to only be used with a file protocol
    @property
    def source_url_path(self) -> Path:
        return Path(urlparse(self.source_url).path)
 
    # Whether this resource is located locally on the system
    @property
    def is_locally_sourced(self) -> bool:
        return urlparse(self.source_url).scheme == 'file'

    # Downloads files needed for this romset
    def download(self, force: bool = False) -> None:
        self.downloader.get(self.source_url, self.download_path.path, force=force)

    # Installs from the given source
    def install(self, source: Optional[Resource] = None, force: bool = False, **kwargs) -> None:
        if not source:
            source = self

        # Download source if:
        # * Target doesn't exist
        # * Source is from the local filesystem and the target isn't the same (always reinstall)
        # * Explicitly forcing a download
        if not self.target_path.exists() or (self.is_locally_sourced and self.target_path.path != self.source_url_path) or force:
            source.download()

            # Ensure target directory exists
            self.target_path.path.parent.mkdir(parents=True, exist_ok=True)

            # Install to target
            self.install_action.install(source.download_path, self.target_path, **kwargs)

    # Determines whether the given files are contained within the target resource path
    def contains(self, files: Set[File]) -> bool:
        return self.target_path.contains(files)

    # Runs any post-processing on the target file
    def clean(self, expected_files: Optional[Set[File]] = None) -> None:
        if self.download_path != self.target_path:
            self.download_path.delete()

        self.target_path.clean(expected_files)

    # Creates a file that's expected to be seen in this resource
    def build_file(self, name: str, crc: str) -> File:
        return File(name, crc, self.file_identifier)

class ResourceTemplate:
    def __init__(self,
        source_url_template: str,
        target_path_template: Optional[str],
        download_path_template: Optional[str] = None,
        downloader: Downloader = Downloader.instance(),
        install_action: BaseAction = Copy(),
        discovery: Optional[BaseDiscovery] = None,
        file_identifier: str = 'crc',
        default_context: dict = {},
    ):
        self.source_url_template = source_url_template
        self.target_path_template = target_path_template
        self.download_path_template = download_path_template
        self.downloader = downloader
        self.install_action = install_action
        self.discovery = discovery
        self.file_identifier = file_identifier
        self.default_context = default_context

    @classmethod
    def from_json(cls, json: dict, **kwargs) -> ResourceTemplate:
        install_action = BaseAction.from_json(json.get('install', {'action': 'copy'}))

        return cls(
            json['source'],
            target_path_template=json.get('target'),
            download_path_template=json.get('download'),
            install_action=install_action,
            file_identifier=json.get('file_identifier', 'crc'),
            **kwargs
        )

    # Builds a URL for an asset in this romset
    def render(self, **context) -> Resource:
        # Add context already assumed to be encoded
        url_context = self.default_context.copy()
        if self.discovery:
            for key, url in self.discovery.mappings().items():
                url_context[f'discovery_{key}'] = url

        # Encode remaining context
        for key, value in context.items():
            url_context[key] = quote(value)

        return Resource(
            source_url=self.source_url_template.format(**url_context),
            target_path=self._render_path(self.target_path_template, context),
            download_path=self._render_path(self.download_path_template, context),
            install_action=self.install_action,
            file_identifier=self.file_identifier,
            downloader=self.downloader,
        )

    # Renders a Path based on the given template
    def _render_path(self, path_template: Optional[str], context: dict) -> Optional[Path]:
        if path_template:
            return Path(path_template.format(home=str(Path.home()), **context))
