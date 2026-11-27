; Initialize actor slots and write the startup configuration for each board.
; Store order follows the original register allocation and preserves storage aliases.
BITS 32
ORG 0x1e91a

actor_destination_x equ 0x729fc
actor_destination_y equ 0x72a00
actor_destination_parameter_one equ 0x72a04
actor_destination_parameter_two equ 0x72a08
saved_actor_x equ 0x772c4
saved_actor_y equ 0x772c8
actor_first_waypoint equ 0x78a40
actor_z_offset equ 0x79214
actor_base_tile equ 0x7abc0
mode_one_tile equ 0x7abc2
mode_two_tile equ 0x7abc4
mode_three_tile equ 0x7abc6
mode_four_tile equ 0x7abc8
mode_five_tile equ 0x7abca
mode_six_tile equ 0x7abcc
actor_health equ 0x7cefa
saved_actor_lotag equ 0x7d6ce
actor_sequence_initial equ 0x7e4e2
actor_profile equ 0x7e8cc
actor_board equ 0x7eac1
actor_enabled equ 0x7ecb6
actor_projectile_type equ 0x7eeab
actor_mode equ 0x7f67f
first_actor_mode equ 0x7f6bd
second_actor_mode equ 0x7f6be

%macro actor_tile_index 2
    mov %1, %2
    shl %1, byte 3
    add %1, %2
%endmacro

%macro actor_destination_index 1
    movsx %1, ax
    shl %1, byte 4
%endmacro

section .text align=1
initialize_board_actors equ 0x1e91a
; Fully guarded C operations own the omitted ranges.
.disable_slot equ 0x1e926
.check_slot equ 0x1e930

section .retained_0 align=1 vstart=0x1e91a follows=.text
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov cl, 0xff
    xor eax, eax
    jmp short .check_slot
    movsx edx, ax
    inc eax
    mov [edx + actor_enabled], cl
    movsx edx, ax
    cmp edx, strict dword 0x1f4
    jng short .disable_slot
    mov ah, 0x5
    mov dl, 0x1
    mov ebx, 0xffffea00
    mov edi, 0x3e8
    xor ecx, ecx
    xor esi, esi

section .retained_1 align=1 vstart=0x1e959 follows=.retained_0
    mov [0x772d4], ebx
    mov [actor_z_offset + 1*4], ecx
    mov [mode_one_tile + 1*18], si
    mov [mode_five_tile + 1*18], si
    mov [mode_six_tile + 1*18], si
    mov [actor_first_waypoint + 1*4], si
    mov [actor_health + 2*2], di
    mov edx, 0xffffc400
    mov bl, 0x3
    mov cl, 0x2
    mov ah, 0x10
    xor esi, esi
    xor edi, edi
    mov [0x772d0], edx
    mov [actor_projectile_type + 1], bl
    mov [actor_mode + 1], cl

