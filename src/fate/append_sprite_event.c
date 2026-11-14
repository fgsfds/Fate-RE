/* Provisional names for the event-table producer consumed by START's hook. */
#pragma pack(push, 1)
typedef struct { short sprite; unsigned short encoded; } SpriteEvent;
#pragma pack(pop)
extern SpriteEvent sprite_events[];
extern short sprite_event_count;
extern char sprite_event_error_buffer[], sprite_event_overflow_text[];
extern int format_sprite_event_error(char *, const char *, ...);
extern void report_sprite_event_error(const char *);

void append_sprite_event(short sprite, unsigned short encoded)
{
    long count;
    count = ++sprite_event_count;
    if (count > 100) {
        format_sprite_event_error(sprite_event_error_buffer, sprite_event_overflow_text);
        report_sprite_event_error(sprite_event_error_buffer);
    }
    sprite_events[sprite_event_count].sprite = sprite;
    sprite_events[sprite_event_count].encoded = encoded;
}
