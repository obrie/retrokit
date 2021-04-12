import logging

# Represents an audio file used by a machine
class Sample:
    def __init__(self, machine, name):
        self.machine = machine
        self.name = name

    @property
    def romset(self):
        return self.machine.romset

    # Target destination for installing this sample
    @property
    def resource(self):
        return self.romset.resource('sample', sample=self.name)

    # Downloads and installs the sample
    def install(self):
        logging.info(f'[{self.machine.name}] Installing sample {self.name}')
        self.resource.install()
