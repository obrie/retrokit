import asyncio
import evdev
import xml

from manualkit.sdl_codes import sdl1_map

# Listens for hotkeys that trigger changes to manualkit
class InputManager():
    def __init__(self,
        keyboard_toggle: str = 'm',
        joystick_toggle: str = 'up',
    ) -> None:
        self.keyboard_toggle = keyboard_toggle
        self.joystick_toggle = joystick_toggle

        self.mappings = {}
        import xml.etree.ElementTree as ET
        tree = ET.parse('country_data.xml')
        lxml.etree.iterparse(str(self.metadata_filepath), tag=('file'))
        pass

    def run(self):
        devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
        for device in devices:
            asyncio.ensure_future(print_events(device))

        loop = asyncio.get_event_loop()
        loop.run_forever()        

    async def print_events(device):
        async for event in device.async_read_loop():
            print(device.path, evdev.categorize(event), sep=': ')

    # Generates an SDL ID from evdev data in order to match the format used by
    # emulationstation / retroarch and other emulators
    def sdl_id(self, device: evdev.InputDevice) -> str:
        info = device.info

        return '%02x%02x0000%02x%02x0000%02x%02x0000%02x%02x0000' % (
            info.bustype & 0xFF,
            info.bustype >> 8,
            info.vendor & 0xFF,
            info.vendor >> 8,
            info.product & 0xFF,
            info.product >> 8,
            info.version & 0xFF,
            info.version >> 8
        )
