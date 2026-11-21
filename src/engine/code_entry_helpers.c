/* Issue the BIOS Print Screen service and return. */
extern void bios_print_screen_body(void);
#pragma aux bios_print_screen_body = 0xcd 0x05 modify exact [];

void bios_print_screen(void);
#pragma aux bios_print_screen modify exact [];
void bios_print_screen(void)
{
    bios_print_screen_body();
}
