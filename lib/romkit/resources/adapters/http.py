from __future__ import annotations

from romkit.resources.adapters import BaseAdapter

import logging
import math
import pycurl
import requests
import requests.adapters
import shutil
import signal
import threading
import time
from collections import deque

# High-performance HTTP adapter using a multi-threaded approach in order to
# improve download speeds from sites that rate-limit on a per connection
# basis.
# 
# PyCurl is used for the actual download as it has shown to improve the
# performance and stability of connections.
# 
# I found that the requests package would often result in connections being
# replaced and eventually aborted due to the amount of time it would take
# between requests.
class HTTPAdapter(BaseAdapter):
    schemes = ['http', 'https']

    def __init__(self, client: Downloader) -> None:
        super().__init__(client)

        self.session = requests.Session()

        retry_adapter = requests.adapters.Retry(total=self.client.retries, backoff_factor=self.client.backoff_factor)
        http_adapter = requests.adapters.HTTPAdapter(max_retries=retry_adapter)

        self.session.mount('http://', http_adapter)
        self.session.mount('https://', http_adapter)

    # Downloads from an HTTP source to the given local destination file path
    def download(self, source: str, destination: Path) -> None:
        if self.client.auth and self.client.auth.match(source):
            headers = self.client.auth.headers
            cookies = self.client.auth.cookies
        else:
            headers = {}
            cookies = {}

        # By default, download entire file at once
        parts = 1

        # Attempt to see if the download size exceeds the file part threshold
        if self.client.part_threshold != -1:
            # Get the file info without an encoding so that we can see what the
            # real filesize is
            headers['Accept-Encoding'] = ''

            # Find how how big the file is so that we can potentially split the download
            # between many workers
            response = self.session.head(source,
                headers=headers,
                cookies=cookies,
                allow_redirects=True,
                timeout=(self.client.connect_timeout, self.client.timeout),
            )
            response.raise_for_status()
            file_size = int(response.headers.get('Content-Length', 0))

            # Downloader in parts if:
            # * File > threshold
            # * Server accepts Range header
            # * Server cannot encode response
            if file_size > self.client.part_threshold and response.headers.get('Accept-Ranges') == 'bytes' and 'Accept-Encoding' not in response.headers.get('Vary', ''):
                parts = math.ceil(file_size / self.client.part_size)

        if parts == 1:
            # Just downloading the entire file -- ignore its filesize
            file_size = 0

        request = ChunkedRequest(self.client, source, destination, parts=parts, file_size=file_size)
        request.headers = headers
        request.cookies = cookies
        request.perform()

# Represents an http request that will attempt to open multiple connections
# in order to improve overall download speed
class ChunkedRequest:
    def __init__(self, client: Downloader, source: str, destination: Path, parts: int, file_size: int):
        self.client = client
        self.source = source
        self.destination = destination
        self.parts = parts
        self.file_size = file_size

        # Defaults
        self.headers = {}
        self.cookies = {}

        self._default_sigint_handler = signal.getsignal(signal.SIGPIPE)
        self._workers = []

        # Create the queue of parts to download
        self.queue = deque()
        for i in range(self.parts):
            start = client.part_size * i
            end = min(file_size, start + client.part_size)
            self.queue.append({'start': start, 'end': end, 'attempts': 0})

    # Start processing this request
    def perform(self) -> None:
        self._create_destination()

        try:
            self._create_workers()
            self._event_loop()
        finally:
            self.close()

    # Ensure destination file exists
    def _create_destination(self) -> None:
        self.destination.touch()

        # Ensure the file has the expected size so that each connection can write to
        # its own portion
        if self.parts > 1 and self.file_size:
            with self.destination.open('wb') as file:
                file.truncate(self.file_size)

    # Create the workers that'll be processing from the queue
    def _create_workers(self) -> None:
        # Ignore sigpipe since the workers will have NOSIGNAL enabled
        signal.signal(signal.SIGPIPE, self._ignore_signal)

        curl_share = pycurl.CurlShare()
        curl_share.setopt(pycurl.SH_SHARE, pycurl.LOCK_DATA_COOKIE)
        curl_share.setopt(pycurl.SH_SHARE, pycurl.LOCK_DATA_DNS)
        curl_share.setopt(pycurl.SH_SHARE, pycurl.LOCK_DATA_SSL_SESSION)

        # Start up workers to download
        for i in range(min(self.parts, self.client.max_concurrency)):
            worker = Worker(self, i)
            worker.connection.setopt(pycurl.SHARE, curl_share)
            self._workers.append(worker)

    # Starts the event loop in curl
    def _event_loop(self) -> None:
        for worker in self._workers:
            worker.start()

        # Wait for workers to finish
        while True:
            time.sleep(1)

            # Check for an exception
            for worker in self._workers:
                if worker.exception:
                    raise worker.exception

            # See if they're all still alive
            if all([not worker.is_alive() for worker in self._workers]):
                break

    # Simple no-op to ignore certain process signals
    def _ignore_signal(self, *args, **kwargs) -> None:
        pass

    # Closes all open file handles / connections
    def close(self) -> None:
        # Restore signal handler
        signal.signal(signal.SIGPIPE, self._default_sigint_handler)

        for worker in self._workers:
            worker.close()


