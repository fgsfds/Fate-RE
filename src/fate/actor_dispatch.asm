; Apply actor mode changes and dispatch the selected update profile.
BITS 32
ORG 0x14610

update_actor_common equ 0x14897
profile_one_mode_one equ 0x15411
profile_one_mode_two equ 0x163f2
profile_one_mode_three equ 0x18a37
profile_one_mode_four equ 0x183ce
profile_one_mode_five equ 0x17da9
profile_one_mode_six equ 0x190aa
profile_two_mode_one equ 0x14b50
profile_two_mode_two equ 0x15e07
profile_two_mode_three equ 0x16aa8
profile_two_mode_four equ 0x1711b
profile_two_mode_five equ 0x17784
actor_kind equ 0x7f0a0
actor_mode equ 0x7f67f
previous_mode equ 0x7f964
defer_mode_change equ 0x709bc
actor_sprite_index equ 0x7dab8
actor_state_byte equ 0x7e0f8
actor_delay_byte equ 0x7df03
actor_recovery_counter equ 0x7f295
sprite_x equ 0x2040a0
sprite_y equ 0x2040a4
sprite_sector equ 0x2040b8
sprite_tile equ 0x2040ae
actor_x equ 0x799e8
actor_y equ 0x7a1bc
actor_sector equ 0x7d2e4
actor_tiles equ 0x7abc0
mode_one_tile equ 0x7abc2
mode_two_tile equ 0x7abc4
mode_three_tile equ 0x7abc6
mode_four_tile equ 0x7abc8
mode_five_tile equ 0x7abca
mode_six_tile equ 0x7abcc
actor_profile equ 0x7e8cc
actor_sequence_initial equ 0x7e4e2

dispatch_actor_update:
    push esi
    push edi
    push ebp
    push eax
    push edx
    movsx edx, ax
    movzx esi, byte [edx + actor_kind]
    cmp esi, 3
    je near .return
    mov al, byte [edx + actor_mode]
    mov ah, byte [edx + previous_mode]
    cmp al, ah
    je near .select_profile
    cmp word [defer_mode_change], 0
    jne near .use_previous_mode
    mov di, word [nosplit edx*2 + actor_sprite_index]
    mov byte [edx + previous_mode], al
    cmp esi, 3
    je short .reset_mode_state
    mov byte [edx + actor_kind], 2

.reset_mode_state:
    movsx edx, word [esp + 4]
    xor ah, ah
    mov byte [edx + actor_state_byte], ah
    mov byte [edx + actor_delay_byte], ah
    mov byte [edx + actor_recovery_counter], ah
    test al, al
    je short .select_profile
    movsx esi, di
    imul esi, esi, 0x2c
    mov ebp, dword [esi + sprite_x]
    mov di, word [esi + sprite_sector]
    mov dword [nosplit edx*4 + actor_x], ebp
    mov word [nosplit edx*2 + actor_sector], di
    mov ebp, dword [esi + sprite_y]
    mov edi, edx
    mov dword [nosplit edx*4 + actor_y], ebp
    shl edx, 3
    add edi, edx
    xor edx, edx
    add edi, edi
    mov dl, al
    mov dx, word [edi + edx*2 + actor_tiles]
    mov word [esi + sprite_tile], dx
    jmp short .select_profile

.use_previous_mode:
    mov al, ah

.select_profile:
    movsx esi, word [esp + 4]
    mov ah, byte [esi + actor_profile]
    cmp ah, 1
    jb near .return
    mov edx, esi
    shl edx, 3
    add edx, esi
    add edx, edx
    cmp ah, 1
    jbe short .profile_one
    cmp ah, 2
    je near .profile_two
    jmp near .return

.profile_one:
    test al, al
    je near .return
    and eax, 0xff
    cmp eax, 1
    jne short .profile_one_check_two
    mov eax, esi
    call update_actor_common
    mov eax, esi
    movsx edx, word [edx + mode_one_tile]
    call profile_one_mode_one
    jmp near .return

.profile_one_check_two:
    cmp eax, 2
    jne short .profile_one_check_three
    mov byte [esi + actor_sequence_initial], 0x10
    mov eax, esi
    call update_actor_common
    movsx eax, word [edx + mode_two_tile]
    push eax
    movsx eax, word [esp + 0x20]
    push eax
    mov edi, dword [esp + 0x20]
    push edi
    movsx edx, word [esp + 0xc]
    mov eax, esi
    call profile_one_mode_two
    jmp near .return

.profile_one_check_three:
    cmp eax, 3
    jne short .profile_one_check_four
    mov eax, esi
    call update_actor_common
    mov eax, esi
    movsx edx, word [edx + mode_three_tile]
    call profile_one_mode_three
    jmp near .return

.profile_one_check_four:
    cmp eax, 4
    jne short .profile_one_check_five
    mov eax, esi
    call update_actor_common
    mov eax, esi
    movsx edx, word [edx + mode_four_tile]
    call profile_one_mode_four
    jmp near .return

.profile_one_check_five:
    cmp eax, 5
    jne short .profile_one_check_six
    mov eax, esi
    call update_actor_common
    mov eax, esi
    movsx edx, word [edx + mode_five_tile]
    call profile_one_mode_five
    jmp near .return

.profile_one_check_six:
    cmp eax, 6
    jne near .return
    mov eax, esi
    call update_actor_common
    mov eax, esi
    movsx edx, word [edx + mode_six_tile]
    call profile_one_mode_six
    jmp near .return

.profile_two:
    test al, al
    je near .return
    and eax, 0xff
    cmp eax, 1
    jne short .profile_two_check_two
    mov eax, esi
    call update_actor_common
    mov eax, esi
    movsx edx, word [edx + mode_one_tile]
    call profile_two_mode_one
    jmp near .return

.profile_two_check_two:
    cmp eax, 2
    jne short .profile_two_check_three
    mov eax, esi
    call update_actor_common
    movsx eax, word [edx + mode_two_tile]
    push eax
    movsx eax, word [esp + 0x20]
    push eax
    mov edx, dword [esp + 0x20]
    push edx
    mov eax, esi
    movsx edx, word [esp + 0xc]
    call profile_two_mode_two
    jmp short .return

.profile_two_check_three:
    cmp eax, 3
    jne short .profile_two_check_four
    mov eax, esi
    call update_actor_common
    mov eax, esi
    movsx edx, word [edx + mode_three_tile]
    call profile_two_mode_three
    jmp short .return

.profile_two_check_four:
    cmp eax, 4
    jne short .profile_two_check_five
    mov eax, esi
    call update_actor_common
    mov eax, esi
    movsx edx, word [edx + mode_four_tile]
    call profile_two_mode_four
    jmp short .return

.profile_two_check_five:
    cmp eax, 5
    jne short .return
    mov eax, esi
    call update_actor_common
    mov eax, esi
    movsx edx, word [edx + mode_five_tile]
    call profile_two_mode_five

.return:
    add esp, 8
    pop ebp
    pop edi
    pop esi
    ret 8
