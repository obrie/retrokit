#!/usr/bin/python3

import logging
import os
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from romkit.systems import BaseSystem
from romkit.output.set_encoder import SetEncoder

import json
from argparse import ArgumentParser
from signal import signal, SIGPIPE, SIG_DFL

class ROMKit:
    def __init__(self,
        action: str,
        config_file: str,
        log_level: str = 'INFO',
    ) -> None:
        self.action = action

        # Load configuration (and expand env vars)
        with open(config_file) as f:
            self.config = json.loads(os.path.expandvars(f.read()))

        # Set up logger
        logging.basicConfig(level=getattr(logging, log_level), format='%(asctime)s - %(message)s', stream=sys.stdout)

        # Build system
        self.system = BaseSystem.from_json(self.config)

    def run(self, **kwargs) -> None:
        getattr(ROMKit, self.action)(self, **kwargs)

    # Lists machines filtered for this system
    def list(self) -> None:
        for machine in self.system.list():
            print(json.dumps(machine.dump(), cls=SetEncoder))

    # Installs the list of filtered machines onto the local filesystem
    def install(self, resources: str = None) -> None:
        if resources:
            resources = set(resources.split(','))

        self.system.install(resource_names=resources)

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
    args, action_args = parser.parse_known_args()
    args = {k: v for k, v in vars(args).items() if v is not None}
    ROMKit(**args).run(**{arg.split('=')[0]: arg.split('=')[1] for arg in action_args})


if __name__ == '__main__':
    signal(SIGPIPE, SIG_DFL)
    main()
