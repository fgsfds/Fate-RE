extern int errno_value, dos_error_value;

int *get_errno_address(void)
{
    return &errno_value;
}

int *get_dos_error_address(void)
{
    return &dos_error_value;
}