section .retained_2 align=1 vstart=0x1e9c1 follows=.retained_1
    mov [actor_z_offset + 2*4], esi
    mov [actor_sequence_initial + 2], ah
    mov [actor_destination_x + 2*16], esi
    mov [actor_destination_y + 2*16], edi
    mov [actor_destination_parameter_one + 2*16], esi
    mov dh, 0x10
    mov ebx, 0x2e65
    mov ecx, 0xa02
    mov eax, 0x1a65
    mov esi, 0x1a65
    mov edi, 0xa70
    mov [actor_sequence_initial + 1], dh
    mov [saved_actor_lotag + 1*2], bx
    mov [actor_base_tile + 1*18], cx
    mov [mode_two_tile + 1*18], cx
    mov [mode_three_tile + 1*18], cx
    mov [mode_four_tile + 1*18], cx
    mov [saved_actor_lotag + 2*2], ax
    mov [saved_actor_lotag + 3*2], si
    mov [actor_base_tile + 3*18], di
    mov [mode_two_tile + 3*18], di
    mov [mode_three_tile + 3*18], di
    mov [mode_four_tile + 3*18], di
    mov edx, 0x3e8
    mov bh, 0x1
    mov ch, 0x2
    xor eax, eax
    xor esi, esi
    mov [actor_health + 1*2], dx
    mov [actor_profile + 1], bh
    mov [actor_enabled + 2], ch
    mov [actor_board + 2], bh
    mov [actor_mode + 2], ch
    mov [actor_destination_parameter_two + 2*16], eax
    mov [actor_enabled + 3], ch
    mov [actor_z_offset + 3*4], eax
    mov [mode_five_tile + 3*18], si
    mov edx, 0xffffda00
    mov ebx, 0xffffe900
    mov cl, 0x1
    xor al, al
    mov [0x772dc], edx
    mov [0x772e0], ebx
    mov [actor_board + 3], cl
    mov [actor_projectile_type + 3], al
    mov ch, 0x10
    mov ah, 0x1
    xor dl, dl
    xor ebx, ebx
    mov [actor_projectile_type + 2], dl
    mov [mode_one_tile + 2*18], bx
    mov [mode_five_tile + 2*18], bx
    mov [mode_six_tile + 2*18], bx
    mov [actor_first_waypoint + 2*4], bx
    mov [actor_sequence_initial + 3], ch
    mov [actor_profile + 3], ah
    mov dh, 0x1
    mov ebx, 0x6a00
    mov ecx, 0x3e8
    xor ah, ah
    mov [actor_profile + 2], dh
    mov edx, 0xa70
    mov [0x772ec], ebx
    mov [actor_base_tile + 2*18], dx
    mov [mode_two_tile + 2*18], dx
    mov [mode_three_tile + 2*18], dx
    mov [mode_four_tile + 2*18], dx
    mov edx, 0x300
    mov [actor_health + 3*2], cx
    mov [0x772e8], edx
    mov dl, 0x2
    mov [mode_one_tile + 3*18], ax
    mov [actor_mode + 3], dl
    mov bl, 0x1
    mov edi, 0x8f8
    mov [mode_six_tile + 3*18], si
    mov [actor_first_waypoint + 3*4], ax
    mov [actor_health + 4*2], cx
    mov [actor_enabled + 5], al
    xor dh, dh
    mov cl, 0x2
    mov eax, 0x565
    mov [actor_enabled + 4], dh
    mov [actor_board + 4], bl
    mov [mode_two_tile + 4*18], di
    mov [mode_three_tile + 4*18], di
    mov [mode_four_tile + 4*18], di
    xor esi, esi
    mov edx, 0xffffbf00
    mov ebx, 0x200
    mov edi, 0x3e8
    mov [actor_destination_x + 3*16], esi
    mov [actor_destination_y + 3*16], esi
    mov [actor_destination_parameter_one + 3*16], esi
    mov [actor_destination_parameter_two + 3*16], esi
    mov [actor_z_offset + 4*4], esi
    mov [actor_projectile_type + 4], cl
    mov [saved_actor_lotag + 5*2], ax
    mov ch, 0x1
    mov al, 0x2
    mov [0x772f4], edx
    mov [0x772f8], ebx
    mov [actor_health + 5*2], di
    mov [actor_health + 21*2], di
    mov bh, 0x10
    mov dl, 0x1
    mov [actor_profile + 4], ch
    mov [actor_mode + 4], cl
    mov [actor_board + 21], al
    mov ecx, 0x966
    mov ah, 0x10
    mov [actor_sequence_initial + 4], bh
    mov [actor_board + 5], dl
    mov ebx, 0x565
    mov edx, 0xffffe200
    mov [actor_base_tile + 4*18], cx
    mov esi, ecx
    mov [mode_one_tile + 4*18], cx
    mov [mode_five_tile + 4*18], cx
    mov [mode_six_tile + 4*18], cx
    mov [actor_base_tile + 5*18], cx
    mov [mode_one_tile + 5*18], cx
    mov [actor_sequence_initial + 21], ah
    mov [actor_projectile_type + 21], al
    mov [saved_actor_lotag + 4*2], bx
    mov [0x77300], edx
    xor esi, ecx
    mov ebx, 0xffffff00
    mov dh, 0x10
    mov [actor_first_waypoint + 4*4], si
    mov [0x77304], ebx
    mov [actor_sequence_initial + 5], dh
    xor esi, esi
    mov bl, 0x2
    mov [actor_destination_x + 4*16], esi
    mov [actor_destination_y + 4*16], esi
    mov [actor_destination_parameter_one + 4*16], esi
    mov [actor_destination_parameter_two + 4*16], esi
    mov [actor_z_offset + 5*4], esi
    mov edx, ecx
    mov [actor_destination_x + 5*16], esi
    mov [actor_destination_y + 5*16], esi
    mov [actor_destination_parameter_one + 5*16], esi
    mov [actor_destination_parameter_two + 5*16], esi
    mov [actor_z_offset + 21*4], esi
    mov esi, 0x565
    mov [actor_projectile_type + 5], bl
    mov [mode_five_tile + 5*18], dx
    mov [mode_six_tile + 5*18], dx
    mov bh, 0x1
    mov [saved_actor_lotag + 21*2], si
    mov [actor_profile + 5], bh
    mov [actor_mode + 5], bl
    mov ebx, ecx
    mov ecx, 0x8f8
    xor ebx, edx
    mov edx, 0x100
    mov [mode_two_tile + 5*18], cx
    mov [mode_three_tile + 5*18], cx
    mov [mode_four_tile + 5*18], cx
    mov [actor_first_waypoint + 5*4], bx
    mov ebx, 0x5600
    mov [0x773c0], edx
    xor ch, ch
    mov dh, 0x1
    mov [actor_enabled + 21], ch
    mov [0x773c4], ebx
    mov [actor_profile + 21], dh
    mov edi, 0x966
    mov bh, 0x4
    mov cl, 0x3
    mov ebp, 0x91a5
    mov [actor_mode + 21], dh
    xor esi, esi
    mov edx, 0x8f8
    mov [actor_base_tile + 21*18], di
    mov eax, edi
    mov [mode_one_tile + 21*18], di
    mov [mode_five_tile + 21*18], di
    mov [mode_six_tile + 21*18], di
    mov [actor_destination_x + 21*16], esi
    mov [actor_destination_y + 21*16], esi
    mov [actor_destination_parameter_one + 21*16], esi
    mov [actor_destination_parameter_two + 21*16], esi
    mov [actor_enabled + 41], bh
    mov [actor_board + 41], cl
    mov [actor_z_offset + 41*4], esi
    mov [actor_destination_parameter_one + 41*16], ebp
    mov ebx, 0x92a0
    mov ch, 0x8
    mov esi, 0x6c5a
    mov [mode_two_tile + 21*18], dx
    mov [mode_three_tile + 21*18], dx
    mov [mode_four_tile + 21*18], dx
    xor eax, edi
    xor ebp, ebp
    mov edx, 0x6c5a
    mov edi, 0x92a0
    mov [actor_first_waypoint + 21*4], ax
    mov [0x774b4], ebx
    mov [actor_sequence_initial + 41], ch
    mov [actor_destination_x + 41*16], esi
    mov [actor_destination_parameter_one + 42*16], ebp
    mov al, 0x1
    mov ebx, 0x765
    mov ecx, 0x9b8
    mov esi, 0x3e8
    mov [0x774b0], edx
    mov [actor_destination_y + 41*16], edi
    mov [actor_destination_parameter_two + 41*16], edi
    mov edx, 0x3e8
    mov edi, 0x865
    mov [actor_projectile_type + 41], al
    mov [saved_actor_lotag + 41*2], bx
    mov [actor_base_tile + 41*18], cx
    mov [mode_one_tile + 41*18], cx
    mov [mode_two_tile + 41*18], cx
    mov [mode_three_tile + 41*18], cx
    mov [mode_four_tile + 41*18], cx
    mov [mode_five_tile + 41*18], cx
    mov [actor_health + 42*2], si
    mov ah, 0x2
    mov bl, 0x3
    mov [actor_health + 41*2], dx
    mov [saved_actor_lotag + 42*2], di
    xor esi, esi
    mov dl, 0x5
    mov [actor_profile + 41], ah
    mov [actor_board + 42], bl
    mov [actor_destination_x + 42*16], esi
    mov [actor_destination_parameter_two + 42*16], esi
    xor edi, edi
    mov ebx, 0x7a00
    mov [actor_mode + 41], dl
    mov eax, ecx
    mov [actor_destination_y + 42*16], edi
    mov dh, 0x4
    mov [0x774c0], ebx
    mov [actor_base_tile + 42*18], ax
    mov [mode_one_tile + 42*18], ax
    mov [mode_two_tile + 42*18], ax
    mov [mode_three_tile + 42*18], ax
    mov [mode_four_tile + 42*18], ax
    mov [mode_five_tile + 42*18], ax
    xor ecx, ecx
    mov bh, 0x5
    mov [actor_first_waypoint + 41*4], cx
    mov [actor_enabled + 42], dh
    xor eax, eax
    mov edx, 0x9400
    mov [actor_sequence_initial + 42], bh
    mov [actor_first_waypoint + 42*4], ax
    xor ecx, ecx
    mov ah, 0x4
    mov ebx, 0x7a00
    mov [0x774bc], edx
    mov [actor_z_offset + 42*4], ecx
    mov cl, 0x1
    mov dl, 0x3
    mov [actor_enabled + 43], ah
    mov [0x774cc], ebx
    mov [actor_projectile_type + 42], cl
    mov [actor_board + 43], dl
    mov ch, 0x2
    mov edx, 0x6de8
    mov [actor_profile + 42], ch
    mov [actor_mode + 42], ch
    mov [0x774c8], edx
    mov dh, 0x5
    mov ebx, 0x965
    mov [actor_z_offset + 43*4], esi
    mov [actor_projectile_type + 43], cl
    mov [actor_profile + 43], ch
    mov [actor_mode + 43], ch
    mov [actor_destination_x + 43*16], esi
    mov [actor_destination_y + 43*16], edi
    mov [actor_destination_parameter_one + 43*16], ebp
    mov [actor_z_offset + 61*4], esi
    xor eax, eax
    mov ecx, 0x9b8
    mov esi, 0x3e8
    mov edi, 0x1165
    mov ebp, 0xfffff700
    mov [actor_sequence_initial + 43], dh
    mov [saved_actor_lotag + 43*2], bx
    mov [actor_destination_parameter_two + 43*16], eax
    mov edx, 0x3e8
    mov al, 0x4
    mov ebx, 0xfffff700
    mov [actor_base_tile + 43*18], cx
    mov [mode_one_tile + 43*18], cx
    mov [mode_two_tile + 43*18], cx
    mov [mode_three_tile + 43*18], cx
    mov [mode_four_tile + 43*18], cx
    mov [mode_five_tile + 43*18], cx
    mov [actor_health + 61*2], si
    mov [saved_actor_lotag + 61*2], di
    mov [actor_destination_y + 61*16], ebp
    mov edi, 0xffffda00
    mov [actor_health + 43*2], dx
    mov [actor_board + 61], al
    mov [0x775a4], ebx
    xor ecx, ecx
    xor esi, esi
    mov edx, 0xffffda00
    mov ah, 0x10
    mov bl, 0x5
    mov [actor_first_waypoint + 43*4], cx
    mov [actor_destination_x + 61*16], edi
    mov [actor_z_offset + 62*4], esi
    mov edi, 0x8f8
    mov [0x775a0], edx
    mov [actor_sequence_initial + 61], ah
    mov [actor_mode + 61], bl
    xor ch, ch
    mov dl, 0x2
    mov eax, 0x966
    mov ebx, 0x8f8
    mov [actor_enabled + 61], ch
    mov [mode_two_tile + 62*18], di
    mov [mode_three_tile + 62*18], di
    mov [mode_four_tile + 62*18], di
    mov ecx, 0x1c48
    mov [actor_projectile_type + 61], dl
    mov [actor_base_tile + 61*18], ax
    mov [mode_one_tile + 61*18], ax
    mov [mode_two_tile + 61*18], bx
    mov [mode_three_tile + 61*18], bx
    mov [mode_four_tile + 61*18], bx
    mov [mode_five_tile + 61*18], ax
    xor edi, edi
    mov dh, 0x1
    mov [0x775a8], ecx
    mov [actor_destination_x + 62*16], edi
    mov [actor_destination_y + 62*16], edi
    xor eax, eax
    xor bh, bh
    mov cl, 0x4
    mov [actor_profile + 61], dh
    mov [actor_first_waypoint + 61*4], ax
    mov [actor_enabled + 62], bh
    mov eax, 0xffffa180
    mov edx, 0xfffff780
    mov ebx, 0x1400
    mov [actor_board + 62], cl
    mov ecx, 0x1200
    mov [actor_destination_parameter_one + 61*16], eax
    mov [actor_destination_parameter_two + 61*16], edx
    mov [0x775ac], ebx
    mov edx, 0x3e8
    mov al, 0x2
    mov ebx, 0x565
    mov [0x775b0], ecx
    mov ch, 0x10
    mov [actor_health + 62*2], dx
    mov [actor_projectile_type + 62], al
    mov [saved_actor_lotag + 62*2], bx
    mov ah, 0x1
    mov dl, 0x6
    mov [actor_sequence_initial + 62], ch
    mov ecx, 0x966
    mov [actor_profile + 62], ah
    mov [first_actor_mode], dl
    mov [actor_base_tile + 62*18], cx
    mov esi, ecx
    mov [mode_one_tile + 62*18], cx
    mov [mode_five_tile + 62*18], cx
    xor esi, ecx
    mov [mode_six_tile + 62*18], cx
    mov [actor_first_waypoint + 62*4], si
    mov bl, 0x4
    mov ecx, 0x13c0
    mov ebp, 0x13c0
    mov esi, 0x1c00
    mov [actor_destination_parameter_one + 62*16], edi
    mov [actor_destination_parameter_two + 62*16], edi
    mov [actor_z_offset + 63*4], edi
    xor eax, eax
    xor edx, edx
    mov edi, 0x3e8
    mov [actor_board + 63], bl
    mov [0x775bc], ecx
    mov [actor_destination_y + 63*16], ebp
    mov [0x775cc], esi
    xor dh, ah
    mov ebx, 0x23c0
    mov cl, 0x2
    mov eax, 0x1365
    mov esi, 0x565
    mov [actor_enabled + 63], dh
    mov [actor_health + 63*2], di
    xor ebp, ebp
    mov edx, 0x966
    mov edi, 0x23c0
    mov [0x775b8], ebx
    mov [actor_projectile_type + 63], cl
    mov [saved_actor_lotag + 63*2], ax
    mov [saved_actor_lotag + 64*2], si
    mov [actor_destination_x + 64*16], ebp
    mov [actor_destination_y + 64*16], ebp
    mov [actor_destination_parameter_one + 64*16], ebp
    mov [actor_destination_parameter_two + 64*16], ebp
    mov [0x775d4], ebp
    mov [actor_z_offset + 65*4], ebp
    mov [saved_actor_lotag + 65*2], si
    mov bh, 0x10
    mov ch, 0x1
    mov [actor_base_tile + 63*18], dx
    mov [mode_one_tile + 63*18], dx
    mov [mode_five_tile + 63*18], dx
    mov [mode_six_tile + 63*18], dx
    mov [actor_destination_x + 63*16], edi
    xor al, al
    mov edx, 0x1cc0
    mov [actor_sequence_initial + 63], bh
    mov [actor_profile + 63], ch
    mov [second_actor_mode], al
    xor edi, edi
    mov ecx, 0x8f8
    mov ebx, 0x5
    mov eax, 0x3980
    mov [actor_destination_parameter_two + 63*16], edx
    mov [actor_z_offset + 64*4], edi
    mov dl, 0x4
    mov edi, 0x966
    mov [mode_two_tile + 63*18], cx
    mov [mode_three_tile + 63*18], cx
    mov [mode_four_tile + 63*18], cx
    mov [actor_first_waypoint + 63*4], bx
    mov [actor_destination_parameter_one + 63*16], eax
    mov ebx, 0xffffd400
    mov ecx, 0x100
    mov [actor_board + 64], dl
    mov [actor_base_tile + 64*18], di
    mov [mode_one_tile + 64*18], di
    mov [mode_five_tile + 64*18], di
    xor ah, ah
    mov dh, 0x10
    mov edi, 0xd
    mov [actor_enabled + 64], ah
    mov [0x775c4], ebx
    mov [0x775c8], ecx
    mov ecx, 0x3e8
    mov bl, 0x2
    mov al, 0x4
    mov [actor_sequence_initial + 64], dh
    mov [actor_first_waypoint + 64*4], di
    mov edx, 0x8f8
    mov edi, 0x1c00
    mov [actor_health + 64*2], cx
    mov [actor_projectile_type + 64], bl
    mov [actor_board + 65], al
    mov bh, 0x1
    mov cl, 0x3
    mov ah, 0x10
    mov [mode_two_tile + 64*18], dx
    mov [mode_three_tile + 64*18], dx
    mov [mode_four_tile + 64*18], dx
    mov [0x775d8], edi
    mov [mode_two_tile + 65*18], dx
    mov [actor_profile + 64], bh
    mov [actor_mode + 64], cl
    mov [actor_sequence_initial + 65], ah
    mov [actor_projectile_type + 65], bl
    mov [actor_profile + 65], bh
    mov eax, 0x3e8
    xor ch, ch
    mov bl, 0x3
    mov [actor_enabled + 65], ch
    mov [actor_health + 65*2], ax
    mov [actor_mode + 65], bl
    mov ecx, 0xffffe700
    mov ebx, 0x966
    mov [0x775d0], ecx
    mov [actor_base_tile + 65*18], bx
    mov [mode_one_tile + 65*18], bx
    mov cl, 0x4
    mov esi, 0xffffde00
    mov edi, 0x1280
    mov [mode_three_tile + 65*18], dx
    mov [mode_four_tile + 65*18], dx
    mov [mode_five_tile + 65*18], bx
    mov [actor_destination_x + 65*16], ebp
    mov [actor_destination_y + 65*16], ebp
    mov [actor_destination_parameter_one + 65*16], ebp
    mov [actor_destination_parameter_two + 65*16], ebp
    xor eax, eax
    mov ebx, 0x12
    mov ebp, 0x1c00
    mov dl, 0x3
    mov [actor_board + 66], cl
    mov [0x775dc], esi
    mov [0x775e0], edi
    mov [actor_z_offset + 66*4], eax
    mov ch, 0x10
    mov esi, 0x565
    mov edi, 0x966
    mov [actor_first_waypoint + 65*4], bx
    mov [0x775e4], ebp
    mov [actor_mode + 66], dl
    mov edx, 0x8f8
    mov ebp, 0x1980
    mov [actor_sequence_initial + 66], ch
    mov [saved_actor_lotag + 66*2], si
    mov [actor_base_tile + 66*18], di
    mov [mode_one_tile + 66*18], di
    mov [mode_five_tile + 66*18], di
    xor ebx, ebx
    mov ecx, 0x3e8
    mov edi, 0x17
    mov esi, 0x8f8
    mov [mode_two_tile + 66*18], dx
    mov [mode_three_tile + 66*18], dx
    mov [mode_four_tile + 66*18], dx
    mov [0x775ec], ebp
    mov [actor_destination_y + 67*16], ebp
    xor bh, ah
    mov al, 0x2
    mov ebp, 0x1d80
    mov [actor_enabled + 66], bh
    mov [actor_health + 66*2], cx
    mov [actor_first_waypoint + 66*4], di
    mov [actor_health + 67*2], cx
    mov [mode_two_tile + 67*18], si
    mov [mode_three_tile + 67*18], si
    mov [mode_four_tile + 67*18], si
    xor edx, edx
    mov bl, 0x4
    mov edi, 0xffffb200
    mov cl, 0x2
    mov esi, 0xe80
    mov [actor_projectile_type + 66], al
    mov [actor_destination_x + 66*16], edx
    mov [actor_destination_y + 66*16], edx
    mov [actor_destination_parameter_one + 66*16], edx
    mov [actor_destination_parameter_two + 66*16], edx
    mov [0x775f8], ebp
    mov ah, 0x1
    mov [actor_board + 67], bl
    mov [0x775e8], edi
    mov [actor_projectile_type + 67], cl
    mov [actor_destination_x + 67*16], edi
    mov [actor_destination_parameter_two + 67*16], esi
    xor dh, dh
    mov bh, 0x10
    mov ch, 0x1
    mov edi, 0x200
    mov [actor_profile + 66], ah
    mov [actor_enabled + 67], dh
    mov edx, 0x1465
    mov [actor_sequence_initial + 67], bh
    mov [actor_profile + 67], ch
    mov [actor_mode + 67], bl
    mov [0x775f4], edi
    xor eax, eax
    mov ebx, 0x966
    mov ecx, 0xffffca80
    mov [actor_z_offset + 67*4], eax
    mov [saved_actor_lotag + 67*2], dx
    mov dl, 0x4
    mov [actor_base_tile + 67*18], bx
    mov [mode_one_tile + 67*18], bx
    mov [mode_five_tile + 67*18], bx
    mov [actor_destination_parameter_one + 67*16], ecx
    xor ah, ah
    mov ecx, 0x3e8
    mov [actor_enabled + 68], ah
    mov [actor_board + 68], dl
    xor ebx, ebx
    mov dh, 0x10
    mov [actor_first_waypoint + 67*4], bx
    mov [actor_health + 68*2], cx
    xor eax, eax
    mov bl, 0x2
    mov [actor_z_offset + 68*4], eax
    mov [actor_sequence_initial + 68], dh
    mov [actor_projectile_type + 68], bl
    mov esi, 0x1565
    mov bh, 0x1
    mov edi, 0x966
    mov ecx, 0xfffff880
    mov al, 0x4
    mov [actor_mode + 68], dl
    mov [actor_destination_y + 68*16], ebp
    mov edx, 0x8f8
    mov ebp, 0x2200
    mov [saved_actor_lotag + 68*2], si
    mov [actor_profile + 68], bh
    mov [actor_base_tile + 68*18], di
    mov [mode_one_tile + 68*18], di
    mov [mode_five_tile + 68*18], di
    mov [actor_destination_parameter_one + 68*16], ecx
    mov [actor_board + 69], al
    mov [actor_projectile_type + 69], bl
    mov [actor_profile + 69], bh
    mov esi, 0x1000
    mov eax, 0x1c00
    mov bl, 0x3
    mov [mode_two_tile + 68*18], dx
    mov [mode_three_tile + 68*18], dx
    mov [mode_four_tile + 68*18], dx
    mov [0x77604], ebp
    xor edi, edi
    xor ch, ch
    mov edx, 0x200
    mov ebp, 0x2e80
    mov [actor_first_waypoint + 68*4], di
    mov [actor_destination_parameter_two + 68*16], esi
    mov [actor_enabled + 69], ch
    mov [0x77608], eax
    mov [actor_mode + 69], bl
    mov [actor_enabled + 70], ch
    mov edi, 0xffffee00
    mov ah, 0x10
    mov ebx, 0x966
    mov esi, 0x8f8
    mov cl, 0x4
    mov [actor_destination_x + 68*16], edx
    mov [0x7760c], ebp
    mov [0x77600], edi
    mov [actor_sequence_initial + 69], ah
    mov [actor_base_tile + 69*18], bx
    mov [mode_one_tile + 69*18], bx
    mov [mode_two_tile + 69*18], si
    mov [mode_three_tile + 69*18], si
    mov [mode_four_tile + 69*18], si
    mov [mode_five_tile + 69*18], bx
    mov [actor_board + 70], cl
    xor edx, edx
    mov eax, 0x3e8
    mov ebx, 0x1a
    mov ch, 0x10
    mov esi, 0x1865
    mov edi, 0x966
    mov [actor_z_offset + 69*4], edx
    mov edx, 0x1265
    mov [actor_health + 69*2], ax
    mov [actor_first_waypoint + 69*4], bx
    mov [actor_sequence_initial + 70], ch
    mov [saved_actor_lotag + 70*2], si
    mov [actor_base_tile + 70*18], di
    mov [mode_one_tile + 70*18], di
    mov [mode_five_tile + 70*18], di
    mov eax, 0x2800
    mov ecx, 0x3e8
    mov [saved_actor_lotag + 69*2], dx
    xor ebx, ebx
    xor edi, edi
    xor esi, esi
    mov edx, 0xffffe800
    mov [actor_destination_x + 69*16], ebx
    mov [actor_destination_y + 69*16], ebx
    mov [actor_destination_parameter_one + 69*16], ebx
    mov [actor_destination_parameter_two + 69*16], ebx
    mov [0x77610], eax
    mov [actor_z_offset + 70*4], ebx
    mov [actor_health + 70*2], cx
    mov [actor_first_waypoint + 70*4], di
    mov [actor_destination_y + 70*16], esi
    mov al, 0x2
    mov [0x77614], edx
    xor ecx, ecx
    mov edx, 0x8f8
    mov [actor_projectile_type + 70], al
    mov [actor_destination_x + 70*16], ecx
    mov [actor_destination_parameter_one + 70*16], ecx
    mov [actor_destination_parameter_two + 70*16], ecx
    mov ah, 0x1
    mov [mode_two_tile + 70*18], dx
    mov [mode_three_tile + 70*18], dx
    mov [mode_four_tile + 70*18], dx
    mov [actor_profile + 70], ah
    xor dh, dh
    mov [actor_mode + 70], al
    mov [actor_enabled + 71], dh
    mov bl, 0x4
    mov edx, 0x2a00
    mov eax, 0x3e8
    mov esi, 0x8f8
    mov [0x77618], ebp
    mov [actor_z_offset + 71*4], ecx
    mov [actor_first_waypoint + 71*4], di
    mov cl, 0x2
    mov edi, 0x966
    mov [actor_board + 71], bl
    mov [0x7761c], edx
    mov [actor_health + 71*2], ax
    mov [mode_two_tile + 71*18], si
    mov [mode_three_tile + 71*18], si
    mov [mode_four_tile + 71*18], si
    xor ebp, ebp
    mov ebx, 0xffffe800
    mov edx, 0x1665
    mov [actor_projectile_type + 71], cl
    mov [actor_base_tile + 72*18], di
    mov [mode_one_tile + 72*18], di
    mov [mode_five_tile + 72*18], di
    mov [actor_destination_x + 72*16], ebp
    mov [actor_destination_y + 72*16], ebp
    mov [actor_destination_parameter_one + 72*16], ebp
    mov [actor_destination_parameter_two + 72*16], ebp
    mov [actor_z_offset + 73*4], ebp
    xor esi, esi
    xor ah, ah
    mov ch, 0x1
    mov [0x77620], ebx
    mov [saved_actor_lotag + 71*2], dx
    mov [actor_destination_x + 71*16], esi
    mov [actor_destination_y + 71*16], esi
    mov [actor_destination_parameter_one + 71*16], esi
    mov [actor_destination_parameter_two + 71*16], esi
    mov [actor_enabled + 72], ah
    mov [actor_z_offset + 72*4], esi
    xor edi, edi
    mov bh, 0x10
    mov dl, 0x4
    mov esi, 0x1765
    mov al, 0x4
    mov [actor_profile + 71], ch
    mov [actor_mode + 71], cl
    mov [actor_first_waypoint + 72*4], di
    mov ecx, 0xfffff000
    mov [actor_sequence_initial + 71], bh
    mov [actor_board + 72], dl
    mov [saved_actor_lotag + 72*2], si
    mov [actor_board + 73], al
    mov ebx, 0x966
    mov edx, 0x2e80
    mov esi, 0xfffff000
    mov ah, 0x10
    mov [0x7762c], ecx
    mov ecx, 0x3e8
    mov [actor_base_tile + 71*18], bx
    mov [mode_one_tile + 71*18], bx
    mov [mode_five_tile + 71*18], bx
    mov [0x77624], edx
    mov [0x77638], esi
    mov [actor_sequence_initial + 73], ah
    mov ebx, 0x600
    mov dh, 0x10
    mov eax, 0x3e8
    mov esi, 0x8f8
    mov [actor_health + 72*2], cx
    mov [0x77628], ebx
    mov [actor_sequence_initial + 72], dh
    mov [actor_health + 73*2], ax
    mov [mode_two_tile + 73*18], si
    mov [mode_three_tile + 73*18], si
    mov [mode_four_tile + 73*18], si
    mov bl, 0x2
    mov edx, 0x8f8
    mov [actor_projectile_type + 72], bl
    mov [mode_two_tile + 72*18], dx
    mov [mode_three_tile + 72*18], dx
    mov ecx, edx
    mov [mode_four_tile + 72*18], dx
    mov bh, 0x1
    xor ch, dh
    mov dl, 0x2
    mov [actor_profile + 72], bh
    mov [actor_mode + 72], bl
    mov [actor_enabled + 73], ch
    mov ebx, 0x2e80
    mov ecx, 0x800
    mov [actor_projectile_type + 73], dl
    mov edx, 0x1765
    mov [0x77630], ebx
    mov [0x77634], ecx
    mov bl, 0x2
    mov [saved_actor_lotag + 73*2], dx
    mov dh, 0x1
    mov [actor_mode + 73], bl
    mov ebx, 0x966
    mov [actor_profile + 73], dh
    mov [actor_base_tile + 73*18], bx
    mov [mode_one_tile + 73*18], bx
    mov [mode_five_tile + 73*18], bx
    mov cl, 0x4
    mov esi, 0xfffff700
    mov [actor_first_waypoint + 73*4], di
    mov [actor_destination_x + 73*16], ebp
    mov [actor_z_offset + 74*4], ebp
    mov [actor_profile + 74], dh
    xor eax, eax
    xor ebx, ebx
    mov edi, 0x1c48
    mov dl, 0x5
    mov ebp, 0x2c00
    mov [actor_destination_y + 73*16], eax
    mov [actor_destination_parameter_one + 73*16], eax
    mov [actor_destination_parameter_two + 73*16], eax
    mov [actor_board + 74], cl
    mov [0x77640], esi
    xor bh, ah
    mov ecx, 0xffffe000
    mov al, 0x2
    mov esi, 0x565
    mov [actor_enabled + 74], bh
    mov [0x77644], edi
    mov [actor_mode + 74], dl
    mov [0x77650], ebp
    mov edi, 0x966
    mov edx, 0x8f8
    mov ebx, 0x1380
    mov ebp, 0xb80
    mov [0x7763c], ecx
    mov [actor_projectile_type + 74], al
    mov [saved_actor_lotag + 74*2], si
    mov ch, 0x10
    mov eax, 0xffffe000
    mov esi, 0xffffe480
    mov [actor_base_tile + 74*18], di
    mov [mode_one_tile + 74*18], di
    mov [mode_two_tile + 74*18], dx
    mov [mode_three_tile + 74*18], dx
    mov [mode_four_tile + 74*18], dx
    mov [mode_five_tile + 74*18], di
    mov [actor_destination_parameter_one + 74*16], ebx
    mov [0x77694], ebp
    mov edx, 0xfffff700
    mov bl, 0x4
    mov [actor_sequence_initial + 74], ch
    mov [actor_destination_x + 74*16], eax
    mov [0x77648], esi
    xor edi, edi
    mov ecx, 0x3e8
    mov esi, 0x8f8
    mov [actor_first_waypoint + 74*4], di
    mov [actor_destination_y + 74*16], edx
    mov [actor_destination_parameter_two + 74*16], edx
    mov [actor_board + 75], bl
    xor eax, eax
    mov edi, 0xffffde00
    mov bh, 0x10
    mov [actor_health + 74*2], cx
    mov [actor_z_offset + 75*4], eax
    mov [actor_health + 75*2], cx
    mov [mode_two_tile + 75*18], si
    mov [mode_three_tile + 75*18], si
    mov [mode_four_tile + 75*18], si
    xor dh, dh
    mov cl, 0x2
    mov al, 0x3
    mov esi, 0x500
    mov [actor_enabled + 75], dh
    mov [0x7764c], edi
    mov [actor_sequence_initial + 75], bh
    mov edx, 0x565
    mov ebx, 0x966
    mov edi, 0xffff5000
    mov [actor_projectile_type + 75], cl
    mov [actor_mode + 75], al
    mov [saved_actor_lotag + 81*2], si
    mov ch, 0x1
    mov [saved_actor_lotag + 75*2], dx
    mov [actor_base_tile + 75*18], bx
    mov [mode_one_tile + 75*18], bx
    mov [mode_five_tile + 75*18], bx
    mov [0x77690], edi
    xor ah, ah
    mov ebx, 0x8
    mov edi, 0x8f8
    mov [actor_profile + 75], ch
    mov [actor_enabled + 81], ah
    mov [actor_mode + 81], ah
    xor edx, edx
    mov ecx, 0x3e8
    mov [actor_first_waypoint + 75*4], bx
    mov [actor_destination_x + 75*16], edx
    mov [actor_destination_y + 75*16], edx
    mov [actor_destination_parameter_one + 75*16], edx
    mov [actor_destination_parameter_two + 75*16], edx
    mov [actor_base_tile + 81*18], di
    mov dl, 0x5
    mov [actor_health + 81*2], cx
    xor ebx, ebx
    mov [actor_board + 81], dl
    mov [actor_z_offset + 81*4], ebx
    mov bl, 0x2
    mov dh, 0x10
    mov [actor_projectile_type + 81], bl
    mov bh, 0x1
    mov [actor_sequence_initial + 81], dh
    mov [actor_profile + 81], bh
    mov eax, 0x966
    mov ebp, 0x1100
    mov [mode_two_tile + 81*18], di
    mov [mode_three_tile + 81*18], di
    mov [mode_four_tile + 81*18], di
    xor edx, edx
    xor ebx, ebx
    xor ecx, ecx
    xor esi, esi
    mov [mode_one_tile + 81*18], ax
    mov [mode_five_tile + 81*18], ax
    mov [actor_destination_x + 81*16], edx
    mov [actor_destination_y + 81*16], ebx
    mov [actor_destination_parameter_one + 81*16], ecx
    mov [actor_destination_parameter_two + 81*16], esi
    mov [0x776a0], ebp
    mov [actor_z_offset + 82*4], edx
    xor edi, edi
    mov al, 0x5
    mov dl, 0x2
    mov ebp, 0x1700
    mov esi, 0x500
    mov [actor_first_waypoint + 81*4], di
    xor ch, ch
    xor bl, bl
    mov edi, 0xffff4d00
    mov [actor_enabled + 82], ch
    mov [actor_board + 82], al
    mov [actor_projectile_type + 82], dl
    mov [actor_mode + 82], bl
    mov [0x776ac], ebp
    mov [saved_actor_lotag + 83*2], si
    mov ah, 0x10
    mov edx, 0x1700
    mov ebx, 0x8f8
    mov ecx, 0x966
    mov ebp, 0x1d00
    mov [0x7769c], edi
    xor esi, esi
    mov edi, 0xffff4d80
    mov [actor_sequence_initial + 82], ah
    mov [saved_actor_lotag + 82*2], dx
    mov [actor_base_tile + 82*18], bx
    mov [mode_one_tile + 82*18], cx
    mov [mode_two_tile + 82*18], bx
    mov [mode_three_tile + 82*18], bx
    mov [mode_four_tile + 82*18], bx
    mov [mode_five_tile + 82*18], cx
    mov [actor_destination_parameter_two + 83*16], esi
    mov [0x776b8], ebp
    mov eax, 0x3e8
    mov dh, 0x1
    mov cl, 0x5
    mov [0x776a8], edi
    xor ebx, ebx
    mov edi, 0x8f8
    mov [actor_health + 82*2], ax
    mov [actor_profile + 82], dh
    mov [actor_first_waypoint + 82*4], bx
    mov [actor_board + 83], cl
    mov [actor_health + 83*2], ax
    mov ch, 0x10
    mov al, 0x2
    mov [actor_base_tile + 83*18], di
    mov [mode_two_tile + 83*18], di
    mov [mode_three_tile + 83*18], di
    mov [mode_four_tile + 83*18], di
    xor edx, edx
    xor ebx, ebx
    mov [actor_destination_x + 82*16], edx
    mov [actor_destination_y + 82*16], edx
    mov [actor_destination_parameter_one + 82*16], edx
    mov [actor_destination_parameter_two + 82*16], edx
    mov [actor_z_offset + 83*4], edx
    mov [actor_sequence_initial + 83], ch
    mov [actor_projectile_type + 83], al
    xor bh, dh
    xor edi, edi
    mov ah, 0x1
    mov [actor_enabled + 83], bh
    mov [actor_first_waypoint + 83*4], di
    xor dl, dl
    xor ecx, ecx
    mov edi, 0xffff5000
    mov [actor_profile + 83], ah
    mov [actor_mode + 83], dl
    mov [actor_destination_parameter_one + 83*16], ecx
    mov [actor_z_offset + 84*4], ecx
    xor ebx, ebx
    mov eax, 0x966
    mov [actor_destination_y + 83*16], ebx
    mov [0x776b4], edi
    xor edx, edx
    mov bl, 0x5
    mov [mode_one_tile + 83*18], ax
    mov [mode_five_tile + 83*18], ax
    mov [actor_destination_x + 83*16], edx
    mov [actor_board + 84], bl
    xor dh, dh
    mov bh, 0x10
    mov [actor_enabled + 84], dh
    mov [actor_sequence_initial + 84], bh
    mov eax, 0x3e8
    mov cl, 0x2
    mov edx, 0x1700
    mov ebx, 0x8f8
    mov edi, 0xffff8100
    mov ebp, 0x2100
    mov esi, 0x1765
    mov [actor_health + 84*2], ax
    mov [actor_projectile_type + 84], cl
    mov [saved_actor_lotag + 84*2], dx
    mov [actor_base_tile + 84*18], bx
    mov [mode_two_tile + 84*18], bx
    mov [mode_three_tile + 84*18], bx
    mov [mode_four_tile + 84*18], bx
    mov [0x776c0], edi
    mov [0x776c4], ebp
    mov [saved_actor_lotag + 85*2], si
    mov [actor_destination_y + 85*16], ebp
    mov ch, 0x1
    mov edi, 0x966
    mov esi, 0x680
    mov ebp, 0x2e00
    xor al, al
    xor ebx, ebx
    xor edx, edx
    mov [actor_profile + 84], ch
    mov [actor_mode + 84], al
    mov [actor_first_waypoint + 84*4], bx
    mov [actor_destination_x + 84*16], edx
    mov [actor_destination_y + 84*16], edx
    mov [actor_destination_parameter_one + 84*16], edx
    mov [actor_destination_parameter_two + 84*16], edx
    mov [actor_base_tile + 85*18], di
    mov [mode_one_tile + 85*18], di
    mov [mode_five_tile + 85*18], di
    mov [actor_destination_parameter_two + 85*16], esi
    mov [0x776d0], ebp
    mov ecx, 0x966
    mov dl, 0x5
    mov esi, 0x8f8
    xor ebx, ebx
    xor ah, ah
    xor edi, edi
    mov [mode_one_tile + 84*18], cx
    mov [mode_five_tile + 84*18], cx
    mov [actor_enabled + 85], ah
    mov [actor_board + 85], dl
    mov [actor_z_offset + 85*4], ebx
    mov [actor_first_waypoint + 85*4], di
    mov [mode_two_tile + 86*18], si
    mov [mode_three_tile + 86*18], si
    mov [mode_four_tile + 86*18], si
    mov dh, 0x10
    mov ecx, 0x3e8
    mov bl, 0x2
    mov al, 0x5
    mov edi, 0xffff9000
    mov [actor_sequence_initial + 85], dh
    mov [actor_health + 85*2], cx
    mov [actor_projectile_type + 85], bl
    mov [actor_board + 86], al
    mov [0x776cc], edi
    mov bh, 0x1
    mov cl, 0x4
    mov edx, 0x8f8
    xor eax, eax
    mov [actor_profile + 85], bh
    mov [actor_mode + 85], cl
    mov [mode_two_tile + 85*18], dx
    mov [mode_three_tile + 85*18], dx
    mov [mode_four_tile + 85*18], dx
    mov [actor_z_offset + 86*4], eax
    mov [actor_projectile_type + 86], bl
    mov [actor_profile + 86], bh
    mov edx, 0xffff8100
    mov ah, 0x10
    mov bl, 0x3
    mov [actor_destination_x + 85*16], edx
    mov ecx, edx
    mov [actor_destination_parameter_one + 85*16], edx
    mov [actor_sequence_initial + 86], ah
    mov [actor_mode + 86], bl
    mov eax, 0x3e8
    mov ebx, 0x966
    xor ch, dh
    mov edx, 0x565
    mov [actor_enabled + 86], ch
    mov [actor_health + 86*2], ax
    mov [actor_base_tile + 86*18], bx
    mov [mode_one_tile + 86*18], bx
    mov [mode_five_tile + 86*18], bx
    mov ebx, 0x3e
    mov [saved_actor_lotag + 86*2], dx
    xor edx, edx
    mov [actor_first_waypoint + 86*4], bx
    mov [actor_destination_x + 86*16], edx
    mov [actor_destination_y + 86*16], edx
    xor ebx, ebx
    mov [actor_destination_parameter_one + 86*16], edx
    xor bh, dh
    mov [actor_destination_parameter_two + 86*16], edx
    mov [actor_enabled + 87], bh
    mov cl, 0x5
    mov edi, 0xffff9f00
    mov ebp, 0x2280
    mov esi, 0x565
    mov bl, 0x5
    mov [actor_z_offset + 87*4], edx
    mov [actor_health + 87*2], ax
    mov dl, 0x3
    mov [actor_board + 87], cl
    mov [0x776d8], edi
    mov [0x776dc], ebp
    mov [saved_actor_lotag + 87*2], si
    mov [actor_board + 88], bl
    mov ch, 0x10
    mov edi, 0x966
    mov ebp, 0x3400
    mov bh, 0x10
    mov esi, 0x8f8
    mov [actor_mode + 87], dl
    mov edx, 0x8f8
    mov [actor_sequence_initial + 87], ch
    mov [actor_base_tile + 87*18], di
    mov [mode_one_tile + 87*18], di
    mov [mode_five_tile + 87*18], di
    mov [0x776e8], ebp
    mov [actor_sequence_initial + 88], bh
    mov [mode_two_tile + 88*18], si
    mov [mode_three_tile + 88*18], si
    mov [mode_four_tile + 88*18], si
    mov edi, 0x43
    mov ebx, 0x966
    mov ebp, 0x2b00
    mov esi, 0x565
    mov ecx, eax
    mov [mode_two_tile + 87*18], dx
    mov [mode_three_tile + 87*18], dx
    mov [mode_four_tile + 87*18], dx
    mov al, 0x2
    mov [actor_first_waypoint + 87*4], di
    mov [actor_base_tile + 88*18], bx
    mov [mode_one_tile + 88*18], bx
    mov [mode_five_tile + 88*18], bx
    mov [0x776f4], ebp
    mov [saved_actor_lotag + 89*2], si
    mov [actor_destination_y + 89*16], ebp
    xor edx, edx
    mov edi, 0xffff9b80
    mov ebx, 0x46
    mov [actor_projectile_type + 87], al
    mov [actor_destination_x + 87*16], edx
    mov [actor_destination_y + 87*16], edx
    mov [actor_destination_parameter_one + 87*16], edx
    mov [actor_destination_parameter_two + 87*16], edx
    mov ah, 0x1
    mov [0x776e4], edi
    mov [actor_first_waypoint + 88*4], bx
    xor dh, dh
    mov edi, 0xffffac80
    mov [actor_profile + 87], ah
    mov [actor_enabled + 88], dh
    xor ebx, ebx
    mov edx, 0x1765
    mov [0x776f0], edi
    mov [actor_z_offset + 89*4], ebx
    xor eax, eax
    mov bl, 0x2
    mov edi, 0x966
    mov [actor_z_offset + 88*4], eax
    mov [saved_actor_lotag + 88*2], dx
    mov eax, ecx
    mov [actor_projectile_type + 89], bl
    mov [actor_base_tile + 89*18], di
    mov [mode_one_tile + 89*18], di
    mov [mode_five_tile + 89*18], di
    xor edx, edx
    mov cl, 0x2
    mov bh, 0x1
    mov [actor_health + 88*2], ax
    mov [actor_destination_x + 88*16], edx
    mov [actor_destination_y + 88*16], edx
    mov [actor_destination_parameter_one + 88*16], edx
    mov [actor_destination_parameter_two + 88*16], edx
    xor edi, edi
    mov al, 0x3
    mov dl, 0x5
    mov [actor_projectile_type + 88], cl
    mov [actor_profile + 89], bh
    mov [actor_first_waypoint + 89*4], di
    mov ch, 0x1
    mov [actor_mode + 88], al
    mov [actor_board + 89], dl
    mov dh, 0x10
    mov [actor_profile + 88], ch
    xor ah, ah
    mov ecx, 0x3e8
    mov [actor_enabled + 89], ah
    mov [actor_sequence_initial + 89], dh
    mov edx, 0x8f8
    mov [actor_health + 89*2], cx
    mov cl, 0x4
    mov [mode_two_tile + 89*18], dx
    mov [mode_three_tile + 89*18], dx
    mov [mode_four_tile + 89*18], dx
    mov edx, 0xffffac80
    mov [actor_mode + 89], cl
    mov [actor_destination_x + 89*16], edx
    mov ecx, 0xffff9580
    mov al, 0x5
    mov edi, 0xffffc680
    mov edx, 0x1665
    mov esi, 0x8f8
    mov [actor_destination_parameter_two + 89*16], ebp
    mov [actor_projectile_type + 90], bl
    mov [actor_profile + 90], bh
    mov ebp, 0x4a80
    mov bl, 0x5
    mov [actor_destination_parameter_one + 89*16], ecx
    mov [actor_board + 90], al
    mov [0x776fc], edi
    mov [saved_actor_lotag + 90*2], dx
    mov [mode_two_tile + 90*18], si
    mov [mode_three_tile + 90*18], si
    mov [mode_four_tile + 90*18], si
    mov [actor_destination_x + 90*16], edi
    mov esi, 0x2980
    mov edi, 0xffffcd00
    mov dl, 0x4
    mov [0x77700], ebp
    mov [actor_mode + 90], bl
    mov [actor_destination_y + 90*16], ebp
    xor ch, ch
    xor eax, eax
    mov ebx, 0x966
    mov ebp, 0x2880
    mov [actor_enabled + 90], ch
    mov [actor_z_offset + 90*4], eax
    mov [actor_destination_parameter_two + 90*16], esi
    mov [0x77708], edi
    mov [0x7f6da], dl
    mov ah, 0x10
    mov ecx, 0xffffb000
    mov esi, 0x1a65
    mov edi, 0xa70
    mov edx, 0xffffcd00
    mov [actor_base_tile + 90*18], bx
    mov [mode_one_tile + 90*18], bx
    mov [mode_five_tile + 90*18], bx
    mov [0x7770c], ebp
    mov [0x72fb0], ebp
    mov ebp, 0x2780
    mov [actor_sequence_initial + 90], ah
    mov [actor_destination_parameter_one + 90*16], ecx
    mov [0x7d784], si
    mov [0x7b226], di
    mov [0x7b228], di
    mov [0x7b22a], di
    mov [0x7b22c], di
    mov [0x7b22e], di
    mov [0x7b230], di
    mov [0x7b232], di
    mov [0x72fac], edx
    xor ebx, ebx
    mov eax, 0x3e8
    mov cl, 0x5
    mov esi, 0x2b00
    mov edx, 0xfa0
    mov [actor_first_waypoint + 90*4], bx
    mov [0x77718], ebp
    mov bh, 0x2
    mov [actor_health + 90*2], ax
    mov [0x7eb1c], cl
    mov [0x72fb8], esi
    mov [0x7cfb2], dx
    mov ch, 0x10
    mov [0x7ed11], bh
    mov [0x7ed12], bh
    xor eax, eax
    mov bl, 0x5
    mov [0x79380], eax
    mov [0x7e53d], ch
    mov ecx, 0xfa0
    mov [0x7eb1d], bl
    xor al, al
    mov bh, 0x10
    mov [0x7cfb0], cx
    mov [0x7ef06], al
    mov ah, 0x1
    mov ecx, 0xffffaf80
    mov [0x7e53e], bh
    mov ebx, 0x1a65
    mov [0x7e927], ah
    mov [0x72fb4], ecx
    mov eax, edi
    xor cl, cl
    mov [0x7d786], bx
    mov [0x7ef07], cl
    xor eax, edi
    mov edi, 0xffffe080
    mov ch, 0x1
    mov [0x78bac], ax
    mov [0x77714], edi
    mov [0x7e928], ch
    xor eax, eax
    mov ecx, 0xa70
    mov [0x79384], eax
    mov al, 0x4
    mov [0x7b238], cx
    mov [0x7b23a], cx
    mov [0x7b23c], cx
    mov [0x7b23e], cx
    mov [0x7b240], cx
    mov [0x7f6db], al
    mov dl, 0x5
    mov bl, 0x2
    mov [0x7b242], cx
    mov [0x7b244], cx
    mov [0x72fbc], edi
    mov [0x72fc0], ebp
    xor esi, esi
    xor ah, ah
    mov ecx, 0xffffd180
    mov edi, 0xffffe500
    mov ebp, 0x3380
    mov [0x78bb0], si
    mov [0x7ed13], ah
    mov [0x7eb1e], dl
    mov [0x7ef08], bl
    mov esi, 0x4000
    mov dh, 0x10
    mov bh, 0x1
    mov [0x72fc4], ecx
    mov [0x77720], edi
    mov [0x77724], ebp
    mov [0x72fd0], ebp
    mov [0x72fd8], ebp
    xor eax, eax
    mov edi, 0x3e8
    mov cl, 0x4
    mov ebp, 0x800
    mov [0x72fc8], esi
    mov [0x79388], eax
    mov [0x7e53f], dh
    mov [0x7e929], bh
    mov eax, 0x1665
    mov edx, 0x966
    mov ebx, 0x3e8
    mov esi, 0x966
    mov [0x7cfb4], di
    mov [0x7f6dc], cl
    mov [0x77730], ebp
    mov [0x72fe0], ebp
    mov [0x72fe8], ebp
    mov [0x7773c], ebp
    mov ecx, 0x8f8
    mov edi, 0xffffb800
    mov [0x7d788], ax
    mov [0x7b24a], dx
    mov [0x7b24c], dx
    mov [0x7b254], dx
    mov [0x7cfb6], bx
    mov [0x7b25c], si
    mov [0x7b25e], si
    mov [0x7b266], si
    mov al, 0x5
    mov bl, 0x4
    mov [0x7b24e], cx
    mov [0x7b250], cx
    mov [0x7b252], cx
    mov [0x7772c], edi
    mov [0x72fdc], edi
    xor edx, edx
    xor esi, esi
    mov ecx, 0xffffb500
    mov edi, 0xffffca80
    mov [0x78bb4], dx
    mov [0x7eb1f], al
    mov [0x7f6dd], bl
    mov [0x78bb8], si
    mov edx, 0xffffe7d0
    mov [0x72fd4], ecx
    mov [0x77738], edi
    xor eax, eax
    xor bh, bh
    mov edi, 0x3e8
    mov [0x72fcc], edx
    mov [0x7938c], eax
    mov [0x7ed15], bh
    xor ch, ch
    mov ah, 0x10
    mov dl, 0x2
    mov [0x7ed14], ch
    mov [0x7cfb8], di
    mov ecx, 0x1865
    mov [0x7e540], ah
    mov [0x7ef09], dl
    mov dh, 0x1
    mov eax, 0x8f8
    mov [0x7d78a], cx
    mov ecx, 0x980
    mov [0x7e92a], dh
    mov [0x7b260], ax
    mov [0x7b262], ax
    mov [0x7b264], ax
    mov [0x7ef0a], dl
    mov [0x7e92b], dh
    mov dl, 0x3
    mov [0x72fe4], ecx
    xor eax, eax
    mov cl, 0x5
    mov [0x79390], eax
    mov [0x7f6de], dl
    mov eax, 0x565
    mov edx, 0x966
    mov [0x7eb20], cl
    mov ch, 0x10
    mov [0x7d78c], ax
    mov [0x7b26e], dx
    mov [0x7e541], ch
    mov ecx, 0x8f8
    mov bl, 0x5
    mov edi, 0xfffffb00
    mov esi, 0xa70
    mov [0x7b270], dx
    mov [0x7b278], dx
    mov [0x77748], ebp
    mov [0x73000], ebp
    mov [0x73008], ebp
    xor eax, eax
    mov edx, 0x49
    mov ebp, 0xffffe680
    mov [0x7b272], cx
    mov [0x7b274], cx
    mov [0x7b276], cx
    mov [0x7eb21], bl
    mov [0x77744], edi
    mov [0x79394], eax
    mov [0x7b280], si
    mov [0x7b282], si
    mov [0x7b284], si
    mov [0x7b286], si
    mov [0x7b288], si
    mov [0x7b28a], si
    mov [0x7b28c], si
    mov bh, 0x10
    mov al, 0x4
    mov [0x78bbc], dx
    mov edi, esi
    mov [0x77754], ebp
    mov [0x77760], ebp
    xor ecx, ecx
    mov [0x7e542], bh
    mov [0x7f6df], al
    xor edx, edx
    xor edi, esi
    mov ebx, 0xfa0
    mov esi, 0x8f8
    mov [0x72fec], edx
    mov [0x72ff0], edx
    mov [0x72ff4], edx
    mov [0x72ff8], edx
    mov [0x78bc0], di
    xor ah, ah
    mov dh, 0x2
    mov edi, 0xffffd980
    mov [0x7cfba], bx
    mov [0x7ed17], ah
    mov [0x7b296], si
    mov [0x7b298], si
    mov [0x7b29a], si
    mov bl, 0x2
    mov [0x7ed16], dh
    mov [0x77750], edi
    xor cl, dl
    xor eax, eax
    mov edx, 0xfffffb00
    mov edi, 0xffffeb00
    mov [0x7ef0b], cl
    mov [0x79398], eax
    mov [0x7ef0c], bl
    mov ecx, 0x1a65
    mov eax, 0x3e8
    mov bh, 0x1
    mov [0x72ffc], edx
    mov [0x7775c], edi
    mov dl, 0x5
    mov [0x7d78e], cx
    mov [0x7cfbc], ax
    mov [0x7e92d], bh
    mov ch, 0x1
    mov ebx, 0x966
    mov al, 0x5
    mov [0x7eb22], dl
    mov dh, 0x10
    mov [0x7e92c], ch
    mov [0x7b292], bx
    mov [0x7b294], bx
    mov [0x7b29c], bx
    mov [0x7eb23], al
    mov ecx, 0xffffae00
    mov ebx, 0x4c
    mov [0x7e543], dh
    mov edx, 0x1665
    mov [0x73004], ecx
    mov [0x78bc4], bx
    mov cl, 0x3
    mov [0x7d790], dx
    xor edx, edx
    mov [0x7f6e0], cl
    mov [0x7300c], edx
    mov [0x73010], edx
    mov [0x73014], edx
    xor ecx, ecx
    mov [0x73018], edx
    xor ch, dh
    mov [0x7939c], edx
    mov [0x7ed18], ch
    mov ah, 0x10
    mov ecx, 0x3e8
    mov dl, 0x2
    mov esi, 0x565
    mov bl, 0x3
    mov edi, 0x966
    mov ebp, 0xffffe480
    mov [0x7e544], ah
    mov [0x7cfbe], cx
    mov [0x7ef0d], dl
    mov [0x7d792], si
    mov [0x7f6e1], bl
    mov [0x7b2a4], di
    mov [0x7b2a6], di
    mov [0x7b2ae], di
    mov [0x7eb24], al
    mov [0x7776c], ebp
    mov [0x7e545], ah
    mov [0x7cfc0], cx
    mov [0x73030], ebp
    mov dh, 0x1
    mov edi, 0x50
    mov al, 0x2
    mov esi, 0x8f8
    mov ecx, 0xffffb500
    mov ebp, 0xffffd380
    xor ebx, ebx
    mov [0x7e92e], dh
    mov [0x78bc8], di
    mov [0x7ef0e], al
    mov [0x7b2ba], si
    mov [0x7b2bc], si
    mov [0x7b2be], si
    mov [0x73034], ecx
    mov [0x77778], ebp
    mov [0x73040], ebp
    mov edx, 0x8f8
    mov edi, 0xffffca00
    mov ah, 0x1
    mov esi, 0xffffcd80
    mov ecx, 0x3e8
    mov [0x7b2a8], dx
    mov [0x7b2aa], dx
    mov [0x7b2ac], dx
    mov [0x77768], edi
    mov [0x7e92f], ah
    mov [0x7302c], edi
    mov [0x73038], esi
    mov [0x77774], edi
    mov [0x7cfc2], cx
    mov cl, 0x2
    mov esi, 0x1865
    mov edi, 0x966
    xor edx, edx
    xor eax, eax
    mov [0x7301c], edx
    mov [0x73020], edx
    mov [0x73024], edx
    mov [0x73028], edx
    mov [0x793a0], edx
    mov [0x793a4], eax
    mov [0x7ef0f], cl
    mov [0x7d796], si
    mov [0x7b2c8], di
    mov [0x7b2ca], di
    mov [0x7b2d2], di
    xor bh, dh
    mov edx, 0x1565
    mov ch, 0x1
    mov esi, 0xffffea80
    mov [0x7ed19], bh
    xor edi, edi
    xor ah, ah
    mov ebx, 0x966
    mov [0x7d794], dx
    mov [0x7e930], ch
    mov [0x78bd0], di
    mov [0x73048], esi
    mov [0x7ed1b], ah
    mov dl, 0x4
    mov ecx, 0xffffb100
    mov [0x7b2b6], bx
    mov [0x7b2b8], bx
    mov [0x7b2c0], bx
    mov [0x7f6e2], dl
    xor ebx, ebx
    mov [0x73044], ecx
    mov [0x78bcc], bx
    xor dh, dh
    mov bl, 0x5
    mov [0x7ed1a], dh
    mov [0x7f6e3], dl
    mov edx, 0x8f8
    mov [0x7eb25], bl
    mov bh, 0x10
    mov [0x7b2cc], dx
    mov [0x7b2ce], dx
    mov [0x7b2d0], dx
    mov edx, 0xffffca00
    mov [0x7e546], bh
    mov [0x7303c], edx
    mov edi, 0xffffea00
    mov ebp, 0xffffcc00
    mov edx, 0x565
    mov cl, 0x4
    mov esi, 0x8f8
    mov [0x7eb26], bl
    mov [0x7e547], bh
    xor eax, eax
    mov bl, 0x2
    mov [0x77780], edi
    mov [0x77784], ebp
    mov [0x793a8], eax
    mov [0x7d798], dx
    mov [0x7f6e4], cl
    mov [0x7b2de], si
    mov [0x7b2e0], si
    mov [0x7b2e2], si
    mov [0x7304c], edi
    mov [0x73050], ebp
    mov [0x73058], ebp
    mov [0x7778c], edi
    mov eax, 0x3e8
    mov ecx, 0xffffd480
    mov ebp, 0xffffc280
    mov dl, 0x2
    mov esi, 0x565
    mov edi, 0x966
    mov [0x7ef10], bl
    mov bh, 0x1
    mov [0x7cfc4], ax
    mov [0x73054], ecx
    mov [0x77790], ebp
    mov [0x7ef11], dl
    mov [0x7d79a], si
    mov [0x7b2ec], di
    mov [0x7b2ee], di
    mov [0x7b2f6], di
    mov [0x73060], ebp
    mov [0x73068], ebp
    mov al, 0x5
    mov dh, 0x1
    mov ebp, 0xffffac80
    mov [0x7e931], bh
    xor ch, ch
    xor edi, edi
    mov ebx, 0x966
    mov [0x7ed1c], ch
    mov [0x7eb27], al
    mov [0x7e932], dh
    mov [0x78bd8], di
    mov [0x7779c], ebp
    mov ecx, 0x3e8
    mov edx, 0x8f8
    mov edi, 0x980
    mov [0x7b2da], bx
    mov [0x7b2dc], bx
    xor eax, eax
    mov [0x7b2e4], bx
    mov [0x793ac], eax
    mov [0x7cfc6], cx
    mov [0x7b2f0], dx
    mov [0x7b2f2], dx
    mov [0x7b2f4], dx
    mov [0x77798], edi
    xor ebx, ebx
    mov ah, 0x10
    mov edx, 0xffffea00
    mov ecx, 0xffffd580
    mov edi, 0x54
    mov [0x78bd4], bx
    mov bl, 0x4
    mov [0x7e548], ah
    mov [0x7305c], edx
    mov [0x73064], ecx
    mov [0x78bdc], di
    mov eax, 0x67
    mov cl, 0x5
    mov [0x7f6e5], bl
    xor edx, edx
    mov bh, 0x2
    mov [0x7eb28], cl
    mov [0x793b0], edx
    mov ch, 0x10
    mov edx, 0xfa0
    mov [0x7ed1d], bh
    mov ebx, 0x1a65
    mov [0x7e549], ch
    mov [0x7cfc8], dx
    mov ecx, 0xa70
    mov [0x7d79c], bx
    xor dl, dl
    mov bl, 0x3
    mov [0x7ef12], dl

