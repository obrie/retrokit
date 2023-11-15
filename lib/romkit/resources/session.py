from __future__ import annotations

from romkit.util.dict_utils import deepmerge, slice_only

class Session:
    def __init__(self,
        # Maximum number of concurrent chunks to download at once
        max_concurrency: int = 5,
        # File size after which the file will be split into multiple parts
        part_threshold: int = 10 * 1024 * 1024,
        # The size of parts that are downloaded in each thread
        part_size: int = 1 * 1024 * 1024,
        # Timeout *after* connection when no data is received
        timeout: int = 300,
        # Timeout of initial connection
        connect_timeout: int = 15,
        # Number of times to re-attempt a download
        retries: int = 3,
        # Backoff factor to apply between attempts
        backoff_factor: float = 2.0,
        # HTTP Headers
        headers: dict = {},
        # HTTP Cookies
        cookies: dict = {},
    ) -> None:
        self.max_concurrency = max_concurrency
        self.part_threshold = part_threshold
        self.part_size = part_size
        self.timeout = timeout
        self.connect_timeout = connect_timeout
        self.retries = retries
        self.backoff_factor = backoff_factor
        self.headers = headers
        self.cookies = cookies

    @classmethod
    def from_json(cls, json: dict, **kwargs) -> Session:
        return cls(
            **slice_only(json, [
                'max_concurrency',
                'part_threshold',
                'part_size',
                'timeout',
                'connect_timeout',
                'retries',
                'backoff_factor',
                'headers',
                'cookies',
            ],
            **kwargs,
        ))

    def with_overrides(self, overrides: dict = {}) -> dict:
        return Session(
            max_concurrency=overrides.get('max_concurrency', self.max_concurrency),
            part_threshold=overrides.get('part_threshold', self.part_threshold),
            part_size=overrides.get('part_size', self.part_size),
            timeout=overrides.get('timeout', self.timeout),
            connect_timeout=overrides.get('connect_timeout', self.connect_timeout),
            retries=overrides.get('retries', self.retries),
            backoff_factor=overrides.get('backoff_factor', self.backoff_factor),
            headers=deepmerge(self.headers.copy(), overrides.get('headers', {})),
            cookies=deepmerge(self.cookies.copy(), overrides.get('cookies', {})),
        )
