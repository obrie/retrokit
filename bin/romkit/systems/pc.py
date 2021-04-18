from __future__ import annotations

from romkit.systems import BaseSystem

import zipfile
from pathlib import Path

class PCSystem(BaseSystem):
    name = 'pc'

    APP_ROOT = Path(__file__).parent.resolve().joinpath('../../..').resolve()
    CONFIG_ARCHIVE = f'{APP_ROOT}/cache/exodos/dosbox-cfg.zip'

    def install_machine(self, machine: Machine) -> bool:
        success = super().install_machine(machine)

        if success:
            # Install configuration files
            with zipfile.ZipFile(self.CONFIG_ARCHIVE, 'r') as conf_zip:
                exodos_name = machine.sourcefile
                machine_dir = str(machine.resource.target_path.path)

                conf_zip.extract(f'{exodos_name}/dosbox.conf', machine_dir)

                if f'{exodos_name}/mapper.map' in conf_zip.namelist():
                    conf_zip.extract(f'{exodos_name}/mapper.map', machine_dir)

        return success

    def enable_machine(self, machine: Machine, system_dir: SystemDir) -> None:
        exodos_name = machine.sourcefile
        exodos_dir = machine.resource.target_path.path.joinpath(exodos_name)
        config_file = exodos_dir.joinpath('dosbox.conf')

        system_dir.symlink('machine', exodos_dir, machine_sourcefile=machine.sourcefile)
        system_dir.symlink('conf', config_file, machine=machine.name)