section .retained_3 align=1 vstart=0x20c44 follows=.retained_2
    mov dh, 0x1
    mov [0x7f6e6], bl
    xor ebx, ebx
    mov [0x7e933], dh

section .retained_4 align=1 vstart=0x20c83 follows=.retained_3
    movsx edx, ax
    xor bh, bh
    mov cl, 0x5
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    mov ebp, 0x1b00
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], ebp
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffffbd80
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_z_offset], ecx
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x10
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    mov bl, 0x2
    movsx edx, ax
    mov ecx, 0x1700
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], cx
    movsx edx, ax
    xor cl, cl
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], di
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_y], edi
    movsx edx, ax
    shl edx, byte 4
    xor ebp, ebp
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    shl edx, byte 4
    xor eax, eax
    mov [edx + actor_destination_parameter_two], eax
    mov eax, 0x69
    movsx edx, ax
    xor ch, ch
    mov [edx + actor_enabled], ch
    movsx edx, ax
    mov byte [edx + actor_board], 0x5
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_x], 0x1f40
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffffc000
    movsx edx, ax
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x10
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    movsx edx, ax
    mov byte [edx + actor_projectile_type], 0x2
    movsx edx, ax
    mov word [nosplit edx*2 + saved_actor_lotag], 0x500
    movsx edx, ax
    mov byte [edx + actor_profile], 0x1
    movsx edx, ax
    xor bl, bl
    mov [edx + actor_mode], bl
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + mode_one_tile], 0x966
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + mode_five_tile], 0x966
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_parameter_one], ebx
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0x6a
    mov [edx + actor_destination_parameter_two], ebx
    movsx edx, ax
    xor bh, bh
    mov cl, 0x5
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0x24c0
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffffc0c0
    movsx edx, ax
    mov ch, 0x10
    mov [nosplit edx*4 + actor_z_offset], ebp
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x2
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x1700
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    xor cl, cl
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x8f8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_four_tile], si
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor esi, esi
    mov [nosplit edx*4 + actor_first_waypoint], si
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_x], ebx
    movsx edx, ax
    shl edx, byte 4
    xor ecx, ecx
    mov [edx + actor_destination_y], ecx

