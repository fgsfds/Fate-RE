/* Animation pre-step state update; names describe observed storage roles only. */
extern long prestep_value,prestep_direction,prestep_speed;
extern unsigned char prestep_hold;

void animation_prestep(void)
{
    prestep_value += prestep_direction * prestep_speed;
    if (prestep_value >= 2048) {
        prestep_value = 2048;
        prestep_direction = -1;
    }
    if (prestep_value <= 0) {
        prestep_value = 0;
        prestep_direction = 1;
    }
    if (prestep_hold && prestep_value > 816 && prestep_value < 1232) {
        prestep_value = 1024;
        prestep_direction = 0;
    }
    if (prestep_direction == 0 && !prestep_hold) {
        prestep_value = 1024;
        prestep_direction = 1;
    }
}
