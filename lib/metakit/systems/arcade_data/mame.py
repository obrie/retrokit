from __future__ import annotations

import lxml.etree
import os

from romkit.resources.resource import ResourceTemplate
from metakit.systems.arcade_data.base import ExternalData

# MAME dats managed by progretto-SNAPS (includes clones)
class MAMEData(ExternalData):
    allow_clone_overrides = True
    resource_template = ResourceTemplate.from_json({
        'source': 'https://archive.org/download/mame-support/Support/Support-Files/MAME_Dats_{version}.zip/XML%2Fmame{version}.xml',
        'target': f'{os.environ["RETROKIT_HOME"]}/tmp/arcade/mame.xml',
    })
    version_pattern = r'MAME_Dats_([0-9]+).zip'

    def update(self, database: Database) -> None:
        self._load(database)

        # Load each attribute that can be looked up from the full mame.xml file.
        # we define this here rather than doing it as part of the romset dat
        # parsing because it allows for consistent metadata filtering regardless of
        # which romset the machine is being filtered in.
        self.update_attribute(database, 'screen')
        self.update_attribute(database, 'controls')
        self.update_attribute(database, 'mechanical')

    def _load(self, database: Database) -> None:
        romkit = database.romkit

        self.screens = {}
        self.controls = {}
        self.mechanical = {}

        # Load data from MAME
        resource = self.download()
        doc = lxml.etree.iterparse(str(resource.target_path.path), tag=('machine'))
        for event, machine in doc:
            name = machine.get('name')
            if name in romkit.names:
                # Orientation
                orientation = None
                display_tag = machine.find('display')
                if display_tag is not None:
                    rotate = display_tag.get('rotate')
                    if rotate == '0' or rotate == '180':
                        orientation = 'horizontal'
                    else:
                        orientation = 'vertical'

                if orientation:
                    self.screens[name] = {'orientation': orientation}

                # Controls
                controls = set()
                input_tag = machine.find('input')
                control_tags = input_tag.findall('control')
                if control_tags is not None:
                    for control_tag in control_tags:
                        control_type = control_tag.get('type')
                        if control_type == 'lightgun':
                            control_type = 'pointer'
                        controls.add(control_type)

                if controls:
                    self.controls[name] = list(sorted(list(controls)))

                # Mechanical
                if machine.get('ismechanical') == 'yes':
                    self.mechanical[name] = True

        # Load from FBNeo
        fbneo_romset = next(romset for romset in romkit.romsets if romset.name == 'fbneo')
        doc = lxml.etree.iterparse(str(fbneo_romset.dat.target_path.path), tag=('game'))
        for event, game in doc:
            name = game.get('name')
            if name in romkit.names:
                # Orientation
                video_tag = game.find('video')
                if video_tag is not None:
                    orientation = video_tag.get('orientation')
                    if orientation:
                        self.screens[name] = {'orientation': orientation}

    # Since this class handles multiple attributes, we have to reimplement
    # the lookup to actually pay attention to the attribute being requested.
    def get_value(self, name, attribute, database):
        if attribute == 'screen':
            return self.screens.get(name)
        elif attribute == 'controls':
            return self.controls.get(name)
        elif attribute == 'mechanical':
            return self.mechanical.get(name)
        else:
            raise NotImplementedError