section .retained_5 align=1 vstart=0x21074 follows=.retained_4
    movsx edx, ax
    xor ch, ch
    mov [edx + actor_enabled], ch
    movsx edx, ax
    mov byte [edx + actor_board], 0x5
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov ebp, 0x1ac0
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], ebp
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffffcf40
    movsx edx, ax
    xor esi, esi
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x10
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    movsx edx, ax
    mov byte [edx + actor_projectile_type], 0x2
    movsx edx, ax
    mov word [nosplit edx*2 + saved_actor_lotag], 0x500
    movsx edx, ax
    mov byte [edx + actor_profile], 0x1
    movsx edx, ax
    xor bl, bl
    mov [edx + actor_mode], bl
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_three_tile], cx
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    xor edi, edi
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    xor bh, bh
    shl edx, byte 0x4
    mov eax, 0x6c
    mov [edx + actor_destination_parameter_two], esi
    movsx edx, ax
    mov cl, 0x5
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_x], 0x1f80
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffffccc0
    movsx edx, ax
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x10
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    mov bl, 0x2
    movsx edx, ax
    mov ecx, 0x500
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], cx
    movsx edx, ax
    xor cl, cl
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_two_tile], si
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], di
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    xor ebp, ebp
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    xor ecx, ecx
    mov [edx + actor_destination_parameter_one], edi
    movsx edx, ax
    xor ebx, ebx
    shl edx, byte 0x4
    mov eax, 0x6d
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    xor ch, bh
    mov [edx + actor_enabled], ch
    movsx edx, ax
    mov byte [edx + actor_board], 0x5
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0x24c0
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffffcc40
    movsx edx, ax
    mov [nosplit edx*4 + actor_z_offset], ebp
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x10
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    movsx edx, ax
    mov byte [edx + actor_projectile_type], 0x2
    movsx edx, ax
    mov word [nosplit edx*2 + saved_actor_lotag], 0x1700
    movsx edx, ax
    mov byte [edx + actor_profile], 0x1
    movsx edx, ax
    xor bl, bl
    mov [edx + actor_mode], bl
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + mode_one_tile], 0x966
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ebx, 0x966
    mov ecx, edi
    mov [nosplit edx*2 + mode_five_tile], bx
    movsx edx, ax
    xor ecx, edi
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    mov bh, 0x2
    shl edx, byte 0x4
    mov eax, 0x6e
    mov [edx + actor_destination_parameter_two], ebp
    movsx edx, ax
    mov cl, 0x5
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    mov ebp, 0x4700
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], ebp
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffff9c40
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_z_offset], ecx
    mov ch, 0x10
    movsx edx, ax
    mov esi, 0xfa0
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    xor bl, bl
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x1a65
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x3
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0xa70
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0xa70
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], cx
    movsx edx, ax
    mov word [nosplit edx*4 + actor_first_waypoint], 0x59
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0x6f
    mov [edx + actor_destination_parameter_two], esi
    movsx edx, ax
    xor ch, ch
    mov [edx + actor_enabled], ch
    movsx edx, ax
    mov byte [edx + actor_board], 0x5
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_x], 0x2c80
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffff6480
    movsx edx, ax
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x10
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    movsx edx, ax
    mov byte [edx + actor_projectile_type], 0x2
    movsx edx, ax
    mov word [nosplit edx*2 + saved_actor_lotag], 0x1265
    movsx edx, ax
    mov byte [edx + actor_profile], 0x1
    movsx edx, ax
    mov byte [edx + actor_mode], 0x3
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + mode_two_tile], 0x8f8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    mov word [nosplit edx*4 + actor_first_waypoint], 0x5f
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], edi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], edi
    movsx edx, ax
    mov bh, 0x2
    shl edx, byte 0x4
    mov eax, 0x70
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov cl, 0x5
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0x6d80
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffffb400
    movsx edx, ax
    xor ebp, ebp
    mov [nosplit edx*4 + actor_z_offset], ebp
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x10
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0xfa0
    movsx edx, ax
    xor bl, bl
    mov esi, 0x1a65
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], si
    movsx edx, ax
    mov cl, 0x3
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0xa70
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], di
    movsx edx, ax
    mov word [nosplit edx*4 + actor_first_waypoint], 0x64
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_x], ebx

