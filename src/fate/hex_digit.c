extern const unsigned char *hex_digit_set;
extern int toupper(int character);

int parse_hex_digits(unsigned char character)
{
    unsigned int digit;
    for (digit = 0; digit < 16; ++digit) {
        if (hex_digit_set[digit] == toupper(character))
            return digit;
    }
    return -1;
}
