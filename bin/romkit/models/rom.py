import subprocess

# Represents a file within a machine
class ROM:
    # Status when a ROM isn't actually included in the Machine
    STATUS_NO_DUMP = 'nodump'

    __slots__ = ['machine', 'name', 'crc', 'external', 'source_name']

    def __init__(self, machine, name, crc, source_name = None):
        self.machine = machine
        self.name = name
        self.crc = crc.lower()

        if source_name:
            self.external = True
            self.source_name = source_name
        else:
            self.external = False
            self.source_name = name

    # Whether this ROM is installable into the machine
    @staticmethod
    def is_installable(xml):
        return xml.get('status') != ROM.STATUS_NO_DUMP

    # Builds a ROM from the given DAT XML
    @staticmethod
    def from_xml(machine, xml):
        return ROM(
          machine,
          xml.get('name'),
          xml.get('crc'),
          xml.get('merge'),
        )

    # Removes this ROM from the current machine
    def remove(self):
        self.machine.format.remove(self.machine, self)

    # Equality based on CRC
    def __eq__(self, other):
        if isinstance(other, ROM):
            return self.crc == other.crc
        return False

    # Hash based on CRC
    def __hash__(self):
        return hash(self.crc)
