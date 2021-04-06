from romkit.build import BaseBuild

# Every machine has its own file
class SplitBuild(BaseBuild):
    name = 'split'

    def source_url_for(self, machine):
        return machine.build_url('rom', filename=machine.name)

    def source_filepath_for(self, machine):
        return machine.filepath
