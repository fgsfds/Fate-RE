/* Split a DOS path into NUL-terminated components in the caller's buffer. */
extern char *copy_path_part(char **, char *, const char *, const char *);
#pragma aux copy_path_part modify exact [eax ebx ecx edx];
extern void begin_split(const char *);
#pragma aux begin_split = "push ebp" "mov esi,eax" parm [eax] modify exact [esi edi];
extern const char *initial_path(void);
#pragma aux initial_path = value [eax] modify exact [];
extern const char *scan_position(void);
#pragma aux scan_position = value [esi] modify exact [];
extern char **drive_result(void);
#pragma aux drive_result = value [ebx] modify exact [];
extern char *split_buffer(void);
#pragma aux split_buffer = value [edx] modify exact [];
extern char read_path_byte(void);
#pragma aux read_path_byte = "mov al,[esi]" value [al] modify exact [eax];
extern void advance_past_drive(void);
#pragma aux advance_past_drive = "add esi,2" modify exact [esi];
extern void advance_split_buffer(void);
#pragma aux advance_split_buffer = "inc edx" modify exact [edx];
extern void advance_drive_buffer(void);
#pragma aux advance_drive_buffer = "add edx,3" modify exact [edx];
extern void begin_components(void);
#pragma aux begin_components = "mov ebp,esi" "mov ebx,esi" modify exact [ebx];
extern void reset_extension(unsigned long zero);
#pragma aux reset_extension = "" parm [edi] modify exact [];
extern void advance_split_path(void);
#pragma aux advance_split_path = "inc esi" modify exact [esi];
extern void mark_extension(void);
#pragma aux mark_extension = "mov edi,esi" modify exact [edi];
extern void mark_directory_end(void);
#pragma aux mark_directory_end = "mov ebp,esi" modify exact [];
extern const char *extension_start(void);
#pragma aux extension_start = value [edi] modify exact [];
extern const char *path_begin(void);
#pragma aux path_begin = value [ebx] modify exact [];
extern char **directory_result(void);
#pragma aux directory_result = "mov eax,ecx" value [eax] modify exact [eax];
extern const char *directory_end(void);
#pragma aux directory_end = value [ebp] modify exact [];
extern char *continued_buffer(char *);
#pragma aux continued_buffer = "mov edx,eax" parm [eax] value [edx] modify exact [edx];
extern char **basename_result(void);
#pragma aux basename_result = "mov eax,[esp+10h]" value [eax] modify exact [eax];
extern char **extension_result(void);
#pragma aux extension_result = "mov eax,[esp+14h]" value [eax] modify exact [eax];
extern void load_basename_endpoints(void);
#pragma aux load_basename_endpoints = "mov ebx,ebp" "mov ecx,edi" modify exact [ebx ecx];
extern void load_extension_endpoints(void);
#pragma aux load_extension_endpoints = "mov ebx,edi" "mov ecx,esi" modify exact [ebx ecx];
extern const char *component_start(void);
#pragma aux component_start = value [ebx] modify exact [];
extern const char *component_end(void);
#pragma aux component_end = value [ecx] modify exact [];
extern void end_split(void);
#pragma aux end_split = "pop ebp" modify exact [];

char *split_path(const char *, char *, char **, char **, char **, char **);
#pragma aux split_path modify exact [eax ebx ecx edx];
char *split_path(const char *path, char *out, char **drive, char **directory,
                 char **basename, char **extension)
{
    char ch, *next;
    char **part;

    begin_split(path);
    if (*initial_path() && scan_position()[1] == ':') {
        if (drive_result()) {
            *drive_result() = split_buffer();
            ch = read_path_byte();
            split_buffer()[1] = ':';
            split_buffer()[2] = '\0';
            split_buffer()[0] = ch;
            advance_drive_buffer();
        }
        advance_past_drive();
    } else if (drive_result()) {
        *drive_result() = split_buffer();
        *split_buffer() = '\0';
        advance_split_buffer();
    }

    begin_components();
reset_component:
    reset_extension(0);
    for (;;) {
        ch = read_path_byte();
        if (!ch)
            break;
        if (ch == '.') {
            mark_extension();
            advance_split_path();
        } else {
            advance_split_path();
            if (ch == '\\' || ch == '/') {
                mark_directory_end();
                goto reset_component;
            }
        }
    }

    part = directory_result();
    next = continued_buffer(copy_path_part(part, split_buffer(), path_begin(), directory_end()));
    if (!extension_start())
        mark_extension();
    part = basename_result();
    load_basename_endpoints();
    next = continued_buffer(copy_path_part(part, next, component_start(), component_end()));
    load_extension_endpoints();
    part = extension_result();
    next = copy_path_part(part, next, component_start(), component_end());
    end_split();
    return next;
}

void path_noop(void)
{
}

/* Assemble the components using the first slash style found in the input. */
extern char normalize_separator(unsigned, char *);
#pragma aux normalize_separator parm [eax] [edx] modify exact [eax];

extern void begin_path_output(char *);
#pragma aux begin_path_output = "mov edi,[esp+10h]" "mov esi,eax" \
    parm [eax] modify exact [eax esi edi];
