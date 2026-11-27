/* The CRT port primitives retain the original Watcom register ABI. */
extern unsigned input_byte(unsigned, unsigned);
#pragma aux input_byte = "sub eax,eax" "in al,dx" parm [eax] [edx] value [eax] modify exact [eax];
unsigned inp(unsigned port);
#pragma aux inp modify exact [eax];
unsigned inp(unsigned port)
{
    return input_byte(port, port);
}

extern unsigned output_word(unsigned, unsigned);
#pragma aux output_word = "out dx,ax" parm [eax] [edx] value [eax] modify exact [eax edx];
extern unsigned hold_port_word(unsigned);
#pragma aux hold_port_word = parm [ebx] value [ebx] modify exact [];
extern unsigned port_in_edx(unsigned);
#pragma aux port_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned word_after_port(unsigned, unsigned);
#pragma aux word_after_port = parm [ebx] [edx] value [ebx] modify exact [];
unsigned outpw(unsigned port, unsigned word)
{
    unsigned saved = hold_port_word(word);
    unsigned address = port_in_edx(port);
    return output_word(word_after_port(saved, address), address);
}

/* Preserve the original ordering of the port and byte register moves. */
extern unsigned retain_port_original(unsigned);
#pragma aux retain_port_original = parm [ebx] value [ebx] modify exact [ecx];
extern unsigned byte_in_ecx(unsigned, unsigned);
#pragma aux byte_in_ecx = parm [ecx] [ebx] value [ecx] modify exact [];
extern unsigned output_byte(unsigned, unsigned char);
#pragma aux output_byte = "out dx,al" parm [edx] [al] value [eax] modify exact [eax edx];
extern unsigned char byte_after_port(unsigned, unsigned);
#pragma aux byte_after_port = parm [ecx] [edx] value [cl] modify exact [];
unsigned outp(unsigned port, unsigned byte)
{
    unsigned value, address;

    unsigned original = retain_port_original(port);
    value = byte_in_ecx(byte, original);
    address = port_in_edx(port);
    return output_byte(address, byte_after_port(value, address));
}
