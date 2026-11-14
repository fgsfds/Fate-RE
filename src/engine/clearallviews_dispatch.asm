; Dispatch CODE offsets indexed by the video backend.
BITS 32
ORG 0x5d08a

clear_vga_planes equ 0x5d135
clear_paged_display equ 0x5d14f
clear_linear_frame equ 0x5d1ae
clear_port_3cd_banks equ 0x5d1cb
clear_graphics_controller_banks equ 0x5d1ed
clear_crtc_banks equ 0x5d216
service_timer equ 0x5d23d

clearallviews_dispatch:
    dd clear_vga_planes - 0x10000
    dd clear_paged_display - 0x10000
    dd clear_linear_frame - 0x10000
    dd clear_port_3cd_banks - 0x10000
    dd clear_graphics_controller_banks - 0x10000
    dd clear_crtc_banks - 0x10000
    dd service_timer - 0x10000
    dd service_timer - 0x10000
