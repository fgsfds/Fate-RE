/* The legacy continuations do not return to these private contexts. */
extern void ripple_particle_continue(void);
#pragma aux ripple_particle_continue parm [] aborts modify exact [];
void ripple_particle_guard(int);
#pragma aux ripple_particle_guard parm [eax] modify exact [];
void ripple_particle_guard(int index)
{
    if(index>=0) ripple_particle_continue();
}

int ripple_sample_step(int);
#pragma aux ripple_sample_step parm [esi] value [esi] modify exact [];
int ripple_sample_step(int sample) { return sample-1; }

extern void ripple_sample_continue(void);
#pragma aux ripple_sample_continue parm [] aborts modify exact [];
void ripple_sample_guard(int);
#pragma aux ripple_sample_guard parm [esi] modify exact [];
void ripple_sample_guard(int sample)
{
    if(sample>=0) ripple_sample_continue();
}

extern void ripple_spawn_continue(void);
#pragma aux ripple_spawn_continue parm [] aborts modify exact [];
void ripple_spawn_guard(int);
#pragma aux ripple_spawn_guard parm [ecx] modify exact [];
void ripple_spawn_guard(int count)
{
    if(count>=0) ripple_spawn_continue();
}

extern int ripple_count;
int ripple_last_slot(void);
#pragma aux ripple_last_slot parm [] value [eax] modify exact [eax];
int ripple_last_slot(void) { return ripple_count-1; }

/* The original RNG changes only EAX. A result in EBX requires a genuine
 * call rather than a tail jump. The selected CALL keeps the original
 * in-place EAX draw; the already restored coordinate phases copy it. */
extern unsigned int ripple_rng(void);
#pragma aux ripple_rng "random_value_" parm [] value [eax] modify exact [eax];
unsigned int ripple_random_draw(void);
#pragma aux ripple_random_draw parm [] value [ebx] modify exact [eax];
unsigned int ripple_random_draw(void) { return ripple_rng(); }
