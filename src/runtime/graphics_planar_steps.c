/* Planar device callbacks receive and return their pixel address in EDI. */
unsigned char *step_up_80(unsigned char *pixel);
#pragma aux step_up_80 parm [edi] value [edi] modify exact [edi];
unsigned char *step_up_80(unsigned char *pixel)
{
    return pixel - 80;
}

unsigned char *step_down_80(unsigned char *pixel);
#pragma aux step_down_80 parm [edi] value [edi] modify exact [edi];
unsigned char *step_down_80(unsigned char *pixel)
{
    return pixel + 80;
}

unsigned char *step_up_40(unsigned char *pixel);
#pragma aux step_up_40 parm [edi] value [edi] modify exact [edi];
unsigned char *step_up_40(unsigned char *pixel)
{
    return pixel - 40;
}

unsigned char *step_down_40(unsigned char *pixel);
#pragma aux step_down_40 parm [edi] value [edi] modify exact [edi];
unsigned char *step_down_40(unsigned char *pixel)
{
    return pixel + 40;
}
