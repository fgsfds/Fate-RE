/* Select the 9-byte word merge before the private RET. Incoming EAX holds
 * the shifted packet byte; BX holds the old low byte; EDX is sender*5.
 * receiver_button_bytes is a separately named view of existing DS storage.
 * This DOS-only overlay intentionally uses the packed input word at offset 3.
 */
/* Real high-button merge: high is packet byte shifted 8, low contains old low byte. */
extern unsigned char receiver_button_bytes[80];
extern unsigned short ax_word(unsigned short);
#pragma aux ax_word = parm nomemory [ax] value [ax] modify exact nomemory [];
void receive_button_high(unsigned long, unsigned long, unsigned long);
#pragma aux receive_button_high parm [eax] [ebx] [edx] modify exact [eax];
void receive_button_high(unsigned long high, unsigned long low, unsigned long offset)
{
    *(unsigned short *)(receiver_button_bytes + offset + 3) = ax_word((unsigned short)(high | low));
}
