from romkit.models import File
from romkit.resources.actions import BaseAction
from romkit.resources.resource_path import ResourcePath
from romkit.util import Downloader

from pathlib import Path
from urllib.parse import quote

class Resource:
    def __init__(self,
        source_url,
        download_path,
        target_path,
        install_action,
        file_identifier,
        downloader,
    ):
        self.source_url = source_url
        self.download_path = ResourcePath.from_path(self, download_path)
        self.target_path = ResourcePath.from_path(self, target_path)
        self.install_action = BaseAction.from_json(install_action)
        self.file_identifier = file_identifier
        self.downloader = downloader
 
    # Downloads files needed for this romset
    def download(self, force=False):
        self.downloader.get(self.source_url, self.download_path.path, force=force)

    def install(self, source_resource=None, force=False, **kwargs):
        if not source_resource:
            source_resource = self

        # Download source
        if not self.target_path.exists() or force:
            source_resource.download()

            # Ensure target directory exists
            Path(self.target_path.path).parent.mkdir(parents=True, exist_ok=True)

            # Install to target
            self.install_action.run(source_resource.download_path, self.target_path, **kwargs)

    # Lists the files that are contained within the resource
    def contains(self, files):
        return self.target_path.contains(files)

    # Runs any post-processing on the target file
    def clean(self, expected_files = None):
        if self.download_path != self.target_path:
            self.download_path.delete()

        self.target_path.clean(expected_files)

    # Creates a symbolic link for this resource to the given target
    def symlink(self, target):
        Path(target).parent.mkdir(parents=True, exist_ok=True)

        self.target_path.symlink(target)

    # Creates a file that's expected to be seen in this resource
    def build_file(self, name, crc):
        return File(name, crc, self.file_identifier)

class ResourceTemplate:
    def __init__(self,
        source_url,
        target_path,
        download_path=None,
        downloader=Downloader.instance(),
        install_action=None,
        discovery=None,
        file_identifier=None,
        default_args={},
    ):
        self.source_url = source_url
        self.target_path = target_path
        self.download_path = download_path or target_path
        self.downloader = downloader
        self.install_action = install_action or {'action': 'copy'}
        self.discovery = discovery
        self.file_identifier = file_identifier or 'crc'
        self.default_args = default_args

    @staticmethod
    def from_json(json, discovery, downloader, default_args={}):
        return ResourceTemplate(
            json['source'],
            json['target'],
            download_path=json.get('download'),
            downloader=downloader,
            install_action=json.get('install'),
            discovery=discovery,
            file_identifier=json.get('file_identifier'),
            default_args=default_args,
        )

    # Builds a URL for an asset in this romset
    def get(self, **args):
        # Add args already assumed to be encoded
        url_args = self.default_args.copy()
        if self.discovery:
            for key, url in self.discovery.mappings().items():
                url_args[f'discovery_{key}'] = url

        # Encode remaining args
        for key, value in args.items():
            url_args[key] = quote(value)

        return Resource(
            source_url=self.source_url.format(**url_args),
            download_path=self.download_path.format(home=str(Path.home()), **args),
            target_path=self.target_path.format(home=str(Path.home()), **args),
            install_action=self.install_action,
            file_identifier=self.file_identifier,
            downloader=self.downloader,
        )
