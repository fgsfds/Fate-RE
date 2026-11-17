"""Mark Watcom inline byte streams in a temporary source copy."""
import argparse
from pathlib import Path
import re

PREFIX = re.compile(r'#\s*pragma\s+aux\s+[a-zA-Z_]\w*\s*=\s*')
TOKENS = re.compile(
    r'"(?:\\.|[^"\\])*"|/\*.*?\*/|//[^\n]*|\\\r?\n|[A-Za-z_]\w*|0[xX][0-9a-fA-F]+|\d+|[,;]|[^\s]',
    re.S,
)
METADATA = {'parm', 'value', 'modify', 'aborts', 'loadds', 'nomemory', 'frame', 'far', 'near'}

# Only annotated rel8 branches are adjusted. The object verifier
# independently requires the adjusted jump to reach the same instruction.
# One count describes complete marker pairs. Two counts describe start and end markers.
MARKER_REL8 = re.compile(
    r'"db (7[0-9a-f]|0?eb)h, (?:0)?([0-9a-f]{2})h" '
    r'/\* marker-rel8 ([+-][1-9]\d*|0)(?:,([+-][1-9]\d*|0))?(?: (widen))? \*/'
)


def adjust_short_branches(body, unique_ends):
    def adjust(match):
        opcode, encoded, starts, ends, widen = match.groups()
        before = int(encoded, 16)
        displacement = before if before < 0x80 else before - 0x100
        after = displacement + int(starts) + int(ends or starts) * (2 if unique_ends else 1)
        if widen and opcode not in ('eb', '0eb'):
            raise ValueError("Marker widening requires an unconditional jump")
        if not -128 <= after <= 127:
            if not widen:
                raise ValueError("Marker-adjusted short branch exceeds signed byte range")
            # Growth shifts a forward target by the same amount as the JMP.
            # A backward target stays put while the end of the JMP moves.
            if displacement < 0:
                after -= 3
            encoded = ', '.join(f'0{byte:02x}h' for byte in after.to_bytes(4, 'little', signed=True))
            return f'"db 0e9h, {encoded}"'
        hex_byte = f'{after & 0xff:02x}'
        if hex_byte[0].isalpha():
            hex_byte = '0' + hex_byte
        return f'"db {opcode}h, {hex_byte}h"'

    adjusted = MARKER_REL8.sub(adjust, body)
    if 'marker-rel8' in adjusted:
        raise ValueError("Unsupported marker-rel8 annotation")
    return adjusted


def instrument(source, unique_ends=False):
    units = 0

    def wrap(match):
        nonlocal units
        original = match[0]
        original = adjust_short_branches(original, unique_ends)
        prefix = PREFIX.search(original)
        if not prefix:
            if any(token[0] == '=' for token in TOKENS.finditer(original)):
                raise ValueError(f'Unsupported aux pragma spelling {original!r}')
            return original
        first = last = None
        substantive = False
        commas = []
        for token in TOKENS.finditer(original, prefix.end()):
            value = token[0]
            if value in METADATA or value == ';':
                break
            if value == ',':
                commas.append(token.start())
                continue
            if value in ('\\\n', '\\\r\n') or value.startswith(('/*', '//')):
                continue
            if value[0].isalpha() or value[0] == '_' or value[0].isdigit() or value.startswith('"'):
                first = token.start() if first is None else first
                last = token.end()
                substantive |= value != '""'
            else:
                raise ValueError(f'Unhandled inline operand {value!r} in {original!r}')
        if not substantive:
            return original
        units += 1
        body = ''.join(value for index, value in enumerate(original[first:last], first)
                       if index not in commas)
        trailing = ''.join(value for index, value in enumerate(original[last:], last)
                           if index not in commas)
        if unique_ends:
            if units > 127:
                raise ValueError('Too many distinct end markers in one source file')
            end = f'0xcd {0x80 + units:#x}'
        else:
            end = '0xf4'
        return original[:first] + '0xf1 ' + body + ' ' + end + trailing

    # Preserve physical newlines while joining each pragma's continuation.
    logical = re.compile(r'^[ \t]*#[ \t]*pragma[ \t]+aux\b(?:[^\r\n\\]|\\[^\r\n]|\\\r?\n)*', re.M)
    return logical.sub(wrap, source), units

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('marked', type=Path)
    args = parser.parse_args()
    content, units = instrument(args.source.read_text(encoding='utf-8'))
    args.marked.write_text(content, encoding='utf-8')
    print(f'Marked {units} nonempty pragma bodies')
