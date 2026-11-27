"""Bind the help menu and its compiler-generated switch table."""
from bind_melee_group import bind_switch_group

BASE, SIZE, PREFIX = 0x3a8ac, 116, 16
DATA = {'_help_entries': 0x17456c, '_help_selection': 0x17458c,
        '_help_menu_title': 0x1156}
CALLS = {'run_menu_loop_': 0x3963b, 'run_first_help_pages_': 0x3a7b2,
         'run_second_help_pages_': 0x3a800, 'run_help_submenu_': 0x3a871}


def bind(blob):
    return bind_switch_group(blob, base=BASE, loaded=False, symbol='run_help_menu_',
                             prefix_size=PREFIX, data_targets=DATA, call_targets=CALLS)
