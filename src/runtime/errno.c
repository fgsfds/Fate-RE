extern int *get_errno_address(void);
#pragma aux get_errno_address modify exact [eax];
extern int *get_dos_error_address(void);
#pragma aux get_dos_error_address modify exact [eax];
extern void set_errno(int);
#pragma aux set_errno modify exact [eax];
/* Keep these entries around set_errno so Watcom shares its body. */
void set_permission_denied(void)
{
    set_errno(13);
}

void set_errno(int value)
{
    *get_errno_address() = value;
}

void set_bad_address(void)
{
    set_errno(14);
}

void set_runtime_error(int value)
{
    *get_dos_error_address() = value;
}

int bad_file_descriptor(void)
{
    set_errno(9);
    return -1;
}