section .retained_6 align=1 vstart=0x2184c follows=.retained_5
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0x71
    mov [edx + actor_destination_parameter_two], ebx
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x6
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov ebp, 0xfffff400
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], ebp
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0x3700
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_z_offset], ecx
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x8
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    movsx edx, ax
    mov byte [edx + actor_projectile_type], 0x1
    movsx edx, ax
    mov word [nosplit edx*2 + saved_actor_lotag], 0x4665
    movsx edx, ax
    mov ch, 0x2
    mov [edx + actor_profile], ch
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], ch
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov edi, ecx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor edi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    mov bh, 0x4
    shl edx, byte 0x4
    mov eax, 0x72
    mov [edx + actor_destination_parameter_two], esi
    movsx edx, ax
    mov cl, 0x6
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_x], 0xfffff800
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0x3700
    movsx edx, ax
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x8
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    movsx edx, ax
    mov byte [edx + actor_projectile_type], 0x1
    movsx edx, ax
    mov word [nosplit edx*2 + saved_actor_lotag], 0x865
    movsx edx, ax
    mov bh, 0x2
    mov [edx + actor_profile], bh
    movsx edx, ax
    mov [edx + actor_mode], bh
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    xor ebp, ebp
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], edi
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0x73
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x6
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0xfffffb00
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0x3700
    movsx edx, ax
    mov [nosplit edx*4 + actor_z_offset], ebp
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x8
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    movsx edx, ax
    mov byte [edx + actor_projectile_type], 0x1
    movsx edx, ax
    mov word [nosplit edx*2 + saved_actor_lotag], 0x4665
    movsx edx, ax
    mov ch, 0x2
    mov [edx + actor_profile], ch
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], ch
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, edi
    mov [nosplit edx*2 + mode_five_tile], di
    movsx edx, ax
    xor ecx, edi
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_two], ebp
    mov eax, 0x74
    mov bh, 0x4
    movsx edx, ax
    mov cl, 0x6
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    mov ebp, 0xfffff000
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], ebp
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xfffff400
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_z_offset], ecx
    mov ch, 0x8
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x1
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x4665
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x2
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x5
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x9b8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov esi, ecx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor esi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], si
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xfffff400
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0xffffe200
    mov eax, 0x75
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x6
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_x], 0xd00
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffffee00
    movsx edx, ax
    xor esi, esi
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x8
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    movsx edx, ax
    mov byte [edx + actor_projectile_type], 0x1
    movsx edx, ax
    mov word [nosplit edx*2 + saved_actor_lotag], 0x4665
    movsx edx, ax
    mov byte [edx + actor_profile], 0x2
    movsx edx, ax
    mov byte [edx + actor_mode], 0x3
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    mov word [nosplit edx*4 + actor_first_waypoint], 0x1d
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    mov bh, 0x4
    shl edx, byte 0x4
    mov eax, 0x76
    mov [edx + actor_destination_parameter_two], esi
    movsx edx, ax
    mov cl, 0x6
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0x3700
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xffffdc00
    movsx edx, ax
    xor ebp, ebp
    mov [nosplit edx*4 + actor_z_offset], ebp
    movsx edx, ax
    mov byte [edx + actor_sequence_initial], 0x8
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    mov bl, 0x1
    movsx edx, ax
    mov ecx, 0x765
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x2
    mov [nosplit edx*2 + saved_actor_lotag], cx
    movsx edx, ax
    mov cl, 0x3
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    mov word [nosplit edx*4 + actor_first_waypoint], 0x21
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0x77
    mov [edx + actor_destination_parameter_two], ebp
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x6
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov ebp, 0x2800
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], ebp
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xf00
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_z_offset], ecx

