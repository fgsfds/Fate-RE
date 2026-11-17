typedef void (*RuntimeHook)(void);
extern RuntimeHook runtime_hook;
extern unsigned long psp_selector;

RuntimeHook exchange_runtime_hook(RuntimeHook replacement)
{
    RuntimeHook previous = runtime_hook;
    runtime_hook = replacement;
    return previous;
}

unsigned long get_psp_selector(void)
{
    return psp_selector;
}
