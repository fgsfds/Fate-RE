/* Positional audio-channel update at loaded0x3526c; library interfaces provisional. */
#pragma pack(push, 1)
typedef struct {
    long handle;
    char reserved[10];
    short sprite;
    long x, y, flags;
} AudioSource;
typedef struct { long x, y; char remainder[36]; } AudioSprite;
typedef struct { long volume; char reserved[20]; long pan; char remainder[212]; } AudioChannel;
#pragma pack(pop)
extern unsigned char audio_enabled;
extern long audio_tick, audio_last_tick, audio_listener_x, audio_listener_y, audio_driver;
extern AudioSource *audio_sources[];
extern AudioSprite sprite[];
extern AudioChannel audio_channels[];
extern long audio_volume(long, long), audio_pan(long, long), audio_sprite_pan(long, long);
extern long labs(long);
extern long audio_set_volume(long, long, long), audio_set_pan(long, long, long);

void loop_finish(void)
{
    long i, distance, volume;
    if (!audio_enabled || audio_tick-audio_last_tick < 10) return;
    i = 0;
    do {
        if (audio_sources[i]->handle == -1 || !audio_sources[i]->flags || audio_sources[i]->flags == 16)
            continue;
        if (audio_sources[i]->flags & 1) {
            audio_channels[i].volume = audio_volume(sprite[audio_sources[i]->sprite].x, sprite[audio_sources[i]->sprite].y);
            audio_channels[i].pan = audio_pan(sprite[audio_sources[i]->sprite].x, sprite[audio_sources[i]->sprite].y);
        } else if (audio_sources[i]->flags & 8) {
            distance = labs(audio_listener_x-audio_sources[i]->x) + labs(audio_listener_y-audio_sources[i]->y);
            if (distance < 4000) {
                volume = 32000-distance*8;
                audio_channels[i].volume = volume | (volume << 16);
            } else audio_channels[i].volume = 0;
            audio_channels[i].pan = audio_sprite_pan(sprite[audio_sources[i]->sprite].x, sprite[audio_sources[i]->sprite].y);
        } else {
            audio_channels[i].volume = audio_volume(audio_sources[i]->x, audio_sources[i]->y);
            audio_channels[i].pan = audio_pan(audio_sources[i]->x, audio_sources[i]->y);
        }
        audio_set_volume(audio_driver, audio_sources[i]->handle, audio_channels[i].volume);
        audio_set_pan(audio_driver, audio_sources[i]->handle, audio_channels[i].pan);
    } while (++i < 16);
    audio_last_tick = audio_tick;
}
