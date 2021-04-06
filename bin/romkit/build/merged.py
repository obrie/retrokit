from romkit.build import BaseBuild

# Clones are packaged in the same file as the parent
class MergedBuild(BaseBuild):
    name = 'merged'

    def source_url_for(self, machine):
        return machine.build_url('rom', filename=(machine.parent_name or machine.name))

    def source_filepath_for(self, machine):
        return machine.build_filepath('rom', filename=f'{machine.parent_name or machine.name}.merged')