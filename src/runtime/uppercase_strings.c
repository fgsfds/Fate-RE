extern int toupper(int);
#pragma aux toupper modify exact [eax];

void uppercase_output(unsigned char *text)
{
    for (;;) {
        if (!*text)
            break;
        *text = (unsigned char)toupper(*text);
        ++text;
    }
}

char *strupr(char *text)
{
    char *p = text;
    for (;; ++p) {
        unsigned char ch = *p;
        if (ch == '\0')
            break;
        ch -= 'a';
        if (ch <= 'z' - 'a')
            *p = ch + 'A';
    }
    return text;
}
