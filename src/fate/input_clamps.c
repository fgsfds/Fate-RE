/* A private context for the cursor and map scale clamps. */
extern short cursor_x, cursor_y, map_scale_or_y;

/* This identity constrains an unchanged value to EBX. */
extern long input_clamp_in_ebx(long);
#pragma aux input_clamp_in_ebx = "" parm [ebx] value [ebx] modify exact [];

/* Precondition: cursor_position equals the current signed cursor_x word and
   scale equals the current signed map_scale_or_y word. DATA stays stable
   during a call. Placed operations receive those coherent live samples;
   this private normalization service is not the input collector itself. */
extern void input_clamp_view_state(long, short);
#pragma aux input_clamp_view_state parm [ebx] [esi] modify exact [ebx];

void input_clamp_view_state(long cursor_position, short scale)
{
    {
        long position = cursor_position;

        position = position > 316 ? position : 316;
        if (position < 988) {
            position = input_clamp_in_ebx(cursor_x);
            if (position <= 316)
                position = input_clamp_in_ebx(316L);
        } else {
            position = input_clamp_in_ebx(988L);
        }
        cursor_x = (short)input_clamp_in_ebx(position);
    }

    {
        long position = input_clamp_in_ebx(cursor_y);

        position = position > 364 ? position : 364;
        if (position < 440) {
            position = input_clamp_in_ebx(cursor_y);
            if (position <= 364)
                position = input_clamp_in_ebx(364L);
        } else {
            position = input_clamp_in_ebx(440L);
        }
        cursor_y = (short)input_clamp_in_ebx(position);
    }

    {
        long position = input_clamp_in_ebx((long)scale);

        position = position > 256 ? position : 256;
        if (position < 2048) {
            position = input_clamp_in_ebx(map_scale_or_y);
            if (position <= 256)
                position = input_clamp_in_ebx(256L);
        } else {
            position = input_clamp_in_ebx(2048L);
        }
        map_scale_or_y = (short)input_clamp_in_ebx(position);
    }
}
