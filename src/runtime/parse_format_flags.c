typedef struct {
    unsigned char prefix[20];
    unsigned char flags;
    unsigned char size_modifier;
    unsigned char padding;
} FormatFlags;

/* Retain the original byte registers for the two sign flag updates. */
extern unsigned char character_in_bl(unsigned char);
#pragma aux character_in_bl = parm [bl] value [bl] modify exact [];
extern unsigned char flags_in_ch(unsigned char);
#pragma aux flags_in_ch = parm [ch] value [ch] modify exact [];
extern unsigned char flags_in_bh(unsigned char);
#pragma aux flags_in_bh = parm [bh] value [bh] modify exact [];
extern unsigned char flags_in_cl(unsigned char);
#pragma aux flags_in_cl = parm [cl] value [cl] modify exact [];

const char *parse_format_flags(const char *format, FormatFlags *state)
{
    state->flags = 0;
    for (;;) {
        unsigned char character = character_in_bl(*format);
        if (character == '-')
            *(volatile unsigned char *)&state->flags |= 8;
        else if (character == '#')
            *(volatile unsigned char *)&state->flags |= 1;
        else if (character == '+') {
            unsigned char updated = flags_in_ch(state->flags);
            unsigned char without_space;
            updated = flags_in_ch(updated | 4);
            without_space = character_in_bl(updated);
            /* The original writes the plus flag before clearing the space flag. */
            *(volatile unsigned char *)&state->flags = updated;
            without_space = character_in_bl(without_space & ~2);
            state->flags = without_space;
        } else if (character == ' ') {
            unsigned char previous = flags_in_bh(state->flags);
            if (!(previous & 4)) {
                unsigned char updated = flags_in_cl(previous);
                updated = flags_in_cl(updated | 2);
                state->flags = updated;
            }
        } else if (character == '0')
            state->padding = character;
        else
            return format;
        ++format;
    }
}
