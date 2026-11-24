/* Partial lanes are bounded by 0x1f1f and 0x1f1f1f; all signed arithmetic fits. */
extern int packed_edi(int);
#pragma aux packed_edi = "" parm [edi] value [edi] modify exact [];
extern int packed_eax(int);
#pragma aux packed_eax = "" parm [eax] value [eax] modify exact [];
int ripple_pack_two(int,int);
#pragma aux ripple_pack_two parm [edi] [eax] value [edi] modify exact [eax edi];
int ripple_pack_two(int first,int second)
{
    first = packed_edi(first & 248);
    second = packed_eax(second & 248);
    first = packed_edi(first >> 3);
    second = packed_eax(second << 5);
    return packed_edi(first + second);
}

extern int packed_edi(int);
#pragma aux packed_edi = "" parm [edi] value [edi] modify exact [];
extern int packed_eax(int);
#pragma aux packed_eax = "" parm [eax] value [eax] modify exact [];
int ripple_pack_third(int,int);
#pragma aux ripple_pack_third parm [edi] [eax] value [edi] modify exact [eax edi];
int ripple_pack_third(int lanes,int sum)
{
    sum = packed_eax(sum & 248);
    sum = packed_eax(sum << 13);
    return packed_edi(lanes + sum);
}

extern int packed_eax(int);
#pragma aux packed_eax = "" parm [eax] value [eax] modify exact [];
int ripple_pack_fourth(int,int);
#pragma aux ripple_pack_fourth parm [edi] [eax] value [eax] modify exact [eax];
int ripple_pack_fourth(int lanes,int sum)
{
    sum = packed_eax(sum & 248);
    sum = packed_eax(sum << 21);
    sum = packed_eax(sum + lanes);
    return packed_eax(sum - 0x3d3d3d3e);
}
