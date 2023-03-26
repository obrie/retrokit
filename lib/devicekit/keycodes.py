from __future__ import annotations

from evdev.ecodes import *

# Retroarch keyboard input name => evdev ecode
def retroarch_keyboard(device: evdev.Inputdevice) -> dict:
    return {
        'a': (KEY_A, 1),
        'add': (KEY_KPPLUS, 1),
        'alt': (KEY_LEFTALT, 1),
        'b': (KEY_B, 1),
        'backquote': (KEY_GRAVE, 1),
        'backslash': (KEY_BACKSLASH, 1),
        'backspace': (KEY_BACKSPACE, 1),
        'c': (KEY_C, 1),
        'capslock': (KEY_CAPSLOCK, 1),
        'comma': (KEY_COMMA, 1),
        'ctrl': (KEY_LEFTCTRL, 1),
        'd': (KEY_D, 1),
        'del': (KEY_DELETE, 1),
        'divide': (KEY_KPSLASH, 1),
        'down': (KEY_DOWN, 1),
        'e': (KEY_E, 1),
        'end': (KEY_END, 1),
        'enter': (KEY_ENTER, 1),
        'equals': (KEY_EQUAL, 1),
        'escape': (KEY_ESC, 1),
        'f': (KEY_F, 1),
        'f1': (KEY_F1, 1),
        'f10': (KEY_F10, 1),
        'f11': (KEY_F11, 1),
        'f12': (KEY_F12, 1),
        'f2': (KEY_F2, 1),
        'f3': (KEY_F3, 1),
        'f4': (KEY_F4, 1),
        'f5': (KEY_F5, 1),
        'f6': (KEY_F6, 1),
        'f7': (KEY_F7, 1),
        'f8': (KEY_F8, 1),
        'f9': (KEY_F9, 1),
        'g': (KEY_G, 1),
        'h': (KEY_H, 1),
        'home': (KEY_HOME, 1),
        'i': (KEY_I, 1),
        'insert': (KEY_INSERT, 1),
        'j': (KEY_J, 1),
        'k': (KEY_K, 1),
        'keypad0': (KEY_KP0, 1),
        'keypad1': (KEY_KP1, 1),
        'keypad2': (KEY_KP2, 1),
        'keypad3': (KEY_KP3, 1),
        'keypad4': (KEY_KP4, 1),
        'keypad5': (KEY_KP5, 1),
        'keypad6': (KEY_KP6, 1),
        'keypad7': (KEY_KP7, 1),
        'keypad8': (KEY_KP8, 1),
        'keypad9': (KEY_KP9, 1),
        'kp_enter': (KEY_KPENTER, 1),
        'kp_equals': (KEY_KPEQUAL, 1),
        'kp_minus': (KEY_KPMINUS, 1),
        'kp_period': (KEY_KPDOT, 1),
        'kp_plus': (KEY_KPPLUS, 1),
        'l': (KEY_L, 1),
        'left': (KEY_LEFT, 1),
        'leftbracket': (KEY_LEFTBRACE, 1),
        'm': (KEY_M, 1),
        'minus': (KEY_MINUS, 1),
        'multiply': (KEY_KPASTERISK, 1),
        'n': (KEY_N, 1),
        'num0': (KEY_0, 1),
        'num1': (KEY_1, 1),
        'num2': (KEY_2, 1),
        'num3': (KEY_3, 1),
        'num4': (KEY_4, 1),
        'num5': (KEY_5, 1),
        'num6': (KEY_6, 1),
        'num7': (KEY_7, 1),
        'num8': (KEY_8, 1),
        'num9': (KEY_9, 1),
        'numlock': (KEY_NUMLOCK, 1),
        'o': (KEY_O, 1),
        'p': (KEY_P, 1),
        'pagedown': (KEY_PAGEDOWN, 1),
        'pageup': (KEY_PAGEUP, 1),
        'pause': (KEY_PAUSE, 1),
        'period': (KEY_DOT, 1),
        'print_screen': (KEY_PRINT, 1),
        'q': (KEY_Q, 1),
        'quote': (KEY_APOSTROPHE, 1),
        'r': (KEY_R, 1),
        'ralt': (KEY_RIGHTALT, 1),
        'rctrl': (KEY_RIGHTCTRL, 1),
        'right': (KEY_RIGHT, 1),
        'rightbracket': (KEY_RIGHTBRACE, 1),
        'rshift': (KEY_RIGHTSHIFT, 1),
        's': (KEY_S, 1),
        'scroll_lock': (KEY_SCROLLLOCK, 1),
        'semicolon': (KEY_SEMICOLON, 1),
        'shift': (KEY_LEFTSHIFT, 1),
        'slash': (KEY_SLASH, 1),
        'space': (KEY_SPACE, 1),
        'subtract': (KEY_MINUS, 1),
        't': (KEY_T, 1),
        'tab': (KEY_TAB, 1),
        'u': (KEY_U, 1),
        'up': (KEY_UP, 1),
        'v': (KEY_V, 1),
        'w': (KEY_W, 1),
        'x': (KEY_X, 1),
        'y': (KEY_Y, 1),
        'z': (KEY_Z, 1),
    }

# Retroarch joystick input name => evdev ecode
def retroarch_joystick(device: evdev.InputDevice) -> dict:
    retroarch_codes = {}

    # Evaluate device capabilities
    capabilities = device.capabilities()
    for index, (code, abs_info) in enumerate(capabilities.get(EV_ABS, [])):
        if code == ABS_HAT0X:
            # D-Pad X
            retroarch_codes['h0left'] = (code, -1)
            retroarch_codes['h0right'] = (code, 1)
        elif code == ABS_HAT0Y:
            # D-Pad Y
            retroarch_codes['h0down'] = (code, -1)
            retroarch_codes['h0up'] = (code, 1)
        else:
            # Analog controls
            retroarch_codes[f'-{index}'] = (code, -1)
            retroarch_codes[f'+{index}'] = (code, 1)

    # Translate retroarch index-based layout to evdev code-based layout
    if EV_KEY in device.capabilities():
        joystick_ecodes = device.capabilities()[EV_KEY]
        for index, ecode in enumerate(joystick_ecodes):
            retroarch_codes[str(index)] = (ecode, 1)

    return retroarch_codes