section .retained_7 align=1 vstart=0x22065 follows=.retained_6
    movsx edx, ax
    mov byte [edx + actor_projectile_type], 0x1

section .retained_8 align=1 vstart=0x22090 follows=.retained_7
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], di

section .retained_9 align=1 vstart=0x2210e follows=.retained_8
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    mov bh, 0x4
    shl edx, byte 0x4
    mov eax, 0x78
    mov [edx + actor_destination_parameter_two], esi
    movsx edx, ax
    mov cl, 0x6
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_10 align=1 vstart=0x22185 follows=.retained_9
    movsx edx, ax
    mov ch, 0x8
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x1
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x4665
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x2
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x3
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x9b8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx

section .retained_11 align=1 vstart=0x2225b follows=.retained_10
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], edi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], edi
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0x79
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x6

section .retained_12 align=1 vstart=0x2231f follows=.retained_11
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_four_tile], cx
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx

section .retained_13 align=1 vstart=0x2239d follows=.retained_12
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_x], ebx

section .retained_14 align=1 vstart=0x223d4 follows=.retained_13
    mov bh, 0x4
    movsx edx, ax
    mov cl, 0x6
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_15 align=1 vstart=0x22438 follows=.retained_14
    mov bl, 0x1
    movsx edx, ax
    mov ecx, 0x4665
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x2
    mov [nosplit edx*2 + saved_actor_lotag], cx
    movsx edx, ax
    mov cl, 0x5
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_three_tile], si
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x6a00
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0x4280
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0x6880
    mov eax, 0x7b
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x6

section .retained_16 align=1 vstart=0x225b4 follows=.retained_15
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_two_tile], di
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], di
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov edi, 0x1900
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x3b00
    movsx edx, ax
    shl edx, byte 4
    mov bh, 0x4
    mov [edx + actor_destination_parameter_one], edi
    movsx edx, ax
    mov ecx, 0xffffff00
    shl edx, byte 0x4
    mov eax, 0x7c
    mov [edx + actor_destination_parameter_two], ecx
    movsx edx, ax
    mov cl, 0x6
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0x2580
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov edi, 0xffffcc00
    xor ebp, ebp
    mov [nosplit edx*4 + saved_actor_y], edi
    movsx edx, ax
    mov ch, 0x8
    mov [nosplit edx*4 + actor_z_offset], ebp
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x1
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x4665
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x2
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x9b8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, 0x9b8
    mov [nosplit edx*2 + mode_one_tile], cx
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov esi, ecx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor esi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], si
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0x2580
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xffffcc00
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xfffffc80
    movsx edx, ax
    mov edi, 0x1a80
    shl edx, byte 0x4
    mov eax, 0x7d
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x6

section .retained_17 align=1 vstart=0x22864 follows=.retained_16
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, 0x9b8
    mov [nosplit edx*2 + actor_base_tile], cx
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov edi, ecx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor edi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xfffff480
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0x200
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0xfffffbac
    mov eax, 0x7e
    mov bh, 0x4
    movsx edx, ax
    mov cl, 0x6
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_18 align=1 vstart=0x229a9 follows=.retained_17
    mov cl, 0x4
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0x2180
    movsx edx, ax
    shl edx, byte 4
    mov ebp, 0xffffdc80
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xf00
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0x7f
    mov [edx + actor_destination_parameter_two], ebp
    movsx edx, ax
    mov [edx + actor_enabled], cl
    movsx edx, ax
    mov byte [edx + actor_board], 0x6
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0xffffe600
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0x1880

