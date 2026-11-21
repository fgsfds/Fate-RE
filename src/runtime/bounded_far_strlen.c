/* Register ABI for the segmented scan used by the format engine. */
extern unsigned keep_offset(unsigned);
#pragma aux keep_offset = parm [edx] value [edx] modify exact [];
extern unsigned keep_count(unsigned);
#pragma aux keep_count = parm [eax] value [eax] modify exact [];
extern unsigned current_selector(void);
#pragma aux current_selector = "" value [esi] modify exact [];
extern unsigned current_limit(void);
#pragma aux current_limit = "" value [edi] modify exact [];
extern unsigned current_offset(void);
#pragma aux current_offset = "" value [edx] modify exact [];
extern unsigned current_length(void);
#pragma aux current_length = "" value [eax] modify exact [];
extern void begin_scan(unsigned, unsigned);
#pragma aux begin_scan = "mov esi,edx" "mov edi,ebx" parm [edx] [ebx] modify exact [esi edi];
/* Read one byte through the caller-supplied segment selector. */
extern unsigned char far_byte(unsigned, unsigned);
#pragma aux far_byte = "mov es,si" "mov ebx,edx" "mov cl,es:[ebx]" parm [esi] [edx] value [cl] modify exact [ebx ecx es];

unsigned bounded_far_strlen(unsigned, unsigned, unsigned);
#pragma aux bounded_far_strlen modify exact [eax ebx edx];
unsigned bounded_far_strlen(unsigned offset, unsigned selector, unsigned limit)
{
    begin_scan(selector, limit);
    keep_offset(offset);
    keep_count(0);
    for (;;) {
        unsigned char ch = far_byte(current_selector(), current_offset());
        keep_offset(current_offset() + 1);
        if (!ch)
            break;
        if (current_length() == current_limit())
            break;
        keep_count(current_length() + 1);
    }
    return current_length();
}

/* Watcom shares the narrow scan epilogue with the wide scan. */
extern unsigned word_scan_selector(void);
#pragma aux word_scan_selector = "" value [ecx] modify exact [];
extern unsigned word_scan_limit(void);
#pragma aux word_scan_limit = "" value [esi] modify exact [];
extern void begin_word_scan(unsigned, unsigned);
#pragma aux begin_word_scan = "mov ecx,edx" "mov esi,ebx" parm [edx] [ebx] modify exact [ecx esi];
extern unsigned short far_word(unsigned, unsigned);
#pragma aux far_word = "mov es,cx" "mov ebx,edx" 0x66 "mov edi,es:[ebx]" parm [ecx] [edx] value [di] modify exact [ebx edi es];

unsigned bounded_far_wcslen(unsigned, unsigned, unsigned);
#pragma aux bounded_far_wcslen modify exact [eax ebx edx];
unsigned bounded_far_wcslen(unsigned offset, unsigned selector, unsigned limit)
{
    begin_word_scan(selector, limit);
    keep_offset(offset);
    keep_count(0);
    for (;;) {
        unsigned short ch = far_word(word_scan_selector(), current_offset());
        keep_offset(current_offset() + 2);
        if (!ch || current_length() == word_scan_limit())
            break;
        keep_count(current_length() + 1);
    }
    return current_length();
}
