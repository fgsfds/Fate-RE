typedef struct SaveStream SaveStream;

extern unsigned fread(void *destination, unsigned size, unsigned count, SaveStream *stream);
extern unsigned fwrite(const void *source, unsigned size, unsigned count, SaveStream *stream);
extern unsigned char crusher_state[0x64c8];
extern short first_player_sprite;

int write_crusher_state(SaveStream *stream)
{
    if (stream == 0)
        return 0;
    fwrite(crusher_state, sizeof(crusher_state), 1, stream);
    return 1;
}

int read_crusher_state(SaveStream *stream)
{
    if (stream == 0)
        return 0;
    fread(crusher_state, sizeof(crusher_state), 1, stream);
    return 1;
}

int is_first_player_sprite(short sprite)
{
    return sprite == first_player_sprite;
}
