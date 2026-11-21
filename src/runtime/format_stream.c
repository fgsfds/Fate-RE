/* Preserve stream status while printf emits characters through its callback. */
typedef struct {
    char *current;
    unsigned pending;
    char *buffer;
    union {
        unsigned word;
        struct { unsigned char status, mode; } bytes;
    } flags;
} FormatStream;

typedef void (*StreamWriter)(void *, int);
extern void stream_format_putc(void *, int);
extern void allocate_stream_buffer(FormatStream *);
#pragma aux allocate_stream_buffer parm [eax] modify exact [eax];
extern int format_engine(FormatStream *, const char *, void *, StreamWriter);
#pragma aux format_engine modify exact [eax ebx ecx edx];
extern void flush_stream(FormatStream *);
#pragma aux flush_stream parm [eax] modify exact [eax];

/* Preserve the formatter's original byte registers and saved status in EBP. */
extern unsigned char begin_stream_format(FormatStream *);
#pragma aux begin_stream_format = "push ebp" "mov esi,eax" "mov ebp,[eax+0ch]" \
    "mov ah,[eax+0ch]" "mov ecx,[esi+8]" "and ah,0cfh" "and ebp,30h" \
    parm [eax] value [ah] modify exact [eax ecx esi];
extern FormatStream *active_stream(void);
#pragma aux active_stream = value [esi] modify exact [];
extern FormatStream *stream_argument(void);
#pragma aux stream_argument = "mov eax,esi" value [eax] modify exact [eax];
extern char *original_buffer(void);
#pragma aux original_buffer = value [ecx] modify exact [];
extern unsigned char read_mode(void);
#pragma aux read_mode = "mov cl,[esi+0dh]" "xor edi,edi" value [cl] modify exact [ecx edi];
extern unsigned char buffered_mode(unsigned char);
#pragma aux buffered_mode = "mov ch,cl" "and ch,0fah" "mov al,ch" parm [cl] value [ch] modify exact [eax ecx];
extern unsigned char use_buffered_mode(void);
#pragma aux use_buffered_mode = "or al,1" "mov edi,1" value [al] modify exact [eax edi];
extern int mode_changed(void);
#pragma aux mode_changed = value [edi] modify exact [];
extern const char *original_format(void);
#pragma aux original_format = value [edx] modify exact [];
extern void *original_arguments(void);
#pragma aux original_arguments = value [ebx] modify exact [];
extern int count_in_edx(int);
#pragma aux count_in_edx = parm [edx] value [edx] modify exact [];
extern void callback_in_ecx(StreamWriter);
#pragma aux callback_in_ecx = parm [ecx] modify exact [];
extern StreamWriter current_callback(void);
#pragma aux current_callback = value [ecx] modify exact [];

extern unsigned char direct_mode(void);
#pragma aux direct_mode = "mov ah,[esi+0dh]" "and ah,0fah" "mov bl,ah" value [ah] modify exact [eax ebx];
extern unsigned char restore_direct_mode(void);
#pragma aux restore_direct_mode = "or bl,4" value [bl] modify exact [ebx];
extern unsigned restore_status_bits(unsigned);
#pragma aux restore_status_bits = "or edi,ebp" parm [edi] value [edi] modify exact [edi];
extern int return_count(void);
#pragma aux return_count = "mov eax,edx" value [eax] modify exact [eax];
extern void restore_status_frame(void);
#pragma aux restore_status_frame = "pop ebp" modify exact [];

int write_stream_format(FormatStream *, const char *, void *);
#pragma aux write_stream_format modify exact [eax ebx edx];
int write_stream_format(FormatStream *stream, const char *format, void *args)
{
    unsigned char mode;
    unsigned status;
    FormatStream *flush_target;
    int count;

    active_stream()->flags.bytes.status = begin_stream_format(stream);
    if (!original_buffer())
        allocate_stream_buffer(active_stream());
    mode = read_mode();
    if (mode & 4) {
        active_stream()->flags.bytes.mode = buffered_mode(mode);
        active_stream()->flags.bytes.mode = use_buffered_mode();
    }

    callback_in_ecx(stream_format_putc);
    count_in_edx(format_engine(stream_argument(), original_format(), original_arguments(), current_callback()));
    if (mode_changed()) {
        active_stream()->flags.bytes.mode = direct_mode();
        mode = restore_direct_mode();
        flush_target = stream_argument();
        active_stream()->flags.bytes.mode = mode;
        flush_stream(flush_target);
    }

    if (active_stream()->flags.bytes.status & 0x20)
        count_in_edx(-1);
    status = restore_status_bits(active_stream()->flags.word);
    count = return_count();
    active_stream()->flags.word = status;
    restore_status_frame();
    return count;
}
