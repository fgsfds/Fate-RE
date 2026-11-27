typedef void (__interrupt __far *InterruptHandler)(void);

extern const unsigned char dos_extender_type;
extern unsigned char extender_in_ah(unsigned char);
#pragma aux extender_in_ah = parm [ah] value [ah] modify exact [];
extern void save_vector(unsigned);
#pragma aux save_vector = parm [ebx] modify exact [];
extern unsigned vector_number(void);
#pragma aux vector_number = value [ebx] modify exact [];
extern unsigned service_in_eax(unsigned);
#pragma aux service_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned service_with_high_byte(unsigned char);
#pragma aux service_with_high_byte = parm [ah] value [eax] modify exact [];
extern unsigned char service_high_byte(void);
#pragma aux service_high_byte = value [ah] modify exact [];
extern void selector_vector(unsigned char);
#pragma aux selector_vector = parm [cl] modify exact [];
extern unsigned char vector_in_cl(void);
#pragma aux vector_in_cl = value [cl] modify exact [];
/* DOS returns the handler in ES:EBX. Preserve ES around the interrupt. */
extern InterruptHandler read_interrupt_vector(unsigned, unsigned char);
#pragma aux read_interrupt_vector = "push es" "int 21h" 0x8c 0xc2 "pop es" "mov eax,ebx" parm [eax] [cl] value [dx eax] modify exact [eax ebx ecx edx];

InterruptHandler _dos_getvect(unsigned vector);
#pragma aux _dos_getvect parm [eax] value [dx eax] modify exact [eax edx];
InterruptHandler _dos_getvect(unsigned vector)
{
    unsigned char extender;
    unsigned service;

    save_vector(vector);
    extender = extender_in_ah(dos_extender_type);
    if (extender >= 2 && extender <= 8) {
        service = service_in_eax(0x2502);
        selector_vector((unsigned char)vector_number());
    } else {
        service = service_in_eax(vector_number() & 0xff);
        selector_vector(0);
        service = service_with_high_byte(service_high_byte() | 0x35);
    }
    return read_interrupt_vector(service, vector_in_cl());
}

extern void offset_in_edx(unsigned);
#pragma aux offset_in_edx = parm [edx] modify exact [];
extern unsigned char extender_in_bl(unsigned char);
#pragma aux extender_in_bl = parm [bl] value [bl] modify exact [];
extern unsigned handler_offset(void);
#pragma aux handler_offset = value [edx] modify exact [];
extern unsigned handler_selector(void);
#pragma aux handler_selector = value [ecx] modify exact [];
extern unsigned incoming_vector(void);
#pragma aux incoming_vector = value [eax] modify exact [];

/* DOS expects the handler at DS:EDX. The caller's DS remains in use afterward. */
extern void write_extender_vector(unsigned, unsigned, unsigned);
#pragma aux write_extender_vector = "push ds" 0x8e 0xd9 "mov cl,al" "mov al,4" "mov ah,25h" "int 21h" "pop ds" parm [eax] [edx] [ecx] modify exact [eax ebx ecx edx];
extern void write_dos_vector(unsigned, unsigned, unsigned);
#pragma aux write_dos_vector = "push ds" 0x8e 0xd9 "mov ah,25h" "int 21h" "pop ds" parm [eax] [edx] [ecx] modify exact [eax ebx ecx edx];

void _dos_setvect(unsigned, void (*)(void), unsigned);
#pragma aux _dos_setvect parm [eax] [ebx] [ecx] modify exact [eax ebx ecx];
void _dos_setvect(unsigned vector, void (*handler)(void), unsigned selector)
{
    unsigned char extender;

    offset_in_edx((unsigned)handler);
    extender = extender_in_bl(dos_extender_type);

    if (extender >= 2 && extender <= 8)
        write_extender_vector(incoming_vector(), handler_offset(), handler_selector());
    else
        write_dos_vector(incoming_vector(), handler_offset(), handler_selector());
}
