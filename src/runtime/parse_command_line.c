/* Count DOS command-line words and optionally split the buffer in place. */
/* Bind C cursor and character operations to the original parser registers. */
extern void input_to_eax(char *);
#pragma aux input_to_eax = "" parm [eax] modify exact [];
extern void output_to_edx(char *);
#pragma aux output_to_edx = "" parm [edx] modify exact [];
extern void following_to_ebx(char *);
#pragma aux following_to_ebx = "" parm [ebx] modify exact [];
extern char *following_from_ebx(void);
#pragma aux following_from_ebx = "" value [ebx] modify exact [];
extern char *word_from_ebp(void);
#pragma aux word_from_ebp = "" value [ebp] modify exact [];
extern char char_to_dl(char);
#pragma aux char_to_dl = "" parm [dl] value [dl] modify exact [];
extern char char_to_bh(char);
#pragma aux char_to_bh = "" parm [bh] value [bh] modify exact [];
extern char char_to_bl(char);
#pragma aux char_to_bl = "" parm [bl] value [bl] modify exact [];
extern char char_to_al(char);
#pragma aux char_to_al = "" parm [al] value [al] modify exact [];
extern void count_to_ecx(unsigned);
#pragma aux count_to_ecx = "" parm [ecx] modify exact [];

extern void begin_parse(char *, char **, char **);
#pragma aux begin_parse = "push ecx" "push esi" "push edi" "push ebp" "sub esp,8" \
    "mov esi,edx" "mov [esp+4],ebx" "xor ecx,ecx" \
    parm [eax] [edx] [ebx] modify exact [ecx esi edi];

extern char **argument_vector(void);
#pragma aux argument_vector = value [esi] modify exact [];
extern char quoted_character(void);
#pragma aux quoted_character = value [bh] modify exact [];
extern char *input_position(void);
#pragma aux input_position = value [eax] modify exact [];
extern void begin_argument(void);
#pragma aux begin_argument = "mov [esp],eax" modify exact [];
extern char *output_position(void);
#pragma aux output_position = value [edx] modify exact [];

extern void prepare_next_word(void);
#pragma aux prepare_next_word = "lea ebp,[eax+1]" modify exact [];
extern unsigned old_count(void);
#pragma aux old_count = "" value [ecx] modify exact [];
extern unsigned count_in_edi(unsigned);
#pragma aux count_in_edi = "" parm [edi] value [edi] modify exact [];
extern void save_argument_pointer(void);
#pragma aux save_argument_pointer = "shl ecx,2" "lea ebx,[esi+ecx]" "mov ecx,[esp]" \
    "mov [ebx],ecx" modify exact [ebx ecx];
extern char **saved_end_slot(void);
#pragma aux saved_end_slot = "mov edx,[esp+4]" value [edx] modify exact [edx];
extern unsigned argument_count(void);
#pragma aux argument_count = "" value [ecx] modify exact [];
extern unsigned finish_parse(unsigned);
#pragma aux finish_parse = "add esp,8" "pop ebp" "pop edi" "pop esi" "pop ecx" \
    parm [eax] value [eax] modify exact [eax];

unsigned parse_command_line(char *, char **, char **);
#pragma aux parse_command_line modify exact [eax ebx ecx edx esi edi];
unsigned parse_command_line(char *input, char **argv, char **end)
{
    char ch, following;
    unsigned count;

    begin_parse(input, argv, end);
skip_whitespace:
    ch = char_to_dl(*input_position());
    if (ch == ' ' || ch == '\t') {
        input_to_eax(input_position() + 1);
        goto skip_whitespace;
    }
    if (!ch)
        goto done;
    if (ch != '"')
        goto unquoted;
    input_to_eax(input_position() + 1);
    begin_argument();
    output_to_edx(input_position());

    for (;;) {
        ch = char_to_bh(*input_position());
        if (ch == '"' || !ch)
            goto finish_argument;
        if (ch == '\\') {
            following = char_to_bl(input_position()[1]);
            if (following == '"' || following == quoted_character())
                input_to_eax(input_position() + 1);
        }
        following_to_ebx(input_position() + 1);
        if (argument_vector()) {
            *output_position() = char_to_al(*input_position());
            input_to_eax(following_from_ebx());
            output_to_edx(output_position() + 1);
        } else {
            input_to_eax(following_from_ebx());
        }
    }

unquoted:
    begin_argument();
    output_to_edx(input_position());
    for (;;) {
        ch = char_to_bl(*input_position());
        if (!ch || ch == ' ' || ch == '\t')
            break;
        if (ch == '\\' && input_position()[1] == '"')
            input_to_eax(input_position() + 1);
        following_to_ebx(input_position() + 1);
        if (argument_vector()) {
            *output_position() = char_to_al(*input_position());
            input_to_eax(following_from_ebx());
            output_to_edx(output_position() + 1);
        } else {
            input_to_eax(following_from_ebx());
        }
    }

finish_argument:
    prepare_next_word();
    count = count_in_edi(old_count() + 1);
    if (argument_vector()) {
        save_argument_pointer();
        ch = char_to_bl(*input_position());
        count_to_ecx(count);
        if (!ch) {
            *output_position() = ch;
            goto done;
        }
        input_to_eax(word_from_ebp());
        *output_position() = 0;
        goto skip_whitespace;
    }
    ch = char_to_dl(*input_position());
    count_to_ecx(count);
    if (ch) {
        input_to_eax(word_from_ebp());
        goto skip_whitespace;
    }
done:
    *saved_end_slot() = input_position();
    return finish_parse(argument_count());
}
