/* The original call sites enter five bytes into this function, at RET 8. */
#pragma aux disabled_positioned_sound parm [] routine value [eax] modify exact [eax];
int disabled_positioned_sound(int first_stack_arg, int second_stack_arg)
{
    return -1;
}
