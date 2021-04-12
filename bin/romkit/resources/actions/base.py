class BaseAction:
    name = None

    def __init__(self, config = {}):
      self.config = config

    # Builds an action from the given JSON data
    @staticmethod
    def from_json(json):
        json = json.copy()
        action = json.pop('action')
        return BaseAction.from_name(action)(json)

    # Looks up the action from the given name
    @staticmethod
    def from_name(name):
        for cls in BaseAction.__subclasses__():
            if cls.name == name:
                return cls

        raise Exception(f'Invalid action: {name}')

    def run(self, source, target, **kwargs):
        raise NotImplementedError()
