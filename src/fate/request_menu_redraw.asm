; Request menu redraw.
BITS 32
ORG 0x38800

menu_redraw_pending equ 0x1314f

request_menu_redraw:
    mov byte [menu_redraw_pending], 0x1
    ret
