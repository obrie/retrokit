from __future__ import annotations

from romkit.models.file import File
from romkit.resources.actions import BaseAction, Copy
from romkit.resources.actions.stub import Stub, StubDownloader
from romkit.resources.resource_path import ResourcePath
from romkit.util import Downloader

from pathlib import Path
from typing import Optional, Set
from urllib.parse import quote
from urllib.parse import urlparse

class Resource:
    def __init__(self,
        # Source url
        source_url: str,
        # Cached url (if source isn't available)
        cached_source_url: Optional[str],
        # Path to store the resource
        target_path: Optional[Path],
        # Path to store a reference to the target based on a stable identifier
        xref_path: Optional[Path],
        # Path to store the downloaded source (before processing)
        download_path: Optional[Path],
        # Action to run for postprocessing the downloaded source
        install_action: BaseAction,
        # How to uniquely identify files in a resource
        file_identifier: str,
        # Whether the files in a resource are predefined in the DAT.  This can be useful
        # if some resources don't define their full list of internal files (e.g. machines
        # and their roms) but should still be downloaded.
        predefined: bool,
        # Client to use for downloading
        downloader: Downloader,
    ) -> None:
        self.source_url = source_url

        # Used the cached source if the primary source doesn't exist
        if cached_source_url and self.is_locally_sourced and not self.source_url_path.exists():
            self.source_url = cached_source_url

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

        if xref_path:
            self.xref_path = ResourcePath.from_path(self, xref_path)
        else:
            self.xref_path = None

        self.install_action = install_action
        # Don't delete the source on install if locally sourced
        if self.is_locally_sourced and 'delete_source' not in self.install_action.config:
            self.install_action.config['delete_source'] = False

        self.file_identifier = file_identifier
        self.predefined = predefined
        self.downloader = downloader

    # The path of the source url, intended to only be used with a file protocol
    @property
    def source_url_path(self) -> Path:
        return Path(urlparse(self.source_url).path)
 
    # Whether this resource is located locally on the system
    @property
    def is_locally_sourced(self) -> bool:
        return urlparse(self.source_url).scheme == 'file'

    # Whether this resources exists on disk
    def exists(self) -> bool:
        return self.target_path.exists()

    # Downloads files needed for this romset
    def download(self, force: bool = False) -> None:
        self.downloader.get(self.source_url, self.download_path.path, force=force)

    # Installs from the given source
    def install(self, source: Optional[Resource] = None, force: bool = False, **kwargs) -> None:
        if not source:
            source = self

        # Download source if:
        # * Target doesn't exist
        # * Source is from the local filesystem, target isn't the same, and install action allows overwrites
        # * Explicitly forcing a download
        if not self.exists() or (self.is_locally_sourced and self.target_path.path != self.source_url_path and self.source_url_path.exists() and self.install_action.overwrite_target) or force:
            source.download()

            # Ensure target directory exists
            self.target_path.path.parent.mkdir(parents=True, exist_ok=True)

            # Install to target
            self.install_action.install(source.download_path, self.target_path, **kwargs)

    # If there's a valid cross-reference symlink for the target and the target doesn't exist,
    # rely on the symlink to create the new target
    def check_xref(self) -> None:
        if self.xref_path and self.xref_path.exists() and not self.exists():
            self.target_path.path.parent.mkdir(parents=True, exist_ok=True)
            self.xref_path.realpath().rename(self.target_path.path)

    # Make sure the cross-reference path reflects the current target path
    def create_xref(self) -> str:
        if self.xref_path:
            # Ensure xref directory exists
            self.xref_path.path.parent.mkdir(parents=True, exist_ok=True)
            self.xref_path.symlink_to(self.target_path)

    # Determines whether the given files are contained within the target resource path
    def contains(self, files: Set[File]) -> bool:
        return self.target_path.contains(files)

    # Runs any post-processing on the target file
    def clean(self, expected_files: Optional[Set[File]] = None) -> None:
        if self.download_path != self.target_path and (not self.is_locally_sourced or self.download_path.path != self.source_url_path):
            self.download_path.delete()

        self.target_path.clean(expected_files)

    # Creates a file that's expected to be seen in this resource
    def build_file(self, name: str, size: int, crc: str) -> File:
        return File(name, size, crc, self.file_identifier)

