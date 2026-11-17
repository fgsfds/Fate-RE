typedef struct {
    char *next;
    char fields[12];
    unsigned count;
} FormatSink;

typedef void (*PutCharacter)(FormatSink *, unsigned char);
extern void sprintf_sink_writer(FormatSink *, unsigned char);
#pragma aux sprintf_sink_writer "sprintf_putc_";
extern int format_engine(char *, const char *, char **, PutCharacter);
#pragma aux format_engine modify exact [eax edx ebx ecx];
/* Set up the original stack argument cursor and register-call adapter. */
extern char *keep_arguments(char *);
#pragma aux keep_arguments = parm [eax] value [eax] modify exact [];
extern const char *keep_format(const char *);
#pragma aux keep_format = parm [edx] value [edx] modify exact [];
extern char **keep_argument_slot(char **);
#pragma aux keep_argument_slot = parm [ebx] value [ebx] modify exact [];
extern char *keep_destination(char *);
#pragma aux keep_destination = parm [edx] value [edx] modify exact [];
extern void select_writer(PutCharacter);
#pragma aux select_writer = parm [ecx] modify exact [];
extern PutCharacter current_writer(void);
#pragma aux current_writer = value [ecx] modify exact [];
int sprintf(char *, const char *, ...);
#pragma aux sprintf parm caller [] modify exact [eax];
int sprintf(char *volatile destination, const char *format, ...)
{
    char *first = keep_arguments((char *)(&format + 1));
    const char *pattern = keep_format(*(const char *volatile *)&format);
    char *arguments;
    char **slot = keep_argument_slot(&arguments);
    int count;

    select_writer(sprintf_sink_writer);
    arguments = first;
    count = format_engine(destination, pattern, slot, current_writer());
    keep_destination(destination)[count] = '\0';
    return count;
}
