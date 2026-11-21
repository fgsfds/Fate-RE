extern unsigned long argument_workspace_size;
extern unsigned char *argument_workspace_end;
extern int argc_value;
extern char **argv_pointer;
extern unsigned long stackavail(void);
#pragma aux stackavail modify exact [eax];
extern void common_init(void);
#pragma aux common_init modify exact [eax];
extern int game_main(int, char **);
#pragma aux game_main modify exact [eax edx];
extern void runtime_exit(int);
#pragma aux runtime_exit modify exact [eax];
/* Keep the dynamic area live through the CRT and game entry calls.
   Watcom keeps the C locals in registers while this frame is active. */
extern void *reserve_argument_workspace(unsigned);
#pragma aux reserve_argument_workspace = "sub esp,eax" "mov eax,esp" parm [eax] value [eax] modify exact [eax];
extern void save_stack_frame(void);
#pragma aux save_stack_frame = "push ebp" "mov ebp,esp" modify exact [];
extern void restore_stack_frame(void);
#pragma aux restore_stack_frame = "mov esp,ebp" "pop ebp" modify exact [];

extern unsigned long size_in_edx(unsigned long);
#pragma aux size_in_edx = parm [edx] value [edx] modify exact [];

void runtime_main(void);
#pragma aux runtime_main "__CMain" modify exact [eax];
void runtime_main(void)
{
    unsigned long size;
    unsigned char *workspace;
    save_stack_frame();
    size = size_in_edx(argument_workspace_size);
    size = size_in_edx(size + 3);
    size = size_in_edx(size & ~3UL);
    if (size < stackavail())
        workspace = reserve_argument_workspace(size);
    else
        workspace = 0;
    argument_workspace_end = (unsigned char *)((unsigned long)workspace + argument_workspace_size);
    common_init();
    runtime_exit(game_main(argc_value, argv_pointer));
    restore_stack_frame();
}
