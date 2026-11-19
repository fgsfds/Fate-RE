/* OR/XOR a byte through the palette mask and return. */
extern void or_masked_byte_body(void);
#pragma aux or_masked_byte_body = 0x22 0xc5 0x26 0x08 0x07 modify exact [];

void or_masked_byte(void);
#pragma aux or_masked_byte modify exact [];
void or_masked_byte(void)
{
    or_masked_byte_body();
}

extern void xor_masked_byte_body(void);
#pragma aux xor_masked_byte_body = 0x22 0xc5 0x26 0x30 0x07 modify exact [];

void xor_masked_byte(void);
#pragma aux xor_masked_byte modify exact [];
void xor_masked_byte(void)
{
    xor_masked_byte_body();
}
