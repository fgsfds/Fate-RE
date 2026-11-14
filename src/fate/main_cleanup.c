/* Runtime-registered callback at loaded0x10010; callee role remains provisional. */
extern void main_run(void);
extern long main_finished;
extern char main_cleanup_message[];
extern int printf(const char *, ...);

void main_prepare_callback(void)
{
    main_run();
    if (!main_finished) printf(main_cleanup_message);
}
