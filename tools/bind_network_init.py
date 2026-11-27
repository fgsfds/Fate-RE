"""Bind the Watcom network initializer and its generated baud switch table."""
from bind_melee_group import bind_switch_group

BASE, SIZE, PREFIX = 0x4152a, 293, 24
DATA = {
    '_net_settings': 0x13cdf,
    '_transport': 0x13cde,
    '_connecthead': 0x19028a,
    '_connectpoint2': 0x18fd78,
    '_connectnum': 0x186d48,
    '_network_id_byte': 0x18fe0c,
    '_serial_transport': 0x18fe10,
    '_serial_baud': 0x18fe28,
    '_numplayers': 0x13ce0,
    '_ipx_missing_error': 0x18cc,
    '_ipx_socket_error': 0x18e2,
}
CALLS = {
    'initcrc_': 0x42f1a,
    'initialize_serial_network_': 0x41a56,
    'initialize_ipx_': 0x41694,
    'printf_': 0x40bb4,
    'exit_': 0x60353,
}


def bind(blob):
    return bind_switch_group(blob, base=BASE, loaded=False, symbol='initialize_network_',
                             prefix_size=PREFIX, data_targets=DATA, call_targets=CALLS)