extern char blank_separator(void);
#pragma aux blank_separator = "xor ah,ah" value [ah] modify exact [eax];
extern char *path_output(void);
#pragma aux path_output = value [esi] modify exact [];
extern void next_output_byte(void);
#pragma aux next_output_byte = "inc esi" modify exact [esi];
extern void previous_output_byte(void);
#pragma aux previous_output_byte = "dec esi" modify exact [esi];
extern const char *drive_input(void);
#pragma aux drive_input = value [edx] modify exact [];
extern char read_drive(void);
#pragma aux read_drive = "mov al,[edx]" value [al] modify exact [eax];
extern const char *directory_input(void);
#pragma aux directory_input = value [ebx] modify exact [];
extern void read_directory_byte(void);
#pragma aux read_directory_byte = "xor eax,eax" "mov edx,esp" "mov al,[ebx]" "inc ebx" modify exact [eax ebx edx];
extern char next_directory_byte(void);
#pragma aux next_directory_byte = "mov dl,[ebx]" value [dl] modify exact [edx];
extern unsigned current_separator_input(void);
#pragma aux current_separator_input = value [eax] modify exact [];
extern char *separator_buffer(void);
#pragma aux separator_buffer = value [edx] modify exact [];
extern char read_separator_in_bh(void);
#pragma aux read_separator_in_bh = "mov bh,[esp]" value [bh] modify exact [ebx];
extern char read_separator_in_dh(void);
#pragma aux read_separator_in_dh = "mov dh,[esp]" value [dh] modify exact [edx];
extern char read_separator_in_dl(void);
#pragma aux read_separator_in_dl = "mov dl,[esp]" value [dl] modify exact [edx];
extern const char *basename_input(void);
#pragma aux basename_input = value [ecx] modify exact [];
extern void prepare_after_separator(void);
#pragma aux prepare_after_separator = "lea ebx,[esi+1]" modify exact [ebx];
extern void skip_separator(void);
#pragma aux skip_separator = "mov esi,ebx" modify exact [esi];
extern void read_basename_start(void);
#pragma aux read_basename_start = "xor eax,eax" "mov edx,esp" "mov al,[ecx]" modify exact [eax edx];
extern char next_basename_byte(void);
#pragma aux next_basename_byte = "mov dl,[ecx]" value [dl] modify exact [edx];
extern unsigned normalize_next_base_byte(void);
#pragma aux normalize_next_base_byte = "xor eax,eax" "mov al,dl" "mov edx,esp" "inc ecx" \
    value [eax] modify exact [eax ecx edx];
extern const char *extension_input(void);
#pragma aux extension_input = value [edi] modify exact [];
extern char first_extension_byte(void);
#pragma aux first_extension_byte = "mov dh,[edi]" value [dh] modify exact [edx];
extern char next_extension_byte(void);
#pragma aux next_extension_byte = "mov bh,[edi]" value [bh] modify exact [ebx];
extern void advance_extension(void);
#pragma aux advance_extension = "inc edi" modify exact [edi];

void make_path(char *, const char *, const char *, const char *, const char *);
#pragma aux make_path modify exact [eax ebx ecx edx];
void make_path(char *out, const char *drive, const char *directory, const char *base,
               const char *extension)
{
    /* The original keeps the selected slash style in a one-byte stack slot. */
    volatile char saved_slash;
    char separator, current;
    unsigned input;

    begin_path_output(out);
    saved_slash = blank_separator();
    if (drive_input()) {
        current = read_drive();
        if (current) {
            *path_output() = current;
            next_output_byte();
            *path_output() = ':';
            next_output_byte();
        }
    }

    *path_output() = '\0';
    if (directory_input() && *directory_input()) {
        do {
            read_directory_byte();
            *path_output() = normalize_separator(current_separator_input(), separator_buffer());
            current = next_directory_byte();
            next_output_byte();
        } while (current);
        if (!saved_slash)
            saved_slash = '\\';
        separator = read_separator_in_bh();
        if (separator == path_output()[-1])
            previous_output_byte();
        else
            *path_output() = separator;
    }
    if (!saved_slash)
        saved_slash = '\\';

    prepare_after_separator();
    if (basename_input()) {
        read_basename_start();
        current = normalize_separator(current_separator_input(), separator_buffer());
        separator = read_separator_in_dh();
        if (current != separator && separator == *path_output())
            skip_separator();
        for (;;) {
            if (!next_basename_byte())
                break;
            input = normalize_next_base_byte();
            current = normalize_separator(input, separator_buffer());
            *path_output() = current;
            next_output_byte();
        }
    } else if (read_separator_in_dl() == *path_output()) {
        skip_separator();
    }

    if (extension_input()) {
        current = first_extension_byte();
        if (current) {
            if (current == '.')
                goto copy_extension;
            *path_output() = '.';
advance_extension_output:
            next_output_byte();
copy_extension:
            current = next_extension_byte();
            if (current) {
                advance_extension();
                *path_output() = current;
                goto advance_extension_output;
            }
        }
    }
    *path_output() = '\0';
}
