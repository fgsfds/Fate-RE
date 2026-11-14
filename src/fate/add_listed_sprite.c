/* Provisional names for the inverse of the listed-sprite removal helper. */
#pragma pack(push, 1)
typedef struct { char unknown[42]; short extra; } ListedSprite;
#pragma pack(pop)
extern ListedSprite listed_sprite_records[];
extern short listed_sprite_count, listed_sprites[];
extern char listed_sprite_error_buffer[], listed_sprite_overflow_text[];
extern int format_listed_sprite_error(char *, const char *, ...);
extern void report_listed_sprite_error(const char *);

void add_listed_sprite(short sprite)
{
    long count;
    count = ++listed_sprite_count;
    if (count > 1023) {
        format_listed_sprite_error(listed_sprite_error_buffer, listed_sprite_overflow_text);
        report_listed_sprite_error(listed_sprite_error_buffer);
    }
    listed_sprite_records[sprite].extra |= 0x4000;
    listed_sprites[listed_sprite_count] = sprite;
}
