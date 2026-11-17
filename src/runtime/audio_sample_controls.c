/* The digital driver library stores sample records in a fixed DOS layout. */
typedef struct AudioSample {
    long source, cursor;
    char reserved08[0x1c - 8];
    long identifier;
    char reserved20;
    unsigned char flags;
    char reserved22[6];
    long handle;
    long field_2c, field_30, field_34;
    char reserved38[12];
    long field_44, field_48;
    char reserved4c[12];
    long field_58;
    char reserved5c[0xec - 0x5c];
    struct AudioSample *next;
} AudioSample;

typedef struct AudioDriver {
    char reserved[0x14];
    unsigned sample_count;
    char reserved18[4];
    long field_1c;
    char reserved20[0x30 - 0x20];
    AudioSample *queue;
    char reserved34[0x54 - 0x34];
    long field_54;
    AudioSample *samples;
} AudioDriver;

extern AudioDriver *audio_driver_slots[];

/* In this unoptimized unit, listing GS suppresses Watcom's unused GS save. */
enum { SAMPLE_ACTIVE = 0x80, SAMPLE_STOP_PENDING = 0x40, INVALID_SAMPLE = 10 };

#define SAMPLE_GETTER(name, field, require_active) \
    long name(unsigned slot, unsigned index) \
    { \
        AudioDriver *driver = audio_driver_slots[slot]; \
        AudioSample *sample; \
        if (driver == 0) \
            return INVALID_SAMPLE; \
        sample = driver->samples + index; \
        if (sample == 0) \
            return INVALID_SAMPLE; \
        if (require_active) { \
            if (sample->flags & SAMPLE_ACTIVE) \
                return sample->field; \
            return INVALID_SAMPLE; \
        } \
        return sample->field; \
    }

#define SAMPLE_SETTER(name, field, delayed_return) \
    long name(unsigned slot, unsigned index, long value) \
    { \
        AudioDriver *driver = audio_driver_slots[slot]; \
        AudioSample *sample; \
        long previous; \
        if (driver == 0) \
            return INVALID_SAMPLE; \
        sample = driver->samples + index; \
        if (sample == 0) \
            return INVALID_SAMPLE; \
        if (sample->flags & SAMPLE_ACTIVE) { \
            previous = sample->field; \
            sample->field = value; \
            if (!delayed_return) \
                return previous; \
        } else { \
            return INVALID_SAMPLE; \
        } \
        return previous; \
    }

#define DRIVER_GETTER(name, field) \
    long name(unsigned slot) \
    { \
        AudioDriver *driver = audio_driver_slots[slot]; \
        if (driver == 0) \
            return INVALID_SAMPLE; \
        return driver->field; \
    }

extern void service_driver(AudioDriver *);
#pragma aux service_driver "service_driver_" parm caller [] modify exact [eax];

extern void *sample_copy(void *, const void *, unsigned);
#pragma aux sample_copy "memcpy_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];

void service_audio_driver_0(void);
#pragma aux service_audio_driver_0 modify exact [eax gs];
void service_audio_driver_0(void)
{
    service_driver(audio_driver_slots[0]);
}

void service_audio_driver_1(void);
#pragma aux service_audio_driver_1 modify exact [eax gs];
void service_audio_driver_1(void)
{
    service_driver(audio_driver_slots[1]);
}

void service_audio_driver_2(void);
#pragma aux service_audio_driver_2 modify exact [eax gs];
void service_audio_driver_2(void)
{
    service_driver(audio_driver_slots[2]);
}

void service_audio_driver_3(void);
#pragma aux service_audio_driver_3 modify exact [eax gs];
void service_audio_driver_3(void)
{
    service_driver(audio_driver_slots[3]);
}

void service_audio_driver_4(void);
#pragma aux service_audio_driver_4 modify exact [eax gs];
void service_audio_driver_4(void)
{
    service_driver(audio_driver_slots[4]);
}

void audio_noop_62185(void);
#pragma aux audio_noop_62185 modify exact [eax gs];
void audio_noop_62185(void)
{
}

void audio_noop_6219f(void);
#pragma aux audio_noop_6219f modify exact [eax gs];
void audio_noop_6219f(void)
{
}

long queue_audio_sample(unsigned, const AudioSample *);
#pragma aux queue_audio_sample parm [eax] [edx] modify exact [eax edx gs];
long queue_audio_sample(unsigned slot, const AudioSample *source)
{
    unsigned index;
    AudioSample *tail;
    AudioDriver *driver = audio_driver_slots[slot];

    if (driver == 0)
        return INVALID_SAMPLE;
    for (index = 0; index < driver->sample_count; ++index) {
        if (!(driver->samples[index].flags & SAMPLE_ACTIVE))
            break;
    }
    if (index == driver->sample_count)
        return -1;

    sample_copy(&driver->samples[index], source, sizeof(*source));
    driver->samples[index].cursor = source->source;
    driver->samples[index].handle = index;
    tail = driver->queue;
    if (tail == 0) {
        driver->samples[index].next = 0;
        driver->samples[index].flags |= SAMPLE_ACTIVE;
        driver->queue = &driver->samples[index];
    } else {
        while (tail->next != 0)
            tail = tail->next;
        driver->samples[index].next = 0;
        driver->samples[index].flags |= SAMPLE_ACTIVE;
        tail->next = &driver->samples[index];
    }
    return index;
}

