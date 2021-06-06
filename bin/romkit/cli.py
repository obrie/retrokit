#!/usr/bin/python3

import logging
import os
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from romkit.systems import BaseSystem

import json
from argparse import ArgumentParser
from signal import signal, SIGPIPE, SIG_DFL

class ROMKit:
    def __init__(self,
        action: str,
        config_file: str,
        log_level: str = 'INFO',
        demo: bool = True,
    ) -> None:
        self.action = action

        # Load configuration (and expand env vars)
        with open(config_file) as f:
            self.config = json.loads(os.path.expandvars(f.read()))

        # Set up logger
        root = logging.getLogger()
        root.setLevel(getattr(logging, log_level))
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(getattr(logging, log_level))
        formatter = logging.Formatter('%(asctime)s - %(message)s')
        handler.setFormatter(formatter)
        root.addHandler(handler)

        # Build system
        self.system = BaseSystem.from_json(self.config, demo)

    def run(self) -> None:
        getattr(ROMKit, self.action)(self)

    # Lists machines filtered for this system
    def list(self) -> None:
        for machine in self.system.list():
            print(json.dumps(machine.dump()))

    # Installs the list of filtered machines onto the local filesystem
    def install(self) -> None:
        self.system.install()

    # Rewrites the rom directory structure based on current filters
    def organize(self) -> None:
        self.system.organize()

    # Removes machines that are not currently installed
    def vacuum(self) -> None:
        self.system.vacuum()


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument(dest='action', help='Action to perform', choices=['list', 'install', 'organize', 'vacuum'])
    parser.add_argument(dest='config_file', help='JSON file containing the configuration')
    parser.add_argument('--log-level', dest='log_level', help='Log level', default='INFO', choices=['DEBUG', 'INFO', 'WARN', 'ERROR'])
    parser.add_argument('--demo', dest='demo', action='store_true')
    parser.add_argument('--no-demo', dest='demo', action='store_false')
    parser.set_defaults(demo=(os.getenv('ROMKIT_DEMO', 'True').lower() == 'true'))
    args = parser.parse_args()
    ROMKit(**vars(args)).run()


if __name__ == '__main__':
    signal(SIGPIPE, SIG_DFL)
    main()
