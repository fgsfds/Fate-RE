"""Shared build/fixture registrations; expected ABI and placement remain independent."""
from dataclasses import dataclass
from importlib import import_module
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BEHAVIOR_FIXTURES = {
    'actmove': 'check_actor_movement',
    'tilecopy': 'check_copytilepiece_candidate',
    'mousebtn': 'check_mouse_button_menu',
    'sectport': 'check_sector_portal',
    'bfront': 'check_bunchfront',
    'viewang': 'check_view_angle_table',
}


@dataclass(frozen=True)
class Fixture:
    script: str
    arguments: tuple
    objects: frozenset

    def command(self, executable, build):
        values = dict(exe=str(executable), build=str(build), asm=str(build / 'asm'))
        return [str(ROOT / 'tools' / (self.script + '.py')),
                *(arg.format(**values) for arg in self.arguments)]


def fixtures(objects=None):
    rows = []
    path = ROOT / 'tools/data/restoration-fixtures.txt'
    for line in path.read_text(encoding='ascii').splitlines():
        line = line.partition('#')[0].strip()
        if not line:
            continue
        command, separator, dependencies = line.partition('|')
        script, *arguments = command.split()
        names = frozenset(dependencies.split())
        if not separator or not names or not (ROOT / 'tools' / (script + '.py')).is_file():
            raise ValueError('Invalid fixture registration: ' + line)
        if objects is None or names.intersection(objects):
            rows.append(Fixture(script, tuple(arguments), names))
    if len({row.script for row in rows}) != len(rows):
        raise ValueError('Duplicate fixture script')
    return rows


def switch_groups():
    """One binder registration shared by validation, linking, and targeted probes."""
    table = 'compiler-generated jump table'
    specs = (
        ('melee', 'bind_melee_group', [(0, 32, None, table, 8),
                                     (32, None, 'melee_trigger_', None, 17)], (16, 9, 11)),
        ('crushini', 'bind_crush_init_group', [(0, 60, None, table, 15),
                                             (60, None, 'init_crush_bank_', None, 19)], (18, 16, 4)),
        ('diffmenu', 'bind_difficulty_group', [(0, 16, None, table, 4),
                                              (16, None, 'run_difficulty_menu_', None, 8)], (7, 5, 1)),
        ('helpmenu', 'bind_help_menu_group', [(0, 16, None, table, 4),
                                             (16, None, 'run_help_menu_', None, 5)], (4, 5, 4)),
        ('setmenu', 'bind_settings_menu', None, (16, 13, 9)),
        ('audmenu', 'bind_audio_menu', [(0, 20, None, table, 5),
                                       (20, None, 'run_audio_menu_', None, 17)], (16, 6, 9)),
        ('initnet', 'bind_network_init', [(0, 24, None, table, 6),
                                         (24, None, 'initialize_network_', None, 19)], (18, 7, 6)),
        ('vidparse', 'bind_video_mode_parser', [(0, 24, None, table, 6),
                                               (24, None, 'parse_video_mode_', None, 8)], (7, 7, 1)),
        ('drawact', 'bind_drawing_action', [(0, 16, None, table, 4),
                                           (16, None, 'get_drawing_action_', None, 2)], (1, 5, 0)),
        ('brdsp', 'bind_level_script_dispatch', [(0, 100, None, table, 25),
                                                (100, None, 'update_board_actors_and_script_', None, 9)],
         (8, 26, 26)),
    )
    rows = {}
    for name, module_name, parts, counts in specs:
        module = import_module(module_name)
        if parts is None:
            parts = [(0, 20, None, table, 5),
                     (20, module.SETTINGS_END, 'run_settings_menu_', None, 6),
                     (module.SETTINGS_END, module.OPTIONS_TABLE, None, 'compiler alignment', 0),
                     (module.OPTIONS_TABLE, module.OPTIONS_ENTRY, None, table, 6),
                     (module.OPTIONS_ENTRY, module.SIZE, 'run_options_menu_', None, 12)]
        # Function ends are defined by the binder, not duplicated here.
        parts[-1] = (parts[-1][0], module.SIZE, *parts[-1][2:])
        rows[name + '.obj'] = (module.bind, module.BASE, module.SIZE, parts, counts)
    return rows
