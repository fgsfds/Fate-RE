extern short probe_crtc_cursor_register(short port);
#pragma aux probe_crtc_cursor_register modify exact [eax];

extern int read_mono_status(int port);
#pragma aux read_mono_status = "sub eax,eax" "in al,dx" parm [edx] value [eax] modify exact [];
/* Preserve the status bit in CX while polling the hardware. */
extern short initial_mono_status(int status);
#pragma aux initial_mono_status = "and cl,80h" "xor ch,ah" parm [ecx] value [cx] modify exact [];
extern short sample_in_bx(short sample);
#pragma aux sample_in_bx = "" parm [bx] value [bx] modify exact [];
extern short result_in_dx(short result);
#pragma aux result_in_dx = "" parm [dx] value [dx] modify exact [];
extern short classify_hercules_status(int status);
#pragma aux classify_hercules_status = "and al,70h" "xor ah,ah" parm [eax] value [ax] modify exact [];

short detect_mono_adapter(void)
{
    short initial, type;
    unsigned short sample;
    short features;
    int status;

    if (!probe_crtc_cursor_register(0x3b4))
        goto absent;

    initial = initial_mono_status(read_mono_status(0x3ba));
    for (sample = sample_in_bx(0); sample < 0x8000; ++sample) {
        status = read_mono_status(0x3ba);
        if ((status & 0x80) == initial)
            continue;
        features = classify_hercules_status(read_mono_status(0x3ba));
        if (!features) {
            type = 13;
            goto done;
        }
        if (!(features & 0x10)) {
            type = 14;
            goto done;
        }
        type = 15;
        goto done;
    }
    /* A controller without a changing status bit is monochrome text only. */
    type = 1;
    goto done;
absent:
    type = 0;
done:
    return result_in_dx(type);
}
