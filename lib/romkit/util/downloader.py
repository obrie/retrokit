from __future__ import annotations

from romkit.auth import BaseAuth

import logging
import math
import pycurl
import requests
import shutil
import tempfile
import threading
from queue import Queue
from pathlib import Path, PurePath
from urllib.parse import urlparse

# High-performance downloader using a multi-threaded approach in order to
# improve download speeds from sites that rate-limit on a per connection
# basis.
# 
# PyCurl is used for the actual download as it has shown to improve the
# performance and stability of connections.
# 
# I found that the requests package would often result in connections being
# replaced and eventually aborted due to the amount of time it would take
# between requests.
class Downloader:
    _instance = None

    def __init__(self,
        auth: str = None,
        # Number of threads to run per download
        concurrency: int = 5,
        # File size after which the file will be split into multiple parts
        part_threshold: int = 10 * 1024 * 1024,
        # The size of parts that are downloaded in each thread
        part_size: int = 1 * 1024 * 1024,
    ) -> None:
        self.auth = auth and BaseAuth.from_name(auth)
        self.concurrency = concurrency
        self.part_threshold = part_threshold
        self.part_size = part_size
        self.session = requests.Session()

    @classmethod
    def instance(cls) -> Downloader:
        if cls._instance is None:
            cls._instance = cls.__new__(cls)
            cls._instance.__init__()
        return cls._instance

    # Attempts to download from the given source unless either:
    # * It already exists in the destination
    # * The file is being force-refreshed
    def get(self, source: str, destination: Path, force: bool = False) -> None:
        if not source:
            raise requests.exceptions.URLRequired()

        source_uri = urlparse(source)

        # Ensure directory exists
        destination.parent.mkdir(parents=True, exist_ok=True)

        if source_uri.scheme == 'file':
            # Copy directly from the filesystem
            if source_uri.path != str(destination):
                logging.debug(f'Copying {source} to {destination}')
                shutil.copyfile(source_uri.path, destination)
        elif not destination.exists() or destination.stat().st_size == 0 or force:
            # Re-download the file
            logging.debug(f'Downloading {source} to {destination}')
            with tempfile.TemporaryDirectory() as tmp_dir:
                # Initially download to a temporary directory so we don't overwrite until
                # the download is completed successfully
                download_path = Path(tmp_dir).joinpath(destination.name)

                self.download(source, download_path)

                if download_path.stat().st_size > 0:
                    # Rename file to final destination
                    download_path.rename(destination)
                else:
                    download_path.unlink()
                    raise requests.exceptions.HTTPError()

    def download(self, source: str, destination: Path) -> None:
        if self.auth and self.auth.match(source):
            headers = self.auth.headers
            cookies = self.auth.cookies
        else:
            headers = {}
            cookies = {}

        # Get the file info without an encoding so that we can see what the
        # real filesize is
        headers['Accept-Encoding'] = ''

        # Find how how big the file is so that we can potentially split the download
        # between many workers
        response = self.session.head(source, headers=headers, cookies=cookies, allow_redirects=True)
        response.raise_for_status()
        file_size = int(response.headers.get('Content-Length', 0))

        # Downloader in parts if:
        # * File > threshold
        # * Server accepts Range header
        # * Server cannot encode response
        if file_size > self.part_threshold and response.headers.get('Accept-Ranges') == 'bytes' and 'Accept-Encoding' not in response.headers.get('Vary', ''):
            parts = math.ceil(file_size / self.part_size)

            # Create a file with the expect size so that each thread can write to
            # its own portion
            with destination.open('wb') as file:
                file.truncate(file_size)
        else:
            # Download with a single thread
            destination.touch()
            parts = 1
            file_size = 0

        # Create the queue of parts to download
        queue = Queue()
        for i in range(parts):
            start = self.part_size * i
            end = min(file_size, start + self.part_size)
            queue.put({'start': start, 'end': end})

        # Start up workers to download
        workers = []
        for i in range(min(parts, self.concurrency)):
            worker = Worker(queue, source, destination, headers, cookies)
            worker.start()
            workers.append(worker)

        try:
            # Wait for workers to finish
            for worker in workers:
                worker.join(raise_exception=True)
        except Exception as e:
            # Empty the queue
            with queue.mutex:
                queue.queue.clear()

            # Wait for all workers to finish, ignoring any exceptions
            for worker in workers:
                worker.join()

            raise e


class Worker:
    def __init__(self, queue: Queue, source: str, destination: Path, headers: dict, cookies: dict):
        self.queue = queue
        self.destination = destination
        self.connection = pycurl.Curl()
        self.connection.setopt(pycurl.COOKIE, ';'.join(f'{key}={value}' for key, value in cookies.items()))
        self.connection.setopt(pycurl.FOLLOWLOCATION, True)
        self.connection.setopt(pycurl.HTTPHEADER, list(f'{key}: {value}' for key, value in headers.items()))
        self.connection.setopt(pycurl.URL, source)
        self.connection.setopt(pycurl.FAILONERROR, True)

        self.exception = None
        self.thread = None

    # Start a new thread to consume from the queue
    def start(self) -> None:
        self.thread = threading.Thread(target=self.download)
        self.thread.setDaemon(True)
        self.thread.start()

    # Wait for the worker to finish.  This will throw an exception if one was
    # encountered during the download process.
    def join(self, raise_exception: bool = False) -> None:
        if self.thread:
            self.thread.join()
            self.thread = None

            if raise_exception and self.exception:
                raise self.exception

    # Downloads parts that have been enqueued
    def download(self) -> None:
        try:
            with self.destination.open('r+b') as file:
                self.connection.setopt(pycurl.WRITEDATA, file)

                while not self.queue.empty():
                    request = self.queue.get_nowait()

                    # Nothing left -- finish the thread
                    if not request:
                        break

                    start = request['start']
                    end = request['end'] - 1
                    file.seek(start)

                    # Specify the download range
                    if end != -1:
                        self.connection.setopt(pycurl.RANGE, '%d-%d' % (start, end))

                    self.connection.perform()

                self.connection.close()
        except Exception as e:
            self.exception = e
