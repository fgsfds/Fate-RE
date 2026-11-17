extern unsigned long stack_bottom;

extern unsigned long current_stack_pointer(void);
#pragma aux current_stack_pointer = "mov eax,esp" value [eax] modify exact [eax];

unsigned long stackavail(void);
#pragma aux stackavail modify exact [eax];
unsigned long stackavail(void)
{
    return current_stack_pointer() - stack_bottom;
}