section .retained_19 align=1 vstart=0x22b00 follows=.retained_18
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, edi
    mov [nosplit edx*2 + mode_five_tile], di
    movsx edx, ax
    xor ecx, edi
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0xffffe600
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x1880
    movsx edx, ax
    mov esi, 0xffffec00
    shl edx, byte 0x4
    mov edi, 0xfffffb00
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    mov bh, 0x5
    shl edx, byte 0x4
    mov eax, 0x80
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov cl, 0x6
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_20 align=1 vstart=0x22c1e follows=.retained_19
    mov esi, 0x3e8
    movsx edx, ax
    mov bl, 0x3
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x2e65
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0xa02
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov edi, ecx
    mov [nosplit edx*2 + mode_six_tile], cx
    movsx edx, ax
    xor edi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x480
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0x1a00
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0x1680
    mov eax, 0x81
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x5
    movsx edx, ax
    mov byte [edx + actor_board], 0x6

section .retained_21 align=1 vstart=0x22dc0 follows=.retained_20
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, esi
    mov [nosplit edx*2 + mode_six_tile], si
    movsx edx, ax
    xor ecx, esi
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0x1700
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x380
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0x800
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0x1880
    mov eax, 0x82
    mov bh, 0x5
    movsx edx, ax
    mov cl, 0x6
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0xffffe000
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov edi, 0x3a00
    xor ebp, ebp
    mov [nosplit edx*4 + saved_actor_y], edi
    movsx edx, ax
    mov ch, 0x10
    mov [nosplit edx*4 + actor_z_offset], ebp
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x3
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x2e65
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0xa02
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov edi, ecx
    mov [nosplit edx*2 + mode_six_tile], cx
    movsx edx, ax
    xor edi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0xffffe000
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x3a00
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xffffd000
    movsx edx, ax
    mov edi, 0xffffff00
    shl edx, byte 0x4
    mov eax, 0x83
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x5
    movsx edx, ax
    mov byte [edx + actor_board], 0x6

section .retained_22 align=1 vstart=0x23098 follows=.retained_21
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, esi
    mov [nosplit edx*2 + mode_six_tile], si
    movsx edx, ax
    xor ecx, esi
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x4600
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0x2e00
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0x6c00
    mov eax, 0x92
    xor bh, bh
    movsx edx, ax
    mov cl, 0x7
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_x], 0xffffe300
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov ecx, 0xcb00
    xor esi, esi
    mov [nosplit edx*4 + saved_actor_y], ecx
    movsx edx, ax
    mov ch, 0x10
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x2
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x565
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x966
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor esi, esi
    mov [nosplit edx*4 + actor_first_waypoint], si
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0xffffe300
    movsx edx, ax
    shl edx, byte 4
    mov ebp, 0xcb00
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xfffff400
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0x93
    mov [edx + actor_destination_parameter_two], ebp
    movsx edx, ax
    xor ch, ch
    mov [edx + actor_enabled], ch
    movsx edx, ax
    mov byte [edx + actor_board], 0x7
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0xfffff400
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov [nosplit edx*4 + saved_actor_y], ebp

section .retained_23 align=1 vstart=0x23355 follows=.retained_22
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_four_tile], di
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor edi, edi
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    mov ecx, 0xcb00
    mov [edx + actor_destination_y], ecx
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xffffe300
    movsx edx, ax
    mov bh, 0x4
    shl edx, byte 0x4
    mov eax, 0x94
    mov [edx + actor_destination_parameter_two], ecx
    movsx edx, ax
    mov cl, 0x7
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_24 align=1 vstart=0x2347a follows=.retained_23
    mov bl, 0x1
    movsx edx, ax
    mov ecx, 0x3665
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x2
    mov [nosplit edx*2 + saved_actor_lotag], cx
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_three_tile], si
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xc200
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0x3100
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0xba00
    mov eax, 0x95
    movsx edx, ax
    mov [edx + actor_enabled], cl
    movsx edx, ax
    mov byte [edx + actor_board], 0x7

section .retained_25 align=1 vstart=0x235f3 follows=.retained_24
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_two_tile], di
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], di
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0x2480
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x9100
    movsx edx, ax
    mov ebx, 0x2680
    shl edx, byte 0x4
    mov ecx, 0xc700
    mov [edx + actor_destination_parameter_one], ebx
    movsx edx, ax
    mov bh, 0x4
    shl edx, byte 0x4
    mov eax, 0x96
    mov [edx + actor_destination_parameter_two], ecx
    movsx edx, ax
    mov cl, 0x7
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0x2780
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov edi, 0xad80
    xor ebp, ebp
    mov [nosplit edx*4 + saved_actor_y], edi
    movsx edx, ax
    mov ch, 0x8
    mov [nosplit edx*4 + actor_z_offset], ebp
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x1
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x4665
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x2
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x9b8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, 0x9b8
    mov [nosplit edx*2 + mode_one_tile], cx
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov esi, ecx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor esi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], si
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0x2780
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xad80
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0x400
    movsx edx, ax
    mov edi, 0xa980
    shl edx, byte 0x4
    mov eax, 0x97
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x7

section .retained_26 align=1 vstart=0x238a7 follows=.retained_25
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, 0x9b8
    mov [nosplit edx*2 + actor_base_tile], cx
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov edi, ecx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor edi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x9280
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0x1300
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0x9780
    mov eax, 0x98
    mov bh, 0x4
    movsx edx, ax
    mov cl, 0x7
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_27 align=1 vstart=0x239ec follows=.retained_26
    mov cl, 0x4
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0xffffc300
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xb900
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xffffba00
    movsx edx, ax
    mov ecx, 0xc100
    shl edx, byte 0x4
    mov eax, 0x99
    mov [edx + actor_destination_parameter_two], ecx
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x7
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0xffff9e00
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0xd580

section .retained_28 align=1 vstart=0x23b48 follows=.retained_27
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, edi
    mov [nosplit edx*2 + mode_five_tile], di
    movsx edx, ax
    xor ecx, edi
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0xffff9e00
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xd580
    movsx edx, ax
    mov esi, 0xffffb180
    shl edx, byte 0x4
    mov edi, 0xe380
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    mov bh, 0x5
    shl edx, byte 0x4
    mov eax, 0x9a
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov cl, 0x7
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_29 align=1 vstart=0x23c66 follows=.retained_28
    mov esi, 0x3e8
    movsx edx, ax
    mov bl, 0x3
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x2e65
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0xa02
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov edi, ecx
    mov [nosplit edx*2 + mode_six_tile], cx
    movsx edx, ax
    xor edi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xdc80
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xffffa600
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0xd780
    mov eax, 0x9b
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x5
    movsx edx, ax
    mov byte [edx + actor_board], 0x7

section .retained_30 align=1 vstart=0x23e08 follows=.retained_29
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, esi
    mov [nosplit edx*2 + mode_six_tile], si
    movsx edx, ax
    xor ecx, esi
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0xffff9380
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xdf00
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xffffa500
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0xd380
    mov eax, 0x9d
    xor bh, bh
    movsx edx, ax
    mov cl, 0x7
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0xffffb100
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov edi, 0x7500
    xor ebp, ebp
    mov [nosplit edx*4 + saved_actor_y], edi
    movsx edx, ax
    mov ch, 0x10
    mov [nosplit edx*4 + actor_z_offset], ebp
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x2
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x565
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x3
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x966
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx

section .retained_31 align=1 vstart=0x23ffe follows=.retained_30
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0x9e
    mov [edx + actor_destination_parameter_two], ebp
    movsx edx, ax
    xor ch, ch
    mov [edx + actor_enabled], ch
    movsx edx, ax
    mov byte [edx + actor_board], 0x7

section .retained_32 align=1 vstart=0x24073 follows=.retained_31
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_z_offset], ecx

section .retained_33 align=1 vstart=0x240c1 follows=.retained_32
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx

section .retained_34 align=1 vstart=0x24144 follows=.retained_33
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    xor bh, bh
    shl edx, byte 0x4
    mov eax, 0x9f
    mov [edx + actor_destination_parameter_two], esi
    movsx edx, ax
    mov cl, 0x7
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_35 align=1 vstart=0x241dc follows=.retained_34
    mov bl, 0x2
    movsx edx, ax
    mov ecx, 0x1865
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], cx
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + mode_two_tile], 0x8f8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0xffffde00
    movsx edx, ax
    shl edx, byte 4
    mov ebp, 0x8d80
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0x580
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0xa0
    mov [edx + actor_destination_parameter_two], ebp
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x5
    movsx edx, ax
    mov byte [edx + actor_board], 0x7
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0xffffea80
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0x7200

section .retained_36 align=1 vstart=0x24361 follows=.retained_35
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], di
    movsx edx, ax
    xor esi, esi
    mov [nosplit edx*4 + actor_first_waypoint], si
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0xffffea80
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x7200
    movsx edx, ax
    mov esi, 0xffffeb00
    shl edx, byte 0x4
    mov edi, 0xa100
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    mov bh, 0x5
    shl edx, byte 0x4
    mov eax, 0xa1
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov cl, 0x7
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_37 align=1 vstart=0x244b3 follows=.retained_36
    mov bh, 0x1
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_four_tile], cx
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], cx
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x8400
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xffffda80
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0xa500
    mov eax, 0xa2
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x5
    movsx edx, ax
    mov byte [edx + actor_board], 0x7

section .retained_38 align=1 vstart=0x24626 follows=.retained_37
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_two_tile], di
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov esi, edi
    mov [nosplit edx*2 + mode_six_tile], di
    movsx edx, ax
    xor esi, edi
    mov [nosplit edx*4 + actor_first_waypoint], si
    movsx edx, ax
    shl edx, byte 4
    mov edi, 0x3480
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xb100
    movsx edx, ax
    mov ebx, 0x2780
    shl edx, byte 0x4
    mov ecx, 0xa700
    mov [edx + actor_destination_parameter_one], ebx
    movsx edx, ax
    mov bh, 0x5
    shl edx, byte 0x4
    mov eax, 0xa3
    mov [edx + actor_destination_parameter_two], ecx
    movsx edx, ax
    mov cl, 0x7
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_39 align=1 vstart=0x24776 follows=.retained_38
    mov bh, 0x1
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, 0xa02
    mov [nosplit edx*2 + actor_base_tile], cx
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], cx
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0x3480
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xa300
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0x2780
    movsx edx, ax
    mov edi, 0xad00
    shl edx, byte 0x4
    mov eax, 0xa4
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    xor ch, ch
    mov [edx + actor_enabled], ch
    movsx edx, ax
    mov byte [edx + actor_board], 0x7

section .retained_40 align=1 vstart=0x248f0 follows=.retained_39
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], di
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xaf00
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0xa480
    mov eax, 0xa5
    xor bh, bh
    movsx edx, ax
    mov cl, 0x7
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_x], 0xffffff00
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov ecx, 0xb980
    mov esi, ebp
    mov [nosplit edx*4 + saved_actor_y], ecx
    movsx edx, ax
    xor esi, ebp
    mov [nosplit edx*4 + actor_z_offset], esi

section .retained_41 align=1 vstart=0x24a16 follows=.retained_40
    movsx edx, ax
    mov bl, 0x2
    mov [edx + actor_projectile_type], bl

section .retained_42 align=1 vstart=0x24a38 follows=.retained_41
    movsx edx, ax
    mov [edx + actor_mode], bl
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x966
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor esi, esi
    mov [nosplit edx*4 + actor_first_waypoint], si
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    xor ebp, ebp
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_parameter_one], ebx
    movsx edx, ax
    xor ecx, ecx
    shl edx, byte 0x4
    mov eax, 0xa6
    mov [edx + actor_destination_parameter_two], ecx
    movsx edx, ax
    xor ch, ch
    mov [edx + actor_enabled], ch
    movsx edx, ax
    mov byte [edx + actor_board], 0x7

section .retained_43 align=1 vstart=0x24b64 follows=.retained_42
    movsx edx, ax
    mov cl, 0x2
    mov [edx + actor_projectile_type], cl

section .retained_44 align=1 vstart=0x24b86 follows=.retained_43
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor edi, edi
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_x], ebx
    movsx edx, ax
    shl edx, byte 4
    xor ecx, ecx
    mov [edx + actor_destination_y], ecx
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_parameter_one], esi

section .retained_45 align=1 vstart=0x24c4d follows=.retained_44
    movsx edx, ax
    xor bh, bh
    mov cl, 0xa
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_46 align=1 vstart=0x24c8e follows=.retained_45
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_z_offset], ecx

section .retained_47 align=1 vstart=0x24cb1 follows=.retained_46
    mov bl, 0x2
    movsx edx, ax
    mov ecx, 0x565
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], cx
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + mode_two_tile], 0x8f8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov edi, 0xcb00
    mov [edx + actor_destination_y], edi
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xfffff400
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0xd2
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x2
    movsx edx, ax
    mov byte [edx + actor_board], 0xa

section .retained_48 align=1 vstart=0x24de1 follows=.retained_47
    movsx edx, ax
    xor esi, esi
    mov [nosplit edx*4 + actor_z_offset], esi

section .retained_49 align=1 vstart=0x24e04 follows=.retained_48
    movsx edx, ax
    xor cl, cl
    mov [edx + actor_projectile_type], cl

