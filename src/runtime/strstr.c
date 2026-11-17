/* Search a NUL-terminated string using the Watcom near-string convention.
   Watcom owns EBX/ECX/ESI/EDI preservation; EBP and real scratch storage stay
   explicit because the existing search helpers address that saved frame. */
extern void begin_search(const char *, const char *);
#pragma aux begin_search = "push ebp" "sub esp,4" \
    "mov esi,eax" "mov ebx,edx" parm [eax] [edx] modify exact [ebx esi];
extern const char *needle_argument(void);
#pragma aux needle_argument = value [edx] modify exact [];
extern char *current_haystack(void);
#pragma aux current_haystack = value [esi] modify exact [];
/* Two characters per iteration, stopping at the first NUL or match.
 * The encoded branches keep the original short jumps and first near jump.
 */
extern void scan_single_character(void);
#pragma aux scan_single_character = "mov dl,[ebx]" \
    "mov al,[esi]" 0x3a 0xc2 0x74 0x16 "cmp al,0" 0x0f 0x84 0x0c 0 0 0 \
    "inc esi" "mov al,[esi]" 0x3a 0xc2 0x74 0x07 "inc esi" "cmp al,0" \
    0x75 0xe6 0x2b 0xf6 modify exact [eax edx esi];
extern char *single_result(void);
#pragma aux single_result = "mov eax,esi" value [eax] modify exact [eax];

/* The two SCAS paths return the found address in EDI, or zero on exhaustion.
 * The overlapping TEST skips the fallback register move on a successful scan.
 */
#define FIND_BYTE "push es" 0xe3 0x0b 0x8c 0xda 0x8e 0xc2 \
    "repne scasb" 0x75 0x03 "dec edi" 0x66 0xa9 "mov edi,ecx" "pop es"
extern void scan_haystack_end(void);
#pragma aux scan_haystack_end = "mov ecx,0ffffffffh" "mov edi,esi" "xor al,al" FIND_BYTE \
    "mov [esp],edi" modify exact [eax ecx edx edi];
extern void measure_needle(void);
#pragma aux measure_needle = "mov edi,ebx" "push es" 0x8c 0xd8 0x8e 0xc0 \
    "sub ecx,ecx" "dec ecx" "xor eax,eax" "repne scasb" "not ecx" "dec ecx" "pop es" \
    "mov ebp,ecx" modify exact [eax ecx edi];
extern int unsearched_length(void);
#pragma aux unsearched_length = "mov ecx,[esp]" "sub ecx,esi" value [ecx] modify exact [ecx];
extern int needle_length(void);
#pragma aux needle_length = value [ebp] modify exact [];
extern const char *find_candidate(void);
#pragma aux find_candidate = "mov edi,esi" "mov al,[ebx]" FIND_BYTE \
    "mov edx,edi" value [edi] modify exact [eax ecx edx edi];
extern int compare_candidate(void);
#pragma aux compare_candidate = "mov esi,edi" "mov ecx,ebp" "mov edi,ebx" "push es" \
    0x8c 0xd8 0x8e 0xc0 "xor eax,eax" "repe cmpsb" 0x74 0x05 \
    "sbb eax,eax" "sbb eax,-1" "pop es" value [eax] modify exact [eax ecx esi edi];
extern char *matched_candidate(void);
#pragma aux matched_candidate = "mov eax,edx" value [eax] modify exact [eax];
extern void advance_candidate(void);
#pragma aux advance_candidate = "lea esi,[edx+1]" modify exact [esi];
extern char *no_match(void);
#pragma aux no_match = "xor eax,eax" value [eax] modify exact [eax];
extern char *finish_search(char *);
#pragma aux finish_search = "add esp,4" "pop ebp" \
    parm [eax] value [eax] modify exact [];

char *strstr(const char *, const char *);
#pragma aux strstr modify exact [eax edx];
char *strstr(const char *haystack, const char *needle)
{
    char *result;

    begin_search(haystack, needle);
    if (!*needle_argument()) {
single_result_path:
        result = single_result();
        goto done;
    }
    if (!*(needle_argument() + 1)) {
        scan_single_character();
        goto single_result_path;
    }

    scan_haystack_end();
    measure_needle();
    for (;;) {
        if (unsearched_length() < needle_length())
            break;
        if (!find_candidate())
            break;
        if (!compare_candidate()) {
            result = matched_candidate();
            goto done;
        }
        advance_candidate();
    }
    result = no_match();

done:
    return finish_search(result);
}
