/* Byte-addressed graphics callbacks pass and return their cursor in EDI. */
unsigned char *step_byte_up_320(unsigned char *pixel);
#pragma aux step_byte_up_320 parm [edi] value [edi] modify exact [edi];
unsigned char *step_byte_up_320(unsigned char *pixel)
{
    return pixel - 320;
}

unsigned char *step_byte_down_320(unsigned char *pixel);
#pragma aux step_byte_down_320 parm [edi] value [edi] modify exact [edi];
unsigned char *step_byte_down_320(unsigned char *pixel)
{
    return pixel + 320;
}

unsigned char *step_byte_left(unsigned char *pixel);
#pragma aux step_byte_left parm [edi] value [edi] modify exact [edi];
unsigned char *step_byte_left(unsigned char *pixel)
{
    return pixel - 1;
}

unsigned char *step_byte_right(unsigned char *pixel);
#pragma aux step_byte_right parm [edi] value [edi] modify exact [edi];
unsigned char *step_byte_right(unsigned char *pixel)
{
    return pixel + 1;
}

unsigned char *step_byte_up_100(unsigned char *pixel);
#pragma aux step_byte_up_100 parm [edi] value [edi] modify exact [edi];
unsigned char *step_byte_up_100(unsigned char *pixel)
{
    return pixel - 100;
}

unsigned char *step_byte_down_100(unsigned char *pixel);
#pragma aux step_byte_down_100 parm [edi] value [edi] modify exact [edi];
unsigned char *step_byte_down_100(unsigned char *pixel)
{
    return pixel + 100;
}
