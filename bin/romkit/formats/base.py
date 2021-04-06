class BaseFormat:
    name = None
    
    # Looks up the format from the given name
    @staticmethod
    def from_name(name):
        for cls in BaseFormat.__subclasses__():
            if cls.name == name:
                return cls

        raise Exception(f'Invalid format: {name}')

    def find_local_roms(self, machine):
        pass

    def merge(self, source, target, roms):
        pass

    def finalize(self, target):
        pass
