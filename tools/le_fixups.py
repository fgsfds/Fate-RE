"""Read the pinned FATE LE image's internal 32-bit pointer relocations.

This is a target-specific reader, not a general DOS executable loader.
"""
import hashlib
import struct
from bisect import bisect_left
from collections.abc import Mapping
from compare_exe import TARGET_SHA256


class RelocationIndex(Mapping):
    """Immutable mapping with logarithmic selection of a half-open address range."""
    def __init__(self, pointers):
        self._items = tuple(sorted(pointers.items()))
        self._sites = tuple(site for site, _ in self._items)

    def __len__(self):
        return len(self._items)

    def __iter__(self):
        return iter(self._sites)

    def __getitem__(self, site):
        index = bisect_left(self._sites, site)
        if index == len(self._sites) or self._sites[index] != site:
            raise KeyError(site)
        return self._items[index][1]

    def items(self):
        return self._items

    def between(self, start, end):
        return self._items[bisect_left(self._sites, start):bisect_left(self._sites, end)]


def pointer_range(pointers, address, size):
    items = (pointers.between(address, address + size) if isinstance(pointers, RelocationIndex)
             else ((site, target) for site, target in pointers.items()
                   if address <= site < address + size))
    return {site - address: target for site, target in items}


def read_le_fixups(blob):
    if hashlib.sha256(blob).hexdigest() != TARGET_SHA256:
        raise ValueError('Unknown FATE.EXE')
    header = struct.unpack_from('<I', blob, 60)[0]
    if blob[header:header+2] != b'LE':
        raise ValueError('Expected LE header')
    def field(offset):
        return struct.unpack_from('<I', blob, header+offset)[0]
    if field(0x28) != 4096:
        raise ValueError('Unexpected page size')
    objects = [struct.unpack_from('<6I', blob, header+field(0x40)+24*i)
               for i in range(field(0x44))]
    pointers, record_count = {}, 0
    for page in range(field(0x14)):
        begin, end = struct.unpack_from('<II', blob, header+field(0x68)+4*page)
        cursor = header+field(0x6c)+begin
        limit = header+field(0x6c)+end
        if cursor > limit or limit > len(blob):
            raise ValueError('Invalid LE fixup page bounds')
        owner, = [o for o in objects if o[3]-1 <= page < o[3]-1+o[4]]
        base = owner[1]+(page-owner[3]+1)*4096
        while cursor < limit:
            if cursor+5 > limit:
                raise ValueError('Truncated LE fixup')
            kind, flags, source, target_object = struct.unpack_from('<BBhB', blob, cursor)
            cursor += 5
            if kind != 7 or flags not in (0, 16):
                raise ValueError('Unsupported LE fixup')
            width = 4 if flags & 16 else 2
            if cursor+width > limit or not 1 <= target_object <= len(objects):
                raise ValueError('Invalid LE fixup target')
            target = int.from_bytes(blob[cursor:cursor+width], 'little')
            cursor += width
            target_owner = objects[target_object-1]
            address = base+source
            if not owner[1] <= address <= owner[1]+owner[0]-4:
                raise ValueError('LE source outside object')
            if target >= target_owner[0]:
                raise ValueError('LE target outside object')
            value = target_owner[1]+target
            if address in pointers and pointers[address] != value:
                raise ValueError('Conflicting duplicate LE relocation')
            pointers[address] = value
            record_count += 1
    return dict(record_count=record_count, pointers=RelocationIndex(pointers))