class ResourceTemplate:
    def __init__(self,
        # Source url
        source_url_template: str,
        # Cached url (if source isn't available)
        cached_source_url_template: Optional[str] = None,
        # Path to store the resource
        target_path_template: Optional[str] = None,
        # Path to store a reference to the target based on a stable identifier
        xref_path_template: Optional[str] = None,
        # Path to store the downloaded source (before processing)
        download_path_template: Optional[str] = None,
        # Client to use for downloading
        downloader: Downloader = Downloader.instance(),
        # Action to run for postprocessing the downloaded source
        install_action: BaseAction = Copy(),
        # Dynamic context to pull for each machine
        discovery: Optional[BaseDiscovery] = None,
        # How to uniquely identify files in a resource
        file_identifier: str = 'crc',
        # Whether the files in a resource are predefined in the DAT
        predefined: bool = True,
        # The default context to use when interpolating templates
        default_context: dict = {},
        # Whether to generate stubbed resource target paths (empty files/directories)
        stub: bool = False,
    ):
        self.source_url_template = source_url_template
        self.cached_source_url_template = cached_source_url_template
        self.target_path_template = target_path_template
        self.xref_path_template = xref_path_template
        self.download_path_template = download_path_template
        self.downloader = downloader
        self.install_action = install_action
        self.discovery = discovery
        self.file_identifier = file_identifier
        self.predefined = predefined
        self.default_context = default_context

        if stub:
            source_is_local = urlparse(source_url_template).scheme == 'file'

            download_path = download_path_template and Path(download_path_template)
            download_path_exists = download_path and download_path.exists() and download_path.stat().st_size > 0

            target_path = target_path_template and Path(target_path_template)
            target_path_exists = target_path and target_path.exists() and target_path.stat().st_size > 0

            if not(source_is_local or download_path_exists or target_path_exists):
                self.install_action = Stub({})
                self.downloader = StubDownloader()

    @classmethod
    def from_json(cls, json: dict, **kwargs) -> ResourceTemplate:
        install_action = BaseAction.from_json(json.get('install', {'action': 'copy'}))

        return cls(
            json['source'],
            cached_source_url_template=json.get('cached_source'),
            target_path_template=json.get('target'),
            xref_path_template=json.get('xref'),
            download_path_template=json.get('download'),
            install_action=install_action,
            file_identifier=json.get('file_identifier', 'crc'),
            predefined=json.get('predefined', True),
            **kwargs
        )

    # The path of the source url, intended to only be used with a file protocol
    @property
    def source_url_path(self) -> Path:
        return Path(urlparse(self.source_url_template).path)

    # Whether this resource is located locally on the system
    @property
    def is_locally_sourced(self) -> bool:
        return urlparse(self.source_url_template).scheme == 'file'

    # Builds a URL for an asset in this romset
    def render(self, **context) -> Resource:
        # Add context already assumed to be encoded
        url_context = self.default_context.copy()
        if self.discovery:
            for key, url in self.discovery.mappings(context).items():
                url_context[f'discovery_{key}'] = url

        # Encode remaining context
        for key, value in context.items():
            if isinstance(value, str) or value is None:
                url_context[key] = quote(value)

        return Resource(
            source_url=self._render_template(self.source_url_template, url_context),
            cached_source_url=self._render_template(self.cached_source_url_template, url_context),
            target_path=self._render_path(self.target_path_template, context),
            xref_path=self._render_path(self.xref_path_template, context),
            download_path=self._render_path(self.download_path_template, context),
            install_action=self.install_action,
            file_identifier=self.file_identifier,
            predefined=self.predefined,
            downloader=self.downloader,
        )

    # Renders a Path based on the given template
    def _render_path(self, path_template: Optional[str], context: dict) -> Optional[Path]:
        rendered_template = self._render_template(path_template, context)
        if rendered_template:
            return Path(rendered_template)

    # Renders a string based on the given template
    def _render_template(self, path_template: Optional[str], context: dict) -> Optional[str]:
        if path_template:
            return path_template.format(**context)
