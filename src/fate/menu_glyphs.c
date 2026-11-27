int menu_glyph_tile(unsigned char glyph)
{
    switch (glyph) {
    case '[': return 0x871;
    case '\\': return 0x872;
    case ']': return 0x873;
    }
    if ((int)glyph >= 'A' && (int)glyph <= 'Z')
        return glyph + 0x816;
    if ((int)glyph >= 'a' && (int)glyph <= 'z')
        return glyph + 0x816;
    if ((int)glyph >= '\'' && (int)glyph <= '>')
        return glyph + 0x818;
    if ((int)glyph >= '[')
        return glyph + 0x815;
    return 0;
}
