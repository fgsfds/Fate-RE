extern char *ultoa(unsigned long, char *, int);
#pragma aux ultoa modify exact [eax edx ebx];
char *ltoa(long number, char *dst, int radix)
{
    char *result = dst;
    if (radix == 10 && number < 0) {
        number = (long)(-(unsigned long)number);
        *dst++ = '-';
    }
    ultoa(number, dst, radix);
    return result;
}

typedef struct {
    char *next;
    char fields[12];
    unsigned count;
} FormatSink;
typedef void (*PutCharacter)(FormatSink *, unsigned char);

/* Emit the callback address as an external CODE relocation. */
extern void format_sink_writer(FormatSink *, unsigned char);
#pragma aux format_sink_writer "vsprintf_putc_";
extern int format_engine(char *destination, const char *format, void *args, PutCharacter);
#pragma aux format_engine modify exact [eax edx ebx ecx];

int vsprintf(char *destination, const char *format, void *args)
{
    int count = format_engine(destination, format, args, format_sink_writer);
    destination[count] = '\0';
    return count;
}

void vsprintf_putc(FormatSink *sink, unsigned char ch)
{
    *sink->next++ = ch;
    ++sink->count;
}

typedef struct {
    void *stream;
    char fields[12];
    unsigned count;
} StreamFormatSink;

extern int fputc(int, void *);
#pragma aux fputc modify exact [eax edx];
void stream_format_putc(StreamFormatSink *, int);
#pragma aux stream_format_putc modify exact [eax edx];
void stream_format_putc(StreamFormatSink *sink, int character)
{
    fputc(character, sink->stream);
    ++sink->count;
}
