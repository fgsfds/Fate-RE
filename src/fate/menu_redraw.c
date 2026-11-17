extern unsigned char menu_redraw_pending;

void request_menu_redraw(void)
{
    menu_redraw_pending = 1;
}
