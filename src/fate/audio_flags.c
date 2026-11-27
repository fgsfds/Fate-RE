extern unsigned long frame_state_12cd4, frame_state_12cd8;

/* Keep the zero-case store in EBX, as in the original Watcom output. */
extern unsigned long audio_flag_store_value(unsigned long);
#pragma aux audio_flag_store_value = parm [ebx] value [ebx] modify exact [];

void set_audio_flag_a(unsigned long flag)
{
    switch (flag) {
    case 0:
        frame_state_12cd4 = audio_flag_store_value(0);
        break;
    case 1:
        frame_state_12cd4 = flag;
        break;
    }
}

void set_audio_flag_b(unsigned long flag)
{
    switch (flag) {
    case 0:
        frame_state_12cd8 = audio_flag_store_value(0);
        break;
    case 1:
        frame_state_12cd8 = flag;
        break;
    }
}
