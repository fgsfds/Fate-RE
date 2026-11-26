; Update the scripted encounter, sprite triggers and exit state.
BITS 32
ORG 0x1de8e
section .text align=1

random_value equ 0x602d0
play_sound equ 0x34f79
sprite_tile equ 0x2040ae
sprite_y equ 0x2040a4
sprite_x equ 0x2040a0
sprite_xrepeat equ 0x2040b2
ticks_per_step equ 0x7a994
sprite_yrepeat equ 0x2040b5
advance_clock equ 0x229b
update_sector equ 0x542c4
update_actor_common equ 0x14897
encounter_clock equ 0x12814
first_trigger_state equ 0x127f4
second_trigger_state equ 0x127f6
encounter_parameters equ 0x127f8
exit_scan_initialized equ 0x12806
exit_trigger_state equ 0x12808
trigger_count equ 0x3be6
trigger_sprite equ 0x77124
sprite_hitag equ 0x2040c8
sprite_lotag equ 0x2040c6
sprite_shade_field equ 0x2040b4
encounter_actor_field equ 0x7dec0
encounter_position equ 0x729e0
first_trigger_sprite equ 0x7494e
second_trigger_sprite equ 0x74950
exit_sector_type equ 0x7659c
exit_sector_index equ 0x7659e
encounter_sprite_index equ 0x7db36
first_actor_state equ 0x7e32b
second_actor_state equ 0x7e32c
first_actor_kind equ 0x7f0de
second_actor_kind equ 0x7f0df
first_actor_mode equ 0x7f6bd
second_actor_mode equ 0x7f6be
exit_scan_index equ 0x851a8
tile_width equ 0x1f2020
sector_lotag equ 0x27c3c2
sector_count equ 0x289154
spawn_sprite_at_position equ 0x11073
add_listed_sprite equ 0x134c2
check_encounter_condition equ 0x10610
delete_sprite equ 0x50a09
update_sprite_sequence_state equ 0x10433
activate_sector equ 0x28710

spawn_positions:
    dd -10240, -6400
    dd -9728, -5632
    dd -8960, -5376
    dd -7936, -5888
    dd -7424, -5376
    dd -9984, -7168
    dd -8704, -6656
    dd -7936, -7424
    dd -7424, -7168
    dd -10752, -9216
    dd -10240, -8192
    dd -6912, -8448
    dd -9984, -9728
    dd -7680, -9728
    dd -8704, -10240
    dd -9216, -10752

spawn_counts:
    times 2 db 60
    times 4 db 30
    times 16 db 15
    times 10 db 7

update_level_encounter equ 0x1df2e
; Compiler-generated C supplies both EBP slots and selected spawn phases.
.inspect_encounter_trigger equ 0x1df83
.clear_sector_tag equ 0x1e012
.advance_sector equ 0x1e034
.check_sector_index equ 0x1e035
.advance_trigger equ 0x1e03e
.check_trigger_index equ 0x1e03f
.advance_encounter equ 0x1e04c
.prepare_spawn_loop equ 0x1e070
.spawn_encounter_sprite equ 0x1e086
.check_spawn_count equ 0x1e199
.check_first_trigger_sprite equ 0x1e1b0


section .spawn_0 align=1 vstart=0x1e08f follows=.text
    and dl, 0xf
    movsx ebx, dx
    mov eax, [esp + ebx*8]

section .spawn_1 align=1 vstart=0x1e09f follows=.spawn_0
    mov eax, [esp + ebx*8 + 0x4]

section .spawn_2 align=1 vstart=0x1e0f0 follows=.spawn_1
    and dl, 0x1
    add edx, strict dword 0x350
    mov [esi + sprite_tile], dx

section .spawn_3 align=1 vstart=0x1e162 follows=.spawn_2
    mov ax, [nosplit eax*2 + tile_width]

section .spawn_4 align=1 vstart=0x1e170 follows=.spawn_3
    movsx ebx, ax

section .spawn_5 align=1 vstart=0x1e175 follows=.spawn_4
    mov al, dl
    imul ebx
    shrd eax, edx, byte 0x7
