"""Bind the drawing-action getter and its compiler-generated switch table."""
from bind_melee_group import bind_switch_group
from verify_c_leaf import DATA_OFFSETS

BASE, SIZE, PREFIX = 0x71914, 60, 16


def bind(blob):
    return bind_switch_group(blob, base=BASE, loaded=False, symbol='get_drawing_action_',
                             prefix_size=PREFIX,
                             data_targets={'_drawing_action': DATA_OFFSETS['_drawing_action']},
                             call_targets={})
