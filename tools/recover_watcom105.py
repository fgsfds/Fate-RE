"""Recover the intact 10.5 compiler from the pinned disc's split WPACK payload.

Uses the official Open Watcom decoder core and its required stable quicksort.
Generated decoder source retains upstream attribution and stays in scratch space.
"""
import argparse
import hashlib
import os
from pathlib import Path
import struct
import subprocess
import zlib


def checked(path, digest):
    data = path.read_bytes()
    if hashlib.sha256(data).hexdigest() != digest:
        raise ValueError(f'Unexpected input: {path}')
    return data


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--media', type=Path, default=Path('reference/watcom105-full'))
    parser.add_argument('--upstream', type=Path, default=Path('reference/open-watcom-v2'))
    parser.add_argument('--cc', type=Path, default=Path('C:/msys64/mingw64/bin/gcc.exe'))
    parser.add_argument('--work', type=Path, default=Path('work/wcc105-recovery'))
    parser.add_argument('--output', type=Path, default=Path('reference/watcom105-recovered/binw'))
    args = parser.parse_args()
    package = ((args.media/'DISKIMGS/DISK02/PCK00017.1').read_bytes()
               + (args.media/'DISKIMGS/DISK03/PCK00017.2').read_bytes())
    assert hashlib.sha256(package).hexdigest() == 'ee1b23125a9ab9a491df621e9d48dcadecfa82c617bf7844616ffc1bc7291463'
    signature, major, minor, files, info_size, info_offset = struct.unpack_from('<HBBHHI', package)
    assert (signature, major, minor, files, info_size) == (0x2403, 1, 1, 1, 27)
    size, start, stamp, crc, namelen = struct.unpack_from('<4IB', package, info_offset)
    assert size == 567558 and start == 12 and namelen == 10
    assert info_offset+info_size == len(package)
    assert package[info_offset+17:] == b'wcc386.exe'
    assert zlib.crc32(package[start:info_offset]) == crc == 0x4e91cf76
    root = args.upstream/'bld/wpack'
    decoder = checked(root/'c/decode.c', '19c1d67eac8495f4f691ef02e5df4f2830ca182c67efd35165a6aa0e166c7192').decode()
    checked(root/'c/wqsort.c', '771c0b4288eec7987fbf335c70227c295c1f45f75d4c43af9416a9c97547c573')
    license_text = decoder[:decoder.index('#include')]
    core = decoder[decoder.index('unsigned short   MinCodeLen;'):decoder.index('static bool CompareCRC')]
    preamble = r'''
#include <stdio.h>
#include <stdlib.h>
#include "wqsort.h"
typedef unsigned char byte,uchar;
#define STRBUF_SIZE 4096
#define LAHEAD_SIZE 60
#define THRESHOLD 2
#define NUM_CHARS (256-THRESHOLD+LAHEAD_SIZE)
#define MAX_CODE_BITS 16
unsigned char text_buf[STRBUF_SIZE+LAHEAD_SIZE-1],len[NUM_CHARS];
int indicies[NUM_CHARS];
static FILE *input,*output;
static unsigned long written;
static unsigned char DecReadByte(void) { int c=fgetc(input); if(c==EOF) exit(3); return c; }
static void DecWriteByte(int c) { if(++written>567558) exit(4); fputc(c,output); }
static void FlushWrite(void) { fflush(output); }
void AssignCodes(int);
'''
    main = r'''
int main(int argc,char **argv) {
    if(argc!=3)return 1;
    input=fopen(argv[1],"rb"); output=fopen(argv[2],"wb");
    if(!input||!output)return 2;
    fseek(input,12,SEEK_SET); DoDecode(567558);
    fclose(input); fclose(output);
    return written==567558?0:5;
}
'''
    args.work.mkdir(parents=True, exist_ok=True)
    source = args.work/'decode-probe.c'
    source.write_text(license_text+preamble+core+main, encoding='utf-8', newline='\n')
    archive = args.work/'compiler.pck'
    archive.write_bytes(package)
    program = args.work/'decode-probe.exe'
    recovered = args.work/'wcc386.exe'
    env = dict(os.environ)
    env['PATH'] = str(args.cc.resolve().parent)+os.pathsep+env['PATH']
    subprocess.run([str(args.cc), '-O2', '-I'+str(root/'h'), str(source),
                    str(root/'c/wqsort.c'), '-o', str(program)], env=env, check=True)
    subprocess.run([str(program.resolve()), str(archive), str(recovered)], env=env, check=True)
    compiler = checked(recovered, '1b97a68f7b8a3efd89b05f64ce99836b1e533f398699305f96dc423254939d6a')
    truncated = checked(args.media/'BINW/WCC386.EXE', '4ba2511a192f90adae95ffbd4dfc82a836cbb7107e7da788fb555303221da2a1')
    assert compiler[:len(truncated)] == truncated
    loader = checked(args.media/'BINW/W32RUN.EXE', 'f3b2864d171319728baaf95c1188e7b98d5b9ce2bb13768b5272e3ec5c94f4f4')
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output/'wcc386.exe').write_bytes(compiler)
    (args.output/'w32run.exe').write_bytes(loader)
    print('PASS: compressed CRC, 567558-byte compiler hash, truncated prefix and loader hash')
