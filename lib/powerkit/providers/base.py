import logging
from typing import Callable

def all_subclasses(cls):
    return set(cls.__subclasses__()).union(
        [s for c in cls.__subclasses__() for s in all_subclasses(c)])

class BaseProvider():
    name = 'base'

    def __init__(self, config: dict) -> None:
        self.config = config
        self.handlers = {}

    # Looks up the provider from the given name
    @classmethod
    def from_config(cls, config: dict) -> None:
        name = config['provider']['id']

        for subcls in all_subclasses(cls):
            if subcls.name == name:
                logging.info(f'Using {name} provider')
                return subcls(config)

        logging.info('Using default provider')

        return cls(config)

    # Starts listening for button presses
    def run(self) -> None:
        pass

    # Briefly blink an LED, if one exists
    def blink(self) -> None:
        pass

    # Add the given event handler
    def on(self, event: str, callback: Callable) -> None:
        self.handlers[event] = callback

    # Triggers any handler registered with the given event
    def trigger(self, event: str) -> None:
        if event in self.handlers:
            self.handlers[event]()

    # Trigger the shutdown event
    def shutdown(self) -> None:
        self.trigger('shutdown')

    # Trigger the reset event
    def reset(self) -> None:
        self.trigger('reset')