long request_sample_stop(unsigned, unsigned);
#pragma aux request_sample_stop parm [eax] [edx] modify exact [eax edx gs];
long request_sample_stop(unsigned slot, unsigned index)
{
    AudioDriver *driver = audio_driver_slots[slot];
    if (driver == 0)
        return INVALID_SAMPLE;
    if (!(driver->samples[index].flags & SAMPLE_ACTIVE))
        return 0;
    driver->samples[index].flags |= SAMPLE_STOP_PENDING;
    return 0;
}

long request_all_samples_stop(unsigned);
#pragma aux request_all_samples_stop parm [eax] modify exact [eax gs];
long request_all_samples_stop(unsigned slot)
{
    AudioDriver *driver = audio_driver_slots[slot];
    unsigned index;
    if (driver == 0)
        return INVALID_SAMPLE;
    for (index = 0; index < driver->sample_count; ++index)
        driver->samples[index].flags |= SAMPLE_STOP_PENDING;
    return 0;
}

void audio_noop_62414(void);
#pragma aux audio_noop_62414 modify exact [eax gs];
void audio_noop_62414(void)
{
}

void audio_noop_62429(void);
#pragma aux audio_noop_62429 modify exact [eax gs];
void audio_noop_62429(void)
{
}

long read_driver_field_1c(unsigned);
#pragma aux read_driver_field_1c parm [eax] modify exact [eax gs];
DRIVER_GETTER(read_driver_field_1c, field_1c)

long set_sample_field_2c(unsigned, unsigned, long);
#pragma aux set_sample_field_2c parm [eax] [edx] [ebx] modify exact [eax ebx edx gs];
SAMPLE_SETTER(set_sample_field_2c, field_2c, 1)

long get_sample_field_2c(unsigned, unsigned);
#pragma aux get_sample_field_2c parm [eax] [edx] modify exact [eax edx gs];
SAMPLE_GETTER(get_sample_field_2c, field_2c, 1)

long get_sample_field_58(unsigned, unsigned);
#pragma aux get_sample_field_58 parm [eax] [edx] modify exact [eax edx gs];
SAMPLE_GETTER(get_sample_field_58, field_58, 1)

long get_sample_field_30(unsigned, unsigned);
#pragma aux get_sample_field_30 parm [eax] [edx] modify exact [eax edx gs];
SAMPLE_GETTER(get_sample_field_30, field_30, 1)

long set_sample_field_44(unsigned, unsigned, long);
#pragma aux set_sample_field_44 parm [eax] [edx] [ebx] modify exact [eax ebx edx gs];
SAMPLE_SETTER(set_sample_field_44, field_44, 0)

long get_sample_field_44(unsigned, unsigned);
#pragma aux get_sample_field_44 parm [eax] [edx] modify exact [eax edx gs];
SAMPLE_GETTER(get_sample_field_44, field_44, 1)

long set_sample_field_34(unsigned, unsigned, long);
#pragma aux set_sample_field_34 parm [eax] [edx] [ebx] modify exact [eax ebx edx gs];
SAMPLE_SETTER(set_sample_field_34, field_34, 0)

long get_sample_field_34(unsigned, unsigned);
#pragma aux get_sample_field_34 parm [eax] [edx] modify exact [eax edx gs];
SAMPLE_GETTER(get_sample_field_34, field_34, 1)

long get_sample_field_48(unsigned, unsigned);
#pragma aux get_sample_field_48 parm [eax] [edx] modify exact [eax edx gs];
SAMPLE_GETTER(get_sample_field_48, field_48, 1)

long get_sample_identifier(unsigned, unsigned);
#pragma aux get_sample_identifier parm [eax] [edx] modify exact [eax edx gs];
SAMPLE_GETTER(get_sample_identifier, identifier, 0)

long find_sample_by_identifier(unsigned, long);
#pragma aux find_sample_by_identifier parm [eax] [edx] modify exact [eax edx gs];
long find_sample_by_identifier(unsigned slot, long identifier)
{
    AudioDriver *driver = audio_driver_slots[slot];
    unsigned index;
    if (driver == 0)
        return INVALID_SAMPLE;
    for (index = 0; index < driver->sample_count; ++index)
        if (driver->samples[index].identifier == identifier)
            return driver->samples[index].handle;
    return -1;
}

long read_driver_field_54(unsigned);
#pragma aux read_driver_field_54 parm [eax] modify exact [eax gs];
DRIVER_GETTER(read_driver_field_54, field_54)

long sample_is_inactive(unsigned, unsigned);
#pragma aux sample_is_inactive parm [eax] [edx] modify exact [eax edx gs];
long sample_is_inactive(unsigned slot, unsigned index)
{
    AudioDriver *driver = audio_driver_slots[slot];
    AudioSample *sample;
    if (driver == 0)
        return INVALID_SAMPLE;
    sample = driver->samples + index;
    if (sample == 0)
        return INVALID_SAMPLE;
    return (sample->flags & SAMPLE_ACTIVE) == 0 ? 1 : 0;
}

void audio_noop_62a82(void);
#pragma aux audio_noop_62a82 modify exact [eax gs];
void audio_noop_62a82(void)
{
}
