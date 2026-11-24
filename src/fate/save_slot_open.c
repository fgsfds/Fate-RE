typedef struct RuntimeStream RuntimeStream;

extern const char load_slot_format[], save_slot_format[];
extern const char load_mode[], save_mode[];
extern short player_count, local_player;

extern int format_slot_suffix(char *, const char *, ...);
#pragma aux format_slot_suffix "sprintf_" parm caller [] modify exact [eax];

/* The pinned runtime appends forward, so it supports this destination
 * ending within the already-read portion of the suffix. */
extern char *append_slot_suffix(char *, const char *);
#pragma aux append_slot_suffix "strcat_" parm [eax] [edx] value [eax] modify exact [eax];

extern RuntimeStream *open_slot_file(const char *, const char *);
#pragma aux open_slot_file "fopen_" parm [eax] [edx] value [eax] modify exact [eax edx];

extern unsigned read_slot_header(void *, unsigned, unsigned, RuntimeStream *);
#pragma aux read_slot_header "fread_" parm [eax] [edx] [ebx] [ecx] value [eax] modify exact [eax ebx ecx edx];

extern unsigned write_slot_header(const void *, unsigned, unsigned, RuntimeStream *);
#pragma aux write_slot_header "fwrite_" parm [eax] [edx] [ebx] [ecx] value [eax] modify exact [eax ebx ecx edx];

extern int close_slot_file(RuntimeStream *);
#pragma aux close_slot_file "fclose_" parm [eax] value [eax] modify exact [eax];

extern RuntimeStream *header_stream_in_edi(RuntimeStream *);
#pragma aux header_stream_in_edi = parm [edi] value [edi] modify exact [];

extern RuntimeStream *file_stream_in_esi(RuntimeStream *);
#pragma aux file_stream_in_esi = parm [esi] value [esi] modify exact [];

int save_open_read_slot(int slot);
#pragma aux save_open_read_slot parm [eax] value [eax] modify exact [eax];

int save_open_write_slot(int slot);
#pragma aux save_open_write_slot parm [eax] value [eax] modify exact [eax];
typedef struct {
    char text[9];
} SlotBasename;

typedef struct {
    SlotBasename basename;
    char gap[3];
    char suffix[8];
} SlotFilename;

typedef char SlotFilenameLayout[
    sizeof(SlotBasename) == 9 && sizeof(SlotFilename) == 20 ? 1 : -1
];

extern const SlotBasename load_basename, save_basename;

extern short first_player, next_player[16];
extern long player_x[16], player_y[16];
extern void open_initialize_player(int);
#pragma aux open_initialize_player "initialize_board_entry_" parm [eax] modify exact [eax];
extern void open_set_player(int);
#pragma aux open_set_player = "" parm [edi] modify exact [edi];
extern int open_player(void);
#pragma aux open_player = "" value [edi] modify exact [];

/* These contexts process the real serialized header prefix. The reader
 * initializes connection-list players before loading their coordinates.
 * All nonterminal links are valid indices 0..15 and the chain terminates.
 * Suffix formatting fits its 8-byte member for menu slots 0..9. */
#ifdef SAVE_OPEN_READ
int save_open_read_slot(int slot)
{
    SlotFilename filename;
    RuntimeStream *stream, *header_stream, *file_stream;
    format_slot_suffix(filename.suffix, load_slot_format, slot);
    filename.basename = load_basename;
    append_slot_suffix((char *)&filename, filename.suffix);
    stream = open_slot_file((char *)&filename, load_mode);
    header_stream = header_stream_in_edi(stream);
    file_stream = file_stream_in_esi(stream);
    if (!stream)
        return -1;
    read_slot_header(&player_count, sizeof(player_count), 1, stream);
    read_slot_header(&local_player, sizeof(local_player), 1, header_stream);
    read_slot_header(&first_player, sizeof(first_player), 1, header_stream);
    read_slot_header(next_player, sizeof(next_player), 1, header_stream);
    open_set_player(first_player);
    goto check;
visit:
    open_initialize_player((int)(short)open_player());
    open_set_player(next_player[open_player()]);
check:
    if (open_player() >= 0)
        goto visit;
    read_slot_header(player_x, sizeof(player_x), 1, file_stream);
    return close_slot_file(file_stream);
}
#else
int save_open_write_slot(int slot)
{
    SlotFilename filename;
    RuntimeStream *stream, *header_stream, *file_stream;
    format_slot_suffix(filename.suffix, save_slot_format, slot);
    filename.basename = save_basename;
    append_slot_suffix((char *)&filename, filename.suffix);
    stream = open_slot_file((char *)&filename, save_mode);
    header_stream = header_stream_in_edi(stream);
    file_stream = file_stream_in_esi(stream);
    if (!stream)
        return -1;
    write_slot_header(&player_count, sizeof(player_count), 1, stream);
    write_slot_header(&local_player, sizeof(local_player), 1, header_stream);
    write_slot_header(&first_player, sizeof(first_player), 1, header_stream);
    write_slot_header(next_player, sizeof(next_player), 1, header_stream);
    write_slot_header(player_x, sizeof(player_x), 1, header_stream);
    write_slot_header(player_y, sizeof(player_y), 1, header_stream);
    return close_slot_file(file_stream);
}
#endif
