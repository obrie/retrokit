from enum import Enum
from typing import Callable

import devicekit.keycodes

# Represents the type of input that we're listening to
class InputType(Enum):
    KEYBOARD = 'keyboard', devicekit.keycodes.retroarch_keyboard
    JOYSTICK = 'joystick', devicekit.keycodes.retroarch_joystick

    def __init__(self, type_name: str, retroarch_codes: Callable) -> None:
        self.type_name = type_name
        self.retroarch_codes = retroarch_codes
