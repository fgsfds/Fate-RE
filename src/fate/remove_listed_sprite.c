/* Provisional names for the original helper called by the START map hook.
 * Remove the sprite, then compact every matching entry by taking the last slot.
 * The loop deliberately continues forward after replacement.
 */
extern short listed_sprite_count, listed_sprites[];
extern int remove_engine_sprite(short);

void remove_listed_sprite(short sprite)
{
    short i;
    remove_engine_sprite(sprite);
    for (i = 1; i <= listed_sprite_count; i++)
        if (listed_sprites[i] == sprite) {
            listed_sprites[i] = listed_sprites[listed_sprite_count];
            listed_sprite_count--;
        }
}
