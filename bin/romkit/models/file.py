from __future__ import annotations

from typing import Optional

# Represents a file resource
class File:
    # Status when a ROM isn't actually included in the Machine
    STATUS_NO_DUMP = 'nodump'

    __slots__ = ['name', 'crc', 'id']

    def __init__(self, name: str, crc: str, file_identifier: Optional[str] = None) -> None:
        self.name = name
        self.crc = crc.lower()
        
        if file_identifier == 'name':
            self.id = self.name
        else:
            self.id = self.crc

    # Whether this file is installable
    @staticmethod
    def is_installable(xml: lxml.etree.ElementBase) -> bool:
        return xml.get('status') != File.STATUS_NO_DUMP

    # Builds a file from an XML element
    @classmethod
    def from_xml(cls, xml: lxml.etree.ElementBase, **kwargs) -> File:
        return cls(
            xml.get('name'),
            xml.get('crc'),
            **kwargs,
        )

    # Equality based on Unique ID
    def __eq__(self, other) -> bool:
        if isinstance(other, File):
            return self.id == other.id
        return False

    # Hash based on Unique ID
    def __hash__(self) -> str:
        return hash(self.id)
