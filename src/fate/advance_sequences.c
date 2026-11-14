/* Provisional names for the original active object-sequence advancement pass. */
#pragma pack(push, 1)
typedef struct {
    char before_picnum[14];
    short picnum;
    char before_lotag[22];
    short lotag;
    char rest[4];
} SequenceSprite;
typedef struct {
    short start, end, final, next;
    short remaining_fields[56];
} ObjectSequence;
#pragma pack(pop)
extern SequenceSprite sequence_sprites[];
extern ObjectSequence object_sequences[];
extern short active_sequence_count, active_sequence_sprites[];
extern void sequence_remove_sprite(short);

void advance_sequences(void)
{
    short i, sprite, sequence;
    for (i = 1; i <= active_sequence_count; i++) {
        sprite = active_sequence_sprites[i];
        sequence = (sequence_sprites[sprite].lotag & 0xff00) >> 8;
        sequence_sprites[sprite].picnum++;
        if (sequence_sprites[sprite].picnum > object_sequences[sequence].end) {
            if (object_sequences[sequence].final) {
                sequence_sprites[sprite].lotag &= 255;
                sequence_sprites[sprite].picnum = object_sequences[sequence].final;
                sequence_sprites[sprite].lotag |= object_sequences[sequence].next << 8;
            } else
                sequence_remove_sprite(sprite);
            active_sequence_sprites[i] = active_sequence_sprites[active_sequence_count];
            active_sequence_count--;
        }
    }
}
