from __future__ import annotations

# Provides a base class for machine attributes
class BaseAttribute:
    metadata_name: Optional[str] = None
    rule_name: Optional[str] = None
    apply_to_overrides: bool = False
    empty: Set = set()

    def __init__(self, default: Any = None) -> None:
        self.default = default

        # Enable default configuration
        self.configure()

    # Normalizes values so that lowercase/uppercase differences are
    # ignored during the matching process
    @classmethod
    def normalize(cls, value):
        if cls.data_type == str:
            if isinstance(value, list):
                return [item and item.lower() for item in value]
            elif isinstance(value, set):
                return {item and item.lower() for item in value}
            else:
                return value and value.lower()
        else:
            return value

    # Reconfigures the behavior of this attribute
    def configure(self, *args, **kwargs) -> None:
        pass

    @property
    def primary_name(self) -> str:
        return self.metadata_name or self.rule_name

    @property
    def data_type(self) -> Any:
        raise NotImplementedError

    # Updates the machine with the given value for this type of metadata
    def set(self, machine: Machine, value) -> None:
        raise NotImplementedError

    # Looks up the list of values associated with the machine
    def get(self, machine: Machine) -> set:
        raise NotImplementedError
