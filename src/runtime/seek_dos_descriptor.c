extern long set_dos_errno(unsigned);
#pragma aux set_dos_errno modify exact [eax];
extern int handle_in_ecx(int);
#pragma aux handle_in_ecx = parm [ecx] value [ecx] modify exact [];
extern int handle_in_ebx(int);
#pragma aux handle_in_ebx = parm [ebx] value [ebx] modify exact [];
extern unsigned kind_in_eax(unsigned);
#pragma aux kind_in_eax = parm [eax] value [eax] modify exact [];
extern long *position_in_edi(long *);
#pragma aux position_in_edi = parm [edi] value [edi] modify exact [];
extern unsigned high_offset_in_ecx(unsigned);
#pragma aux high_offset_in_ecx = parm [ecx] value [ecx] modify exact [];
extern unsigned seek_service(unsigned);
#pragma aux seek_service = "mov ah,42h" parm [eax] value [eax] modify exact [];
/* DOS returns the position in DX:AX and reports failure in carry. */
extern long dos_seek(unsigned, int, unsigned, unsigned, long *);
/* Use the historical operand-size prefix before each SS override. */
#pragma aux dos_seek = "int 21h" 0x66 "mov ss:[edi],eax" 0x66 "mov ss:[edi+2],edx" "rcl eax,1" "ror eax,1" parm [eax] [ebx] [ecx] [edx] [edi] value [eax] modify exact [eax ebx edx];

long lseek(int, long, int);
#pragma aux lseek modify exact [eax edx ebx];
long lseek(int handle, long offset, int origin)
{
    long position;
    long status;
    long *result;
    unsigned high;

    handle = handle_in_ecx(handle);
    origin = kind_in_eax(origin);
    result = position_in_edi(&position);
    handle = handle_in_ebx(handle);
    origin = seek_service(origin);
    high = high_offset_in_ecx(offset);
    high = high_offset_in_ecx(high >> 16);
    status = dos_seek(origin, handle, high, offset, result);
    if (status < 0) {
        set_dos_errno(status & 0xffff);
        return -1;
    }
    return position;
}
