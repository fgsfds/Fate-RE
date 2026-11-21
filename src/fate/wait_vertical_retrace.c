/* Wait for the VGA retrace signal with the original instruction sequence. */
extern void wait_vertical_retrace_body(void);
#pragma aux wait_vertical_retrace_body = \
    0x31 0xd2            /* xor edx,edx */ \
    0x31 0xc0            /* xor eax,eax */ \
    0x66 0x81 0xf2 0xda 0x03 /* xor dx,0x3da */ \
    0xec                 /* in al,dx */ \
    0xa8 0x08            /* test al,8 */ \
    0x75 0xfb            /* jnz first */ \
    0xec                 /* in al,dx */ \
    0xa8 0x08            /* test al,8 */ \
    0x74 0xfb            /* je second */ \
    0xe2 0xf4            /* loop first */ \
    0xfc                 /* cld */ \
    modify exact [];

void wait_vertical_retrace(void);
#pragma aux wait_vertical_retrace modify exact [];
void wait_vertical_retrace(void)
{
    wait_vertical_retrace_body();
}
