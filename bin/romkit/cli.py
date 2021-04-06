#!/usr/bin/python3

import logging
import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

from romkit.systems import BaseSystem

from argparse import ArgumentParser
import json

class ROMKit:
    def __init__(self, action, config_file, log_level):
        self.action = action

        # Load configuration
        with open(config_file) as f:
            self.config = json.load(f)
        self.config['roms'].setdefault('allowlists', {})
        self.config['roms'].setdefault('blocklists', {})
        self.config['roms'].setdefault('favorites', [])

        # Setup logger
        root = logging.getLogger()
        root.setLevel(getattr(logging, log_level))
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(getattr(logging, log_level))
        formatter = logging.Formatter('%(asctime)s - %(message)s')
        handler.setFormatter(formatter)
        root.addHandler(handler)

        # Build system
        self.system = BaseSystem.from_name(self.config['system'])(self.config)

    def run(self):
        getattr(ROMKit, self.action)(self)

    # Lists machines filtered for this system
    def list(self):
        for machine in self.system.list():
            print(json.dumps(machine.dump()))

    # Installs the list of filtered machines onto the local filesystem
    def install(self):
        self.system.install()


def main():
    parser = ArgumentParser()
    parser.add_argument(dest='action', help='Action to perform', choices=['list', 'install', 'clean'])
    parser.add_argument(dest='config', help='JSON file containing the configuration')
    parser.add_argument('--log-level', dest='log_level', help='Log level', default='INFO', choices=['DEBUG', 'INFO', 'WARN', 'ERROR'])
    args = parser.parse_args()
    ROMKit(args.action, args.config, args.log_level).run()


if __name__ == '__main__':
    main()
