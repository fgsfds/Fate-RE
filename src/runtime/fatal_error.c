extern unsigned read_data_selector(void);
/* Watcom's assembler only accepts the operand-size-prefixed DX form. */
#pragma aux read_data_selector = 0x8c 0xda value [edx] modify exact [edx];
extern int notify_debugger(const char *, unsigned, int);
#pragma aux notify_debugger parm [eax] [edx] [ecx] modify exact [eax];
extern void write_console_and_exit(const char *, int);
#pragma aux write_console_and_exit modify exact [eax edx];
/* Keep the arguments in the original callee-saved registers across the hook. */
extern void save_error_arguments(const char *, int);
#pragma aux save_error_arguments = parm [ebx] [ecx] modify exact [];
extern const char *incoming_message(void);
#pragma aux incoming_message = value [eax] modify exact [];
extern const char *saved_message(void);
#pragma aux saved_message = value [ebx] modify exact [];
extern int saved_status(void);
#pragma aux saved_status = value [ecx] modify exact [];
extern const char *console_message(const char *);
#pragma aux console_message = parm [eax] value [eax] modify exact [];

void fatal_runtime_error(const char *message, int status)
{
    unsigned selector;
    save_error_arguments(message, status);
    selector = read_data_selector();
    if (!notify_debugger(incoming_message(), selector, saved_status())) {
        const char *text = console_message(saved_message());
        write_console_and_exit(text, saved_status());
    }
}
