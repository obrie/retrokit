# Represents a ROMSet build structure
class BaseBuild:
  def from_name(name):
      for cls in BaseBuild.__subclasses__():
          if cls.name == name:
              return cls

      raise Exception(f'Invalid build: {name}')

  def source_url_for(self, machine):
      pass

  def source_filepath_for(self, machine):
      pass