section .retained_50 align=1 vstart=0x24e30 follows=.retained_49
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov edi, 0xa70
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov esi, edi
    mov [nosplit edx*2 + mode_six_tile], di
    movsx edx, ax
    xor esi, edi
    mov [nosplit edx*4 + actor_first_waypoint], si
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_x], 0xfffff880
    movsx edx, ax
    shl edx, byte 4
    mov ebp, 0xac00
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xffffcd00
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_two], ebp
    mov eax, 0xd3
    mov bh, 0x4
    movsx edx, ax
    mov cl, 0xa
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_51 align=1 vstart=0x24f7f follows=.retained_50
    mov bh, 0x2
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov edi, ecx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor edi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xb000
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    mov edi, 0x9d00
    shl edx, byte 0x4
    mov eax, 0xd4
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x5
    movsx edx, ax
    mov byte [edx + actor_board], 0xa
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov ebp, 0xffffdb80
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], ebp
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_y], 0x8d00

section .retained_52 align=1 vstart=0x250e0 follows=.retained_51
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, esi
    mov [nosplit edx*2 + mode_six_tile], si
    movsx edx, ax
    xor ecx, esi
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov edi, 0x8d00
    mov [edx + actor_destination_y], edi
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_one], 0xfffffb00
    movsx edx, ax
    xor bh, bh
    shl edx, byte 0x4
    mov eax, 0xb1
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov cl, 0x18
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_x], 0xffff9680
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov ecx, 0x1f80
    xor esi, esi
    mov [nosplit edx*4 + saved_actor_y], ecx
    movsx edx, ax
    mov ch, 0x10
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x2
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x565
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x5
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x966
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], cx
    movsx edx, ax
    xor edi, edi
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    mov edi, 0xffff9680
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x1f80
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], edi
    movsx edx, ax
    mov ecx, 0xffffea00
    shl edx, byte 0x4
    mov eax, 0xb2
    mov [edx + actor_destination_parameter_two], ecx
    movsx edx, ax
    xor ch, ch
    mov [edx + actor_enabled], ch
    movsx edx, ax
    mov byte [edx + actor_board], 0x18
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    mov esi, 0xffffa080
    sub edx, ebx
    movsx ebx, ax
    mov [nosplit edx*4 + saved_actor_x], esi
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov edi, 0xffffe800
    mov [nosplit edx*4 + saved_actor_y], edi

section .retained_53 align=1 vstart=0x253b2 follows=.retained_52
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + mode_two_tile], 0x8f8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_four_tile], cx
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], si
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov ebx, 0xffffa080
    mov [edx + actor_destination_x], ebx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], edi
    movsx edx, ax
    shl edx, byte 4
    mov edi, 0x2100
    mov [edx + actor_destination_parameter_one], ebx
    movsx edx, ax
    xor bh, bh
    shl edx, byte 0x4
    mov eax, 0xb3
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov cl, 0x18
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_54 align=1 vstart=0x254d5 follows=.retained_53
    mov ch, 0x10
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x2
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x565
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x3
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x966
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov esi, 0x8f8
    mov [nosplit edx*2 + mode_two_tile], si
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], cx

section .retained_55 align=1 vstart=0x255b8 follows=.retained_54
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], esi

section .retained_56 align=1 vstart=0x255ef follows=.retained_55
    movsx edx, ax
    xor ch, ch
    mov [edx + actor_enabled], ch
    movsx edx, ax
    mov byte [edx + actor_board], 0x18

section .retained_57 align=1 vstart=0x25662 follows=.retained_56
    movsx edx, ax
    mov ch, 0x1
    mov [edx + actor_profile], ch
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], ch
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov esi, 0x966
    mov [nosplit edx*2 + actor_base_tile], si
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + mode_two_tile], 0x8f8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], si
    movsx edx, ax
    xor ecx, ecx
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    xor ebp, ebp
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_parameter_one], ebx
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0xb5
    mov [edx + actor_destination_parameter_two], ebx
    movsx edx, ax
    xor bh, bh
    mov cl, 0x18
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_58 align=1 vstart=0x257aa follows=.retained_57
    movsx edx, ax
    mov bl, 0x2
    mov [edx + actor_projectile_type], bl

section .retained_59 align=1 vstart=0x257cc follows=.retained_58
    movsx edx, ax
    mov [edx + actor_mode], bl
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x966
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x966
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x8f8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], cx
    movsx edx, ax
    xor edi, edi
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_x], ebx
    movsx edx, ax
    shl edx, byte 4
    xor ecx, ecx
    mov [edx + actor_destination_y], ecx
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_parameter_one], esi

section .retained_60 align=1 vstart=0x258a7 follows=.retained_59
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x2
    movsx edx, ax
    mov byte [edx + actor_board], 0x18

section .retained_61 align=1 vstart=0x258e6 follows=.retained_60
    movsx edx, ax
    mov [nosplit edx*4 + actor_z_offset], esi

section .retained_62 align=1 vstart=0x25907 follows=.retained_61
    movsx edx, ax
    xor cl, cl
    mov [edx + actor_projectile_type], cl

section .retained_63 align=1 vstart=0x25933 follows=.retained_62
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0xa70
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, esi
    mov [nosplit edx*2 + mode_six_tile], di
    movsx edx, ax
    xor ecx, esi
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xb80
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0xfffff980
    mov eax, 0xb7
    mov bh, 0x2
    movsx edx, ax
    mov cl, 0x18
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_x], 0xffffc780
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov ecx, 0x400
    xor esi, esi
    mov [nosplit edx*4 + saved_actor_y], ecx
    movsx edx, ax
    mov ch, 0x10
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    xor bl, bl
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x1a65
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x2
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0xa70
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    xor ecx, ecx
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0xa70
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], cx
    movsx edx, ax
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    xor ebp, ebp
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_parameter_one], ebx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_two], ebx
    mov eax, 0xb8
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x2
    movsx edx, ax
    mov byte [edx + actor_board], 0x18

section .retained_64 align=1 vstart=0x25ba7 follows=.retained_63
    movsx edx, ax
    mov [nosplit edx*4 + actor_z_offset], ebp

section .retained_65 align=1 vstart=0x25bbb follows=.retained_64
    movsx edx, ax
    mov word [nosplit edx*2 + actor_health], 0x3e8
    movsx edx, ax
    xor cl, cl
    mov [edx + actor_projectile_type], cl

section .retained_66 align=1 vstart=0x25bf4 follows=.retained_65
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0xa70
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 0x3
    xor edi, edi
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], di

section .retained_67 align=1 vstart=0x25c86 follows=.retained_66
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_x], ebx
    movsx edx, ax
    shl edx, byte 4
    xor ecx, ecx
    mov [edx + actor_destination_y], ecx
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_parameter_one], esi

section .retained_68 align=1 vstart=0x25cc1 follows=.retained_67
    mov bh, 0x5
    movsx edx, ax
    mov cl, 0x18
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_69 align=1 vstart=0x25d02 follows=.retained_68
    movsx edx, ax
    mov ch, 0x10
    mov [nosplit edx*4 + actor_z_offset], esi
    movsx edx, ax
    mov esi, 0x3e8
    mov [edx + actor_sequence_initial], ch
    movsx edx, ax
    mov bl, 0x3
    mov [nosplit edx*2 + actor_health], si
    movsx edx, ax
    mov edi, 0x2e65
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x1
    mov [nosplit edx*2 + saved_actor_lotag], di
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0xa02
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    xor ecx, ecx
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], cx
    movsx edx, ax
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x1b00
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0xfffff400
    mov eax, 0xba
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x5
    movsx edx, ax
    mov byte [edx + actor_board], 0x18

section .retained_70 align=1 vstart=0x25eb6 follows=.retained_69
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 0x3
    xor edi, edi
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], di
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], di
    movsx edx, ax
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], edi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], edi
    movsx edx, ax
    mov bh, 0x5
    shl edx, byte 0x4
    mov eax, 0xbb
    mov [edx + actor_destination_parameter_two], edi
    movsx edx, ax
    mov cl, 0x18
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_71 align=1 vstart=0x25fbe follows=.retained_70
    movsx edx, ax
    xor ebp, ebp
    mov [nosplit edx*4 + actor_z_offset], ebp

section .retained_72 align=1 vstart=0x25fe1 follows=.retained_71
    movsx edx, ax
    mov bl, 0x3
    mov [edx + actor_projectile_type], bl

section .retained_73 align=1 vstart=0x26003 follows=.retained_72
    movsx edx, ax
    mov [edx + actor_mode], bl
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0xa02
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    xor ecx, ecx
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0xa02
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_three_tile], si
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_five_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_six_tile], cx

section .retained_74 align=1 vstart=0x260a0 follows=.retained_73
    movsx edx, ax
    shl edx, byte 4
    xor ebx, ebx
    mov [edx + actor_destination_x], ebx

section .retained_75 align=1 vstart=0x260d7 follows=.retained_74
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x18

section .retained_76 align=1 vstart=0x26116 follows=.retained_75
    movsx edx, ax
    xor esi, esi
    mov [nosplit edx*4 + actor_z_offset], esi

section .retained_77 align=1 vstart=0x26164 follows=.retained_76
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_one_tile], si
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0x900
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_parameter_two], 0xffffe500
    mov eax, 0xbd
    mov bh, 0x4
    movsx edx, ax
    mov cl, 0x18
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov dword [nosplit edx*4 + saved_actor_x], 0x4980
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x2
    sub edx, ebx
    mov ecx, 0xc00
    mov esi, ebp
    mov [nosplit edx*4 + saved_actor_y], ecx
    movsx edx, ax
    xor esi, ebp
    mov [nosplit edx*4 + actor_z_offset], esi

section .retained_78 align=1 vstart=0x26278 follows=.retained_77
    mov ecx, 0x3e8
    movsx edx, ax
    mov bl, 0x1
    mov [nosplit edx*2 + actor_health], cx
    movsx edx, ax
    mov esi, 0x3665
    mov [edx + actor_projectile_type], bl
    movsx edx, ax
    mov bh, 0x2
    mov [nosplit edx*2 + saved_actor_lotag], si
    movsx edx, ax
    mov cl, 0x4
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov edi, 0x9b8
    mov [nosplit edx*2 + actor_base_tile], di
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], di
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov ecx, edi
    mov [nosplit edx*2 + mode_five_tile], di
    movsx edx, ax
    xor ecx, edi
    mov [nosplit edx*4 + actor_first_waypoint], cx
    movsx edx, ax
    shl edx, byte 4
    mov edi, 0x4980
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    mov dword [edx + actor_destination_y], 0xc00
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], edi
    movsx edx, ax
    mov ecx, 0xfffffb00
    shl edx, byte 0x4
    mov eax, 0xbe
    mov [edx + actor_destination_parameter_two], ecx
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x18

section .retained_79 align=1 vstart=0x26409 follows=.retained_78
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov word [nosplit edx*2 + actor_base_tile], 0x9b8
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], cx

section .retained_80 align=1 vstart=0x26489 follows=.retained_79
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_x], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], ebp
    movsx edx, ax
    mov bh, 0x4
    shl edx, byte 0x4
    mov eax, 0xbf
    mov [edx + actor_destination_parameter_two], ebp
    movsx edx, ax
    mov cl, 0x18
    mov [edx + actor_enabled], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_board], cl

section .retained_81 align=1 vstart=0x26522 follows=.retained_80
    movsx edx, ax
    mov byte [edx + actor_projectile_type], 0x1

section .retained_82 align=1 vstart=0x26539 follows=.retained_81
    mov bh, 0x2
    movsx edx, ax
    mov cl, 0x1
    mov [edx + actor_profile], bh
    movsx edx, ax
    movsx ebx, ax
    mov [edx + actor_mode], cl
    mov edx, ebx
    shl edx, byte 0x3
    mov ecx, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], cx
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov edi, ecx
    mov [nosplit edx*2 + mode_five_tile], cx
    movsx edx, ax
    xor edi, ecx
    mov [nosplit edx*4 + actor_first_waypoint], di
    movsx edx, ax
    shl edx, byte 4
    xor esi, esi
    mov [edx + actor_destination_x], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_y], esi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], esi
    movsx edx, ax
    shl edx, byte 4
    mov eax, 0xc0
    mov [edx + actor_destination_parameter_two], esi
    movsx edx, ax
    mov byte [edx + actor_enabled], 0x4
    movsx edx, ax
    mov byte [edx + actor_board], 0x18

section .retained_83 align=1 vstart=0x26690 follows=.retained_82
    movsx ebx, ax
    mov edx, ebx
    shl edx, byte 0x3
    mov esi, 0x9b8
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + actor_base_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_one_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_two_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_three_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    movsx ebx, ax
    mov [nosplit edx*2 + mode_four_tile], si
    mov edx, ebx
    shl edx, byte 3
    add edx, ebx
    mov [nosplit edx*2 + mode_five_tile], si
    movsx edx, ax
    xor ebx, ebx
    mov [nosplit edx*4 + actor_first_waypoint], bx
    movsx edx, ax
    shl edx, byte 4
    xor edi, edi
    mov [edx + actor_destination_x], edi
    movsx edx, ax
    shl edx, byte 4
    xor ebp, ebp
    mov [edx + actor_destination_y], ebp
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_one], edi
    movsx edx, ax
    shl edx, byte 4
    mov [edx + actor_destination_parameter_two], edi
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
