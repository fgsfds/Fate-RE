/* Reset the second encounter actor and continue into the exit scan. */
extern unsigned char second_actor_kind;
extern short second_trigger_state;
extern unsigned char reset_kind(unsigned char);
#pragma aux reset_kind = "" parm [dh] value [dh] modify exact [];
extern void encounter_exit_scan(void);
#pragma aux encounter_exit_scan aborts modify exact [];
#pragma aux encounter_reset_state aborts modify exact [edx];
void encounter_reset_state(void)
{
    second_actor_kind = reset_kind(0);
    second_trigger_state = 1;
    encounter_exit_scan();
}
