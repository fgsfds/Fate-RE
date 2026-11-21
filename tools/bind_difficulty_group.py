"""Bind the difficulty menu and its compiler-generated switch table."""
from bind_melee_group import bind_switch_group

BASE, SIZE, PREFIX = 0x3ae6c, 152, 16
DATA = {'_difficulty_entries': 0x1745d0, '_difficulty_selection': 0x1745e0,
        '_difficulty_divisor': 0x7deec, '_difficulty_menu_title': 0x128b}
CALLS = {'run_menu_loop_': 0x3963b}


def bind(blob):
    return bind_switch_group(blob, base=BASE, loaded=False, symbol='run_difficulty_menu_',
                             prefix_size=PREFIX, data_targets=DATA, call_targets=CALLS)
