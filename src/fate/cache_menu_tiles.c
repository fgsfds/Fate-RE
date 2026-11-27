extern long waloff[];
extern void loadtile(int);
#pragma aux loadtile modify exact [eax];
extern void loadtile_tail(int);
#pragma aux loadtile_tail "loadtile_" aborts modify exact [eax];
extern void menu_return(void);
#pragma aux menu_return aborts modify exact [];

void cache_menu_tiles(void)
{
    if (!waloff[0x824])
        loadtile(0x824);
    if (!waloff[0x825])
        loadtile(0x825);
    if (!waloff[0x826])
        loadtile(0x826);
    if (!waloff[0x827])
        loadtile(0x827);
    if (!waloff[0x81f])
        loadtile(0x81f);
    if (!waloff[0x820])
        loadtile(0x820);

    /* The cached path uses the menu's shared RET instruction. */
    if (waloff[0x821])
        menu_return();
    loadtile_tail(0x821);
}
