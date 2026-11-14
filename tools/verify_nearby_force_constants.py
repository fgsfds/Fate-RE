"""Verify the 16 source-generated nearby-force DATA bytes, without code coverage."""
import argparse
import hashlib
import json
import struct
from pathlib import Path
from check_start_hook import EXPECTED, image
from match_objects import read_object
from le_fixups import read_le_fixups
from omf_fixups import read_externals, read_fixups

OFFSET, SIZE, RAW = 0xf8, 16, 0x9b6f8
SYMBOLS = [('_force_normalizer',0),('_force_numerator',4),('_force_cap',8),('_force_vertical',12)]


def extract(blob):
    segments,publics=read_object(blob)
    populated=[(i,s) for i,s in enumerate(segments) if s and len(s['data'])]
    if len(populated)!=1:raise ValueError('Expected one allocated constant segment')
    index,segment=populated[0]
    if segment['name']!='CONST' or segment['cls']!='DATA' or len(segment['data'])!=SIZE:
        raise ValueError('Expected 16-byte CONST/DATA payload and no code')
    if publics!=[(index,off,name) for name,off in SYMBOLS]:
        raise ValueError('Unexpected nearby-force constant public layout')
    if read_fixups(blob) or len(read_externals(blob))!=1:
        raise ValueError('Constants must have no fixups or external dependencies')
    return bytes(segment['data'])


def verify(executable,obj):
    exe = executable if isinstance(executable, bytes) else Path(executable).read_bytes()
    blob = obj if isinstance(obj, bytes) else Path(obj).read_bytes()
    if hashlib.sha256(exe).hexdigest()!=EXPECTED:raise ValueError('Unsupported executable hash')
    data=extract(blob)
    if data!=exe[RAW:RAW+SIZE] or data!=image(exe)[0x80000+OFFSET:0x80000+OFFSET+SIZE]:
        raise ValueError('Nearby-force initialized DATA mismatch')
    if any(0x80000+OFFSET <= site < 0x80000+OFFSET+SIZE for site in read_le_fixups(exe)['pointers']):
        raise ValueError('Unexpected original relocation within constants')
    return dict(executable_sha256=EXPECTED,object_sha256=hashlib.sha256(blob).hexdigest(),
        data_object_offset=hex(OFFSET),loaded_address=hex(0x80000+OFFSET),raw_file_offset=hex(RAW),
        bytes=SIZE,exact_initialized_data=True,code_bytes=0,fixups=0,
        source_values=list(struct.unpack('<4f',data)),payload_sha256=hashlib.sha256(data).hexdigest(),
        publics={name:hex(OFFSET+off) for name,off in SYMBOLS},
        original_function_still_unmatched=True,placement_pragma_is_reconstruction_choice=True)


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('executable',type=Path);p.add_argument('object',type=Path)
    p.add_argument('--output',type=Path,required=True);a=p.parse_args()
    a.output.write_text(json.dumps(verify(a.executable,a.object),indent=2)+'\n',encoding='utf-8')
    print('PASS: 16 exact initialized DATA bytes, four named floats, zero code/fixups')
