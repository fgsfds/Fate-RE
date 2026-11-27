extern unsigned strlen(const char *);
#pragma intrinsic(strlen);
unsigned runtime_strlen(const char *);
#pragma aux runtime_strlen "strlen_" modify exact [eax];
unsigned runtime_strlen(const char *text)
{
    return strlen(text);
}
