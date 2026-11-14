/* Provisional reconstruction of the template-based sprite creation helper.
 * The original makes no insertion-failure check; do not add one for matching.
 */
#pragma pack(push, 1)
typedef struct {
    short cstat;
    signed char shade;
    unsigned char pal, clipdist, xrepeat, yrepeat;
    signed char xoffset, yoffset;
    short picnum, ang, xvel, yvel, zvel, owner, statnum, lotag, hitag, extra, type;
} SpriteTemplate;
typedef struct {
    long x, y, z;
    short cstat, picnum;
    signed char shade;
    unsigned char pal, clipdist, filler, xrepeat, yrepeat;
    signed char xoffset, yoffset;
    short sectnum, statnum, ang, owner, xvel, yvel, zvel, lotag, hitag, extra;
} GameSprite;
typedef struct { long x, y, z; } SpritePosition;
#pragma pack(pop)
extern SpriteTemplate sprite_templates[];
extern GameSprite game_sprites[];
extern SpritePosition sprite_old_positions[];
extern unsigned char sprite_visibility[];
extern short insert_template_sprite(short, short);
#include "copybuf.h"

short spawn_template_sprite(short type, const SpritePosition *position, short sector)
{
    short sprite;
    GameSprite *s;
    sprite = insert_template_sprite(sector, sprite_templates[type].statnum);
    s = &game_sprites[sprite];
    s->x = position->x;
    s->y = position->y;
    s->z = position->z;
    s->cstat = sprite_templates[type].cstat;
    s->shade = sprite_templates[type].shade;
    s->pal = sprite_templates[type].pal;
    s->clipdist = sprite_templates[type].clipdist;
    s->xrepeat = sprite_templates[type].xrepeat;
    s->yrepeat = sprite_templates[type].yrepeat;
    s->xoffset = sprite_templates[type].xoffset;
    s->yoffset = sprite_templates[type].yoffset;
    s->picnum = sprite_templates[type].picnum;
    s->ang = sprite_templates[type].ang;
    s->xvel = sprite_templates[type].xvel;
    s->yvel = sprite_templates[type].yvel;
    s->zvel = sprite_templates[type].zvel;
    s->owner = sprite_templates[type].owner;
    s->lotag = sprite_templates[type].lotag;
    s->hitag = sprite_templates[type].hitag;
    s->extra = sprite_templates[type].extra;
    copybuf(s, &sprite_old_positions[sprite], 3);
    sprite_visibility[sprite >> 3] &= ~(1 << (sprite & 7));
    return sprite;
}
