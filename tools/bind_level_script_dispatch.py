"""Bind the native Watcom board script dispatcher and its CODE switch table."""
from bind_melee_group import bind_switch_group
from verify_c_leaf import DATA_OFFSETS

BASE, SIZE, PREFIX = 0x1e74c, 462, 100
DATA = {symbol: DATA_OFFSETS[symbol] for symbol in
        ('_current_level', '_player_sector', '_player_z', '_player_y', '_player_x')}
DATA.update({'_dispatch_actor_enabled': 0x7ecb6, '_dispatch_actor_board': 0x7eac1})

BOARD_SCRIPTS = (
    0x1dae8, 0x1dae9, 0x1daea, 0x1df2e, 0x1e41d, 0x1e5d0, 0x1e5d1,
    *range(0x1e73a, 0x1e74c),
)
CALLS = {f'update_board_{board}_script_': address
         for board, address in enumerate(BOARD_SCRIPTS, start=1)}
CALLS['update_actor_'] = 0x14610


def bind(blob, loaded=False):
    return bind_switch_group(blob, base=BASE, loaded=loaded, symbol='update_board_actors_and_script_',
                             prefix_size=PREFIX, data_targets=DATA, call_targets=CALLS)
