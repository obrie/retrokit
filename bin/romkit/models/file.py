# Represents a file resource
class File:
    # Status when a ROM isn't actually included in the Machine
    STATUS_NO_DUMP = 'nodump'

    __slots__ = ['name', 'crc', 'id']

    def __init__(self, name, crc, file_identifier=None):
        self.name = name
        self.crc = crc.lower()
        
        if file_identifier == 'name':
            self.id = self.name
        else:
            self.id = self.crc

    # Whether this file is installable
    @staticmethod
    def is_installable(xml):
        return xml.get('status') != File.STATUS_NO_DUMP

    # Builds a file from an XML element
    @staticmethod
    def from_xml(xml, file_identifier=None):
        return File(
            xml.get('name'),
            xml.get('crc'),
            file_identifier=file_identifier,
        )

    # Equality based on Unique ID
    def __eq__(self, other):
        if isinstance(other, File):
            return self.id == other.id
        return False

    # Hash based on Unique ID
    def __hash__(self):
        return hash(self.id)
