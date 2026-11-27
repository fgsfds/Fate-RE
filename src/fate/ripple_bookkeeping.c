/* Count is 0..3 on body entry; the step in ESI is one. The old ECX
 * and step remain live across the original two selected instructions. */
int ripple_spawn_countdown(int, int);
#pragma aux ripple_spawn_countdown parm [ecx] [esi] value [ebp] modify exact [];

int ripple_spawn_countdown(int count, int step)
{
    return count - step;
}

extern int ripple_origin_y[32];

int ripple_radial_set_slot(int);
#pragma aux ripple_radial_set_slot parm [eax] value [ebp] modify exact [];

int ripple_radial_set_slot(int slot)
{
    return slot;
}

/* The radial setup enters with the selected slot in EBP. Its checked
 * body preserves that register until this handoff replaces it with Y. */
extern int ripple_radial_slot_ebp(void);
#pragma aux ripple_radial_slot_ebp = "" parm [] value [ebp] modify exact [];

int ripple_radial_load_y(void);
#pragma aux ripple_radial_load_y parm [] value [ebp] modify exact [];

int ripple_radial_load_y(void)
{
    return ripple_origin_y[ripple_radial_slot_ebp()];
}

int ripple_row_reset(void);
#pragma aux ripple_row_reset parm [] value [ebp] modify exact [];

int ripple_row_reset(void)
{
    return 0;
}

/* Instruction-aligned handoffs within animate_ripple_texture. Pointer
 * results refer to the same live tile/plane objects as their inputs. */
const unsigned char *ripple_tile_register(const unsigned char *);
#pragma aux ripple_tile_register parm [eax] value [edx] modify exact [];
const unsigned char *ripple_tile_register(const unsigned char *tile) { return tile; }
int ripple_spawn_step(void);
#pragma aux ripple_spawn_step parm [] value [esi] modify exact [];
int ripple_spawn_step(void) { return 1; }
unsigned char *ripple_output_tile(unsigned char *);
#pragma aux ripple_output_tile parm [edx] value [esi] modify exact [];
unsigned char *ripple_output_tile(unsigned char *tile) { return tile; }
const unsigned char *ripple_stencil_center(const unsigned char *);
#pragma aux ripple_stencil_center parm [ecx] value [ebx] modify exact [];
const unsigned char *ripple_stencil_center(const unsigned char *cursor) { return cursor; }
const unsigned char *ripple_stencil_next1(const unsigned char *);
#pragma aux ripple_stencil_next1 parm [ecx] value [ebx] modify exact [];
const unsigned char *ripple_stencil_next1(const unsigned char *cursor) { return cursor+1; }
unsigned int ripple_first_lane(unsigned int);
#pragma aux ripple_first_lane parm [eax] value [edi] modify exact [];
unsigned int ripple_first_lane(unsigned int raw_sum) { return raw_sum; }
const unsigned char *ripple_stencil_next2(const unsigned char *);
#pragma aux ripple_stencil_next2 parm [ecx] value [ebx] modify exact [];
const unsigned char *ripple_stencil_next2(const unsigned char *cursor) { return cursor+2; }
const unsigned char *ripple_stencil_next3(const unsigned char *);
#pragma aux ripple_stencil_next3 parm [ecx] value [ebx] modify exact [];
const unsigned char *ripple_stencil_next3(const unsigned char *cursor) { return cursor+3; }
