
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

/* Menu slots are 0..9. Formatting fits the 8-byte suffix and forward append
 * fits the complete 20-byte object. The private second transfer and close
 * retain real stream lifetimes beyond the selected opening/count phases. */
int save_open_read_slot(int slot)
{
    SlotFilename filename;
    RuntimeStream *stream;
    RuntimeStream *header_stream;
    RuntimeStream *file_stream;

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
    return close_slot_file(file_stream);
}

int save_open_write_slot(int slot)
{
    SlotFilename filename;
    RuntimeStream *stream;
    RuntimeStream *header_stream;
    RuntimeStream *file_stream;

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
    return close_slot_file(file_stream);
}

