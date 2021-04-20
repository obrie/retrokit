from __future__ import annotations

from romkit.systems import BaseSystem

import subprocess
import zipfile
from pathlib import Path

class PCSystem(BaseSystem):
    name = 'pc'

    APP_ROOT = Path(__file__).parent.resolve().joinpath('../../..').resolve()
    CONFIG_ARCHIVE = f'{APP_ROOT}/cache/exodos/dosbox-cfg.zip'

    def install_machine(self, machine: Machine) -> bool:
        success = super().install_machine(machine)

        if success:
            self.install_config(machine)
            self.fix_windows_paths(machine)

        return success

    # Installs the dosbox configuration file required to run the machine.
    # Note that this will install the default configuration provided by eXoDOS.
    def install_config(self, machine: Machine) -> None:
        with zipfile.ZipFile(self.CONFIG_ARCHIVE, 'r') as conf_zip:
            exodos_name = machine.sourcefile
            machine_dir = str(machine.resource.target_path.path)

            conf_file = conf_zip.getinfo(f'{exodos_name}/dosbox.conf')
            conf_file.filename = 'dosbox.conf'
            conf_zip.extract(conf_file, machine_dir)

            if f'{exodos_name}/mapper.map' in conf_zip.namelist():
                mapper_file = conf_zip.getinfo(f'{exodos_name}/mapper.map')
                mapper_file.filename = 'mapper.map'
                conf_zip.extract(zip_info, mapper_file)

            self.update_config_defaults(machine)
            self.replace_opengl_renderer(machine)

    # Updates the dosbox configuration with overall and game-specific overrides provided
    def update_config_defaults(self, machine: Machine) -> None:
        machine_dir = machine.resource.target_path.path
        conf_file = machine_dir.joinpath('dosbox.conf')

        global_overrides_path = self.config['roms']['files']['conf'].get('global_overrides')

        # Override with RPi-specific configurations
        if global_overrides_path:
            with open(global_overrides_path) as f:
                subprocess.run(['crudini', '--merge', conf_file], stdin=f, check=True)

        # Override with Machine-specific configurations
        overrides_template = self.config['roms']['files']['conf'].get('overrides')
        if overrides_template:
            overrides_path = Path(overrides_template.format(machine=machine.name))
            if overrides_path.exists():
                with overrides_path.open() as f:
                    subprocess.run(['crudini', '--merge', conf_file], stdin=f, check=True)

    # OpenGL is unreasonably slow on Raspberry Pi 4 + latest kernel/Raspbian.
    # This replaces any opengl output configurations with surface, which is
    # known to perform much better.
    def replace_opengl_renderer(self, machine: Machine) -> None:
        renderer = subprocess.run(['crudini', '--get', conf_file, 'sdl', 'output'], check=True, capture_output=True).stdout
        if renderer and renderer.lower().startswith('opengl'):
            renderer = subprocess.run(['crudini', '--set', conf_file, 'sdl', 'output', 'surface'], check=True, capture_output=True).stdout

    # Find paths that contain windows-style slashes and replace them with linux-style
    def fix_windows_paths(self, machine: Machine) -> None:
        machine_dir = machine.resource.target_path.path
        files_to_fix = subprocess.run(['grep', '-lIR', ".\\eXoDOS", machine.resource.target_path.path], check=True, capture_output=True).stdout

        for filepath in files_to_fix.splitlines():
            subprocess.run(['sed', '-i', '/.\\\\eXoDOS/{s/\\\\/\\//g;}', filepath], check=True)

    # Symlinks the configuration file so that it's visible in the frontend
    def enable_machine(self, machine: Machine, system_dir: SystemDir) -> None:
        config_file = machine.resource.target_path.path.joinpath('dosbox.conf')
        system_dir.symlink('conf', config_file, machine=machine.name)
