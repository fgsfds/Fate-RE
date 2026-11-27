struct FormatState;
struct FormatArguments;

/* The original callback returns a segmented text pointer in DX:EAX. */
typedef char __far *FloatFormatter(char *, struct FormatArguments *, struct FormatState *);
#pragma aux FloatFormatter parm [eax] [edx] [ebx] value [dx eax] modify exact [eax edx ebx ecx];
extern FloatFormatter *float_formatter;

char __far *call_float_formatter(char *, struct FormatArguments *, struct FormatState *);
#pragma aux call_float_formatter parm [eax] [edx] [ebx] value [dx eax] modify exact [eax edx ebx ecx];
char __far *call_float_formatter(char *buffer, struct FormatArguments *arguments, struct FormatState *state)
{
    return float_formatter(buffer, arguments, state);
}
