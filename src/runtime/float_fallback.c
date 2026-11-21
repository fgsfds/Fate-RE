extern int common_init_value;
extern const char float_support_message[];
extern void fatal_float_error(int, const char *);
#pragma aux fatal_float_error "fatal_runtime_error_" parm [edx] [eax] modify exact [eax edx];
void __CommonInit(void)
{
    common_init_value = 0x8000;
}

void float_support_missing(void);
#pragma aux float_support_missing modify exact [eax];
void float_support_missing(void)
{
    fatal_float_error(1, float_support_message);
}
