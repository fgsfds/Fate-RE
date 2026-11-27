/* Save/load status uses the low length byte and a wrapping 32-bit clock. */
typedef char SaveStatusWidth[sizeof(unsigned)==4 ? 1 : -1];
extern unsigned char save_status_length;
extern unsigned save_status_clock, save_status_expiration;

/* Empty identities preserve the EAX-width/EDX-clock scheduling and result. */
extern unsigned status_width(unsigned);
#pragma aux status_width = "" parm [eax] value [eax] modify exact [edx];
extern unsigned status_clock(unsigned);
#pragma aux status_clock = "" parm [edx] value [edx] modify exact [];
extern unsigned status_base(unsigned,unsigned);
#pragma aux status_base = "" parm [edx] [eax] value [edx] modify exact [];
extern unsigned status_result(unsigned);
#pragma aux status_result = "" parm [edx] value [edx] modify exact [];

unsigned save_status_completion(unsigned);
#pragma aux save_status_completion parm [eax] value [eax] modify exact [eax edx];
unsigned save_status_completion(unsigned length)
{
    unsigned width,clock;
    save_status_length=(unsigned char)length;
    width=status_width((unsigned)(unsigned char)length<<4);
    clock=status_clock(save_status_clock);
    save_status_expiration=status_result(status_base(clock+360,width)+width);
    return 0;
}
