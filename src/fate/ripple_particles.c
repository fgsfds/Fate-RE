/* In-place particle phases. Active count is 0..32; creation uses count<32
 * and step=1, while radius update receives an active slot with radius1..10.
 * The three compiler RETs are guarded and remain unlinked. */
extern int ripple_count;
extern int ripple_origin_y[32], ripple_radius[32];

extern unsigned int slot_draw_ebx(unsigned int);
#pragma aux slot_draw_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int slot_index_eax(int);
#pragma aux slot_index_eax = "" parm [eax] value [eax] modify exact [];
extern int slot_next_edi(int);
#pragma aux slot_next_edi = "" parm [edi] value [edi] modify exact [];

int ripple_store_y_slot(unsigned int, int);
#pragma aux ripple_store_y_slot parm [eax] [esi] value [eax] modify exact [eax ebx edi];

/* The original passes one in ESI and an active count in 0..31. The
 * count is the destination slot and EAX retains that slot on exit. */
int ripple_store_y_slot(unsigned int draw, int step)
{
    unsigned int y = slot_draw_ebx(draw);
    int slot = slot_index_eax(*(const volatile int *)&ripple_count);
    int next;

    y = slot_draw_ebx(y & 127U);
    next = slot_next_edi(slot + step);
    ((volatile int *)ripple_origin_y)[slot] = y;
    ((volatile int *)ripple_radius)[slot] = step;
    *(volatile int *)&ripple_count = next;
    return slot;
}

extern int floor_eax(int);
#pragma aux floor_eax = "" parm [eax] value [eax] modify exact [];
void ripple_floor_pixel(unsigned char *);
#pragma aux ripple_floor_pixel parm [ecx] modify exact [eax];
void ripple_floor_pixel(unsigned char *pixel)
{
    if (floor_eax(*pixel) < 192)
        *pixel = 192;
}

extern int ripple_count;
extern int ripple_radius[], ripple_origin_x[], ripple_origin_y[];
extern int radius_ebx(int);
#pragma aux radius_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int radius_esi(int);
#pragma aux radius_esi = "" parm [esi] value [esi] modify exact [];
extern int radius_ecx(int);
#pragma aux radius_ecx = "" parm [ecx] value [ecx] modify exact [];
void ripple_advance_radius(int);
#pragma aux ripple_advance_radius parm [eax] modify exact [eax ebx ecx esi];
void ripple_advance_radius(int slot)
{
    int next = radius_ebx(ripple_radius[slot]);
    ++next;
    ripple_radius[slot] = next;
    if (next > 10) {
        int last = radius_esi(ripple_count - 1);
        int last_x = radius_ecx(ripple_origin_x[last]);
        int last_radius = radius_ebx(ripple_radius[last]);
        int last_y;
        /* Preserve the original removal publication order, including self-copy. */
        *(volatile int *)&ripple_count = last;
        *(volatile int *)&ripple_origin_x[slot] = last_x;
        last_y = radius_ecx(*(const volatile int *)&ripple_origin_y[last]);
        ripple_radius[slot] = last_radius;
        ripple_origin_y[slot] = last_y;
    }
}
