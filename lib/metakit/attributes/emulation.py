from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class EmulationAttribute(BaseAttribute):
    name = 'emulation'

    KEYS = ['emulator', 'rating']

    def load(self) -> None:
        self.emulators = set()

        if 'emulators' in self.config:
            for emulator_name, emulator_config in self.config['emulators'].items():
                if 'names' in emulator_config:
                    self.emulators.update(emulator_config['names'])
                else:
                    self.emulators.add(emulator_name)

                if 'aliases' in emulator_config:
                    self.emulators.update(emulator_config['aliases'])

    def validate(self, value: dict) -> List[str]:
        errors = []

        # Emulator must be defined in the settings
        if 'emulator' in value and value['emulator'] not in self.emulators:
            errors.append(f"emulator not valid: {value['emulator']}")

        if 'rating' in value and (value['rating'] < 0 or value['rating'] > 5):
            errors.append(f"emulator rating must be between 0 and 5: {value['rating']}")

        invalid_keys = value.keys() - self.KEYS
        if invalid_keys:
            errors.append(f"emulator config not valid: {', '.join(invalid_keys)}")

        return errors

    def format(self, value: dict) -> List[str]:
        return self._sort_dict(value, self.KEYS)
