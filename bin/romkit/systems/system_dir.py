from pathlib import Path

class SystemDir:
    def __init__(self, path, file_templates):
        self.path = path
        self.file_templates = file_templates

    # Clears all existing symlinks in the directory
    def reset(self):
        path = Path(self.path)

        if path.is_dir():
            for filename in path.iterdir():
                filepath = path.joinpath(filename)
                if filepath.is_symlink():
                    filepath.unlink()

    # Symlinks a resource with the given source path to this directory
    def symlink(self, resource_name, source_path, **context):
        file_template = self.file_templates[resource_name]

        source_match = file_template.get('source')
        target_path = file_template['target'].format(dir=self.path, **context)

        if not source_match:
            # Target is being directly linked: create parent dir and symlink
            Path(target_path).parent.mkdir(parents=True, exist_ok=True)
            Path(target_path).symlink_to(source_path)
        elif source_match == '..':
            # Target is a directory: create grandparent and symlink parent
            source_dirname = Path(source_path).parent
            
            Path(target_path).parent.mkdir(parents=True, exist_ok=True)
            Path(target_path).symlink_to(source_dirname, target_is_directory=True)
        elif source_match == '*':
            # Ensure target directory exists
            Path(target_path).mkdir(parents=True, exist_ok=True)

            # Symlink all files within directory
            for source_filepath in Path(source_path).iterdir():
                Path(target_path).joinpath(source_filepath.name).symlink_to(source_filepath)
        else:
            raise ArgumentError