# Represents a threaded worker that's processed from a request chunk queue
class Worker:
    def __init__(self, request: ChunkedRequest, id: int):
        self.id = id
        self.request = request

        self.connection = pycurl.Curl()
        self.connection.setopt(pycurl.URL, request.source)
        if request.cookies:
            self.connection.setopt(pycurl.COOKIE, ';'.join(f'{key}={value}' for key, value in request.cookies.items()))
        if request.headers:
            self.connection.setopt(pycurl.HTTPHEADER, list(f'{key}: {value}' for key, value in request.headers.items()))

        # Error handling
        self.connection.setopt(pycurl.FAILONERROR, True)
        self.connection.setopt(pycurl.NOSIGNAL, 1)

        # Set basic timeouts
        self.connection.setopt(pycurl.CONNECTTIMEOUT, 30)
        self.connection.setopt(pycurl.TIMEOUT, 300)

        # Allow redirects
        self.connection.setopt(pycurl.FOLLOWLOCATION, True)
        self.connection.setopt(pycurl.MAXREDIRS, 5)

        self.closed = False
        self.exception = None
        self._thread = None

    # The Downloader client
    @property
    def client(self) -> Downloader:
        return self.request.client

    # Start a new thread to consume from the queue
    def start(self) -> None:
        self._thread = threading.Thread(target=self._process_queue)
        self._thread.setDaemon(True)
        self._thread.start()

    # Is this worker still running?
    def is_alive(self) -> bool:
        return self._thread and self._thread.is_alive()

    # Ends any processing by the worker and ensures the connection is closed
    # 
    # Note this will wait for the worker's thread to end before completing.
    def close(self) -> None:
        self.closed = True

        try:
            self.connection.close()
        except Exception as e:
            # Ignore -- we don't want to raise exceptions here
            pass

    # Wait for the worker to finish.  This will throw an exception if one was
    # encountered during the download process.
    def join(self, raise_exception: bool = False) -> None:
        if self._thread:
            self._thread.join()
            self._thread = None

            if raise_exception and self.exception:
                raise self.exception

    # Downloads parts that have been enqueued
    def _process_queue(self) -> None:
        try:
            with self.request.destination.open('r+b') as file:
                self.connection.setopt(pycurl.WRITEDATA, file)

                while self.request.queue and not self.closed:
                    try:
                        chunk = self.request.queue.popleft()
                    except IndexError as e:
                        # Nothing left in queue
                        chunk = None

                    # Nothing left -- finish the thread
                    if not chunk:
                        break

                    self._download_chunk(chunk, file)
        except Exception as e:
            self.exception = e

    # Downloads a remote chunk to the given file
    def _download_chunk(self, chunk: dict, file) -> None:
        start = chunk['start']
        end = chunk['end'] - 1
        file.seek(start)

        # Specify the download range
        if end != -1:
            self.connection.setopt(pycurl.RANGE, '%d-%d' % (start, end))

        try:
            self.connection.perform()
            logging.debug(f'[Connection #{self.id}] Download success for part {start} -> {end}')

            # Use final connection url so we don't have to deal with redirects and
            # closed connections
            effective_url = self.connection.getinfo(self.connection.EFFECTIVE_URL)
            self.connection.setopt(pycurl.URL, effective_url)
        except Exception as e:
            # Reset the source url in case the resolved url is no longer available
            self.connection.setopt(pycurl.URL, self.request.source)

            attempts = chunk['attempts']
            if attempts < self.client.retries:
                # Add back to the queue (in the front, so this is immediately tried again)
                chunk['attempts'] = attempts + 1
                logging.debug(f'[Connection #{self.id}] Download error for part {start} -> {end} (attempt #{attempts}): {e}')
                self.request.queue.appendleft(chunk)
            else:
                # Perma-failure
                raise e
