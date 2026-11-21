extern unsigned char transport;
extern volatile short *outbufend, *outbufplc;
extern void startcom(void);
#pragma aux startcom modify exact [eax];

long output_queue_depth(void)
{
    long mode = transport;
    if (mode >= 1 && mode <= 4) {
        startcom();
        return (16384 + (*outbufend - *outbufplc)) & 16383;
    }
    return 0;
}
