extern char *copy_c_string(char *, const char *);
#pragma aux copy_c_string modify exact [eax edx];
/* Preserve the argument cursor and output registers across the string copy. */
extern const char *const *arguments_in_esi(const char *const *);
#pragma aux arguments_in_esi = parm [esi] value [esi] modify exact [];
extern char *current_tail(void);
#pragma aux current_tail = "" value [ebx] modify exact [];
extern char *tail_in_ebx(char *);
#pragma aux tail_in_ebx = parm [ebx] value [ebx] modify exact [];
extern char *tail_in_edx(char *);
#pragma aux tail_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned char tail_low_byte(void);
#pragma aux tail_low_byte = value [bl] modify exact [];
extern unsigned char length_in_dl(unsigned char);
#pragma aux length_in_dl = parm [dl] value [dl] modify exact [];

void build_command_tail(const char *, const char *const *, char *, int);
#pragma aux build_command_tail modify exact [eax ebx edx];
void build_command_tail(const char *file, const char *const *arguments, char *tail, int plain)
{
    char *volatile original_tail;
    arguments = arguments_in_esi(arguments);
    original_tail = tail;
    if (!plain)
        tail_in_ebx(current_tail() + 1);
    /* Skip argv[0] and join the remaining arguments with spaces. */
    if (*arguments) {
        ++arguments;
        if (*arguments) {
            do {
                char *end = copy_c_string(current_tail(), *arguments);
                ++arguments;
                tail_in_edx(end);
                tail_in_ebx(end);
                if (!*arguments)
                    break;
                tail_in_ebx(end + 1);
                *end = ' ';
            } while (1);
        }
    }
    if (plain) {
        *current_tail() = 0;
        return;
    }
    {
        /* DOS command tails have a length byte and end with a carriage return. */
        unsigned char length = length_in_dl(tail_low_byte());
        *current_tail() = '\r';
        length = length_in_dl(length - (unsigned long)original_tail);
        tail_in_ebx(original_tail);
        length = length_in_dl(length - 1);
        *current_tail() = length;
    }
}
