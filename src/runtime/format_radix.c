/* Legacy radix conversions use a stack buffer for reversed digits. */
extern const char format_digits[], integer_digits[];

extern void begin_format_digits(char *, unsigned);
#pragma aux begin_format_digits = "push ebp" "sub esp,28h" "push edx" \
    "mov ebp,ebx" "mov esi,edx" "xor dl,dl" "lea ecx,[esp+5]" "mov [esp+4],dl" \
    parm [edx] [ebx] modify exact [ecx edx esi];
extern void begin_ultoa_digits(char *, unsigned);
#pragma aux begin_ultoa_digits = "push ebp" "sub esp,28h" "mov ebp,edx" \
    "mov edi,ebx" "mov esi,edx" "xor dl,dl" "lea ecx,[esp+1]" "mov [esp],dl" \
    parm [edx] [ebx] modify exact [ecx edx esi edi];

/* Each division leaves the quotient in EAX and the next table index in EDX. */
extern char divide_format_digit(void);
#pragma aux divide_format_digit = "lea ebx,[esp+28h]" "mov [esp+28h],ebp" \
    "xor edx,edx" "div dword ptr [ebx]" "mov [ebx],edx" "mov edx,[esp+28h]" \
    "mov dl,cs:[edx+format_digits]" value [dl] modify exact [eax ebx edx];
extern char divide_ultoa_digit(void);
#pragma aux divide_ultoa_digit = "lea ebx,[esp+24h]" "mov [esp+24h],edi" \
    "xor edx,edx" "div dword ptr [ebx]" "mov [ebx],eax" \
    "mov al,cs:[edx+integer_digits]" value [al] modify exact [eax ebx edx];
extern void read_saved_quotient(void);
#pragma aux read_saved_quotient = "mov eax,[esp+24h]" modify exact [eax];
extern unsigned long quotient(void);
#pragma aux quotient = value [eax] modify exact [];

extern char *digit_slot(void);
#pragma aux digit_slot = value [ecx] modify exact [];
extern char *output_slot(void);
#pragma aux output_slot = value [esi] modify exact [];
extern void next_slot(void);
#pragma aux next_slot = "inc ecx" modify exact [ecx];
extern void advance_output(void);
#pragma aux advance_output = "inc esi" modify exact [esi];
extern char previous_digit(void);
#pragma aux previous_digit = "dec ecx" "mov al,[ecx]" value [al] modify exact [eax ecx];

extern char *finish_format_digits(void);
#pragma aux finish_format_digits = "mov eax,[esp]" "add esp,2ch" "pop ebp" value [eax] modify exact [eax];
extern char *finish_ultoa_digits(void);
#pragma aux finish_ultoa_digits = "mov eax,ebp" "add esp,28h" "pop ebp" value [eax] modify exact [eax];

char *format_unsigned(unsigned long, char *, unsigned);
#pragma aux format_unsigned modify exact [eax ebx edx];
char *format_unsigned(unsigned long number, char *out, unsigned radix)
{
    char digit;

    begin_format_digits(out, radix);
    do {
        *digit_slot() = divide_format_digit();
        next_slot();
    } while (quotient());
    do {
        digit = previous_digit();
        *output_slot() = digit;
        advance_output();
    } while (digit);
    return finish_format_digits();
}

char *ultoa(unsigned long, char *, unsigned);
#pragma aux ultoa modify exact [eax ebx edx];
char *ultoa(unsigned long number, char *out, unsigned radix)
{
    char digit;

    begin_ultoa_digits(out, radix);
    do {
        *digit_slot() = divide_ultoa_digit();
        read_saved_quotient();
        next_slot();
    } while (quotient());
    do {
        digit = previous_digit();
        *output_slot() = digit;
        advance_output();
    } while (digit);
    return finish_ultoa_digits();
}
