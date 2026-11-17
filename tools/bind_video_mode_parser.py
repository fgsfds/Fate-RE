"""Bind the Watcom video mode parser and its generated mode switch table."""
from bind_melee_group import bind_switch_group

BASE, SIZE, PREFIX = 0x36bfe, 243, 24
DATA = {
    '_video_mode_names': 0x12d30,
    '_chain_mode_widths': 0x12d48,
    '_chain_mode_heights': 0x12d4e,
    '_vesa_mode_widths': 0x12d60,
    '_vesa_mode_heights': 0x12d64,
}
CALLS = {'stricmp_': 0x62d95}


def bind(blob):
    return bind_switch_group(blob, base=BASE, loaded=False, symbol='parse_video_mode_',
                             prefix_size=PREFIX, data_targets=DATA, call_targets=CALLS)
