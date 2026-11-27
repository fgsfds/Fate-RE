"""Bind the audio menu and its compiler-generated switch table."""
from bind_melee_group import bind_switch_group
from verify_c_leaf import FUNCTION_ADDRESSES

BASE, SIZE, PREFIX = 0x3af2c, 264, 20
DATA = {'_audio_entries': 0x1745e8, '_audio_menu_selection': 0x1745fc, '_audio_menu_title': 0x12d6}
CALLS = {name: FUNCTION_ADDRESSES[name] for name in (
    'run_menu_loop_', 'get_audio_flag_a_', 'get_audio_flag_b_',
    'set_audio_flag_a_', 'set_audio_flag_b_', 'get_audio_level_a_', 'get_audio_level_b_',
    'set_audio_level_a_', 'set_audio_level_b_',
)}


def bind(blob):
    return bind_switch_group(blob, base=BASE, loaded=False, symbol='run_audio_menu_',
                             prefix_size=PREFIX, data_targets=DATA, call_targets=CALLS)
