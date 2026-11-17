typedef struct {
    char *next;
    char fields[12];
    unsigned count;
} FormatSink;

void sprintf_putc(FormatSink *sink, unsigned char ch)
{
    *sink->next++ = ch;
    ++sink->count;
}
