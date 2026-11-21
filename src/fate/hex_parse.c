extern unsigned strlen(const char *text);
extern int parse_hex_digits(unsigned char character);
#pragma aux parse_hex_digits modify exact [eax];
extern unsigned long hex_place_values[];

unsigned long parse_hexadecimal(const char *text)
{
    /* The caller supplies a nonempty token within the place-value table's range. */
    unsigned remaining = strlen(text);
    unsigned long value = 0;
    unsigned index = 0;

    do {
        value += (unsigned long)parse_hex_digits((unsigned char)text[index++]) * hex_place_values[remaining - 1];
    } while (--remaining > 0);
    return value;
}
