"""Bind both settings menus and their compiler-generated switch tables."""
from bind_melee_group import bind_switch_groups

BASE, SIZE = 0x39758, 312
SETTINGS_END, OPTIONS_TABLE, OPTIONS_ENTRY = 131, 132, 156
TABLES = ((0, 20, SETTINGS_END, 'run_settings_menu_'),
          (OPTIONS_TABLE, 24, SIZE, 'run_options_menu_'))
DATA = {'_settings_entries': 0x1740d0, '_settings_selection': 0x1740cc, '_settings_menu_title': 0xc77,
        '_gore_mode': 0x770f8, '_options_entries': 0x174010, '_options_selection': 0x1740e8,
        '_options_menu_title': 0xcf7, '_gore_on_caption': 0xc4f, '_gore_off_caption': 0xd04}
CALLS = {'run_menu_loop_': 0x3963b, 'run_keyboard_settings_': 0x3a65c,
         'run_mouse_settings_': 0x3ade2, 'save_game_configuration_': 0x38291,
         'run_audio_menu_': 0x3af40, 'run_control_limits_menu_': 0x3b05b}


def bind(blob):
    return bind_switch_groups(blob, base=BASE, loaded=False, tables=TABLES,
                              data_targets=DATA, call_targets=CALLS)
