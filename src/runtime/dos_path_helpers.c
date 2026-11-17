extern char copy_byte_in_bl(char);
#pragma aux copy_byte_in_bl = parm [bl] value [bl] modify exact [];
char *copy_c_string(char *dest, const char *source)
{
    char ch;
    for (;;) {
        ch = copy_byte_in_bl(*source);
        *dest = ch;
        if (!ch)
            return dest;
        ++dest;
        ++source;
    }
}

char normalize_separator(char separator, char *saved)
{
    if (separator == '\\' || separator == '/') {
        if (!*saved)
            *saved = separator;
        return *saved;
    }
    return separator;
}

int dos_find_close(void)
{
    return 0;
}

extern unsigned set_directory_search_buffer(void *, void *);
#pragma aux set_directory_search_buffer = "mov ah,1ah" "int 21h" parm [eax] [edx] value [eax] modify exact [eax];
extern unsigned dos_search_next(unsigned);
#pragma aux dos_search_next = "mov ah,4fh" "int 21h" parm [eax] value [eax] modify exact [eax];
extern unsigned copy_caller_to_dta(unsigned, void *);
#pragma aux copy_caller_to_dta modify exact [eax];
extern unsigned copy_dta_to_caller(unsigned, void *);
#pragma aux copy_dta_to_caller modify exact [eax];
/* The DOS interrupt supplies carry to the status translator. */
extern unsigned dos_search_status(unsigned);
#pragma aux dos_search_status modify exact [eax];
extern void *current_directory_record(void);
#pragma aux current_directory_record = value [edx] modify exact [];
unsigned dos_find_next(void *);
#pragma aux dos_find_next modify exact [eax];
unsigned dos_find_next(void *record)
{
    unsigned status = set_directory_search_buffer(record, record);
    status = copy_caller_to_dta(status, current_directory_record());
    status = dos_search_status(dos_search_next(status));
    return copy_dta_to_caller(status, current_directory_record());
}

/* The set-DTA service precedes find-first. Restore the path in DX and
   move the attribute mask into CX before invoking function 4Eh. */
extern unsigned begin_directory_search(const char *, unsigned, void *);
#pragma aux begin_directory_search = "push eax" "push edx" "mov edx,ebx" "mov ah,1ah" "int 21h" "pop ecx" "pop edx" "mov ah,4eh" "int 21h" parm [eax] [edx] [ebx] value [eax] modify exact [eax ecx edx];
extern void *first_directory_record(void);
#pragma aux first_directory_record = value [ebx] modify exact [];
unsigned dos_find_first(const char *, unsigned, void *);
#pragma aux dos_find_first modify exact [eax edx];
unsigned dos_find_first(const char *path, unsigned attributes, void *record)
{
    unsigned status = dos_search_status(begin_directory_search(path, attributes, record));
    return copy_dta_to_caller(status, first_directory_record());
}
