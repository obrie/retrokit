import logging

# Represents an audio file used by a machine
class Sample:
    def __init__(self, machine, name):
        self.machine = machine
        self.name = name

    # Source url to get the sample
    @property
    def url(self):
        return self.machine.build_url('sample', filename=self.name)

    # Target destination for installing this sample
    @property
    def filepath(self):
        return self.machine.build_filepath('sample', filename=self.name)

    @property
    def romset(self):
        return self.machine.romset

    # Downloads and installs the sample
    def install(self):
        logging.info(f'[{self.machine.name}] Installing sample {self.name}')
        self.romset.download(self.url, self.filepath)
