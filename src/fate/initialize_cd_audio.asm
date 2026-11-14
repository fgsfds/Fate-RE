; Initialize cd audio.
BITS 32
ORG 0x37950

selected_cd_track equ 0x12d7c
allocate_dos_memory equ 0x37659
detect_cd_drives equ 0x376bb
prepare_cd_request_buffers equ 0x3771a
request_cd_disk_info equ 0x3784f
read_cd_track_info equ 0x3786d
read_cd_track_start equ 0x378d8
open equ 0x61368
far_memmove equ 0x630ce
frame_state_173f50 equ 0x173f50
frame_state_173f54 equ 0x173f54
frame_state_173f88 equ 0x173f88
first_cd_track equ 0x173f8e
frame_state_173f90 equ 0x173f90
frame_state_173f94 equ 0x173f94
frame_state_173f96 equ 0x173f96
frame_state_173f98 equ 0x173f98
last_cd_track equ 0x173f9a
cd_request_segment equ 0x173f9e
frame_state_173fa0 equ 0x173fa0
frame_state_173fa4 equ 0x173fa4
cd_drive_letter equ 0x173fa6
frame_state_173fac equ 0x173fac

initialize_cd_audio:
    push ebx
    push ecx
    push edx
    call detect_cd_drives
    mov [cd_drive_letter], ax
    test ax, ax
    jnz short .branch_37969

.branch_37963:
    xor eax, eax
    pop edx
    pop ecx
    pop ebx
    ret

.branch_37969:
    mov eax, 0x16
    call allocate_dos_memory
    test eax, eax
    jnz short .branch_3797c
    test dx, dx
    jz short .branch_37963

.branch_3797c:
    mov ax, [frame_state_173fa0]
    mov [cd_request_segment], ax
    mov ax, [frame_state_173f90]
    mov [frame_state_173f94], ax
    call prepare_cd_request_buffers
    lgs eax, [frame_state_173f88]
    xor dh, dh
    xor bh, bh
    mov dl, [gs:eax + 0x4]
    mov bl, [gs:eax + 0x3]
    shl edx, byte 0x8
    add edx, ebx
    mov [frame_state_173fa4], dx
    xor dh, dh
    mov dl, [gs:eax + 0x2]
    shl edx, byte 0x8
    mov al, [gs:eax + 0x1]
    xor ah, ah
    push strict byte 0x8
    add edx, eax
    xor eax, eax
    mov word [frame_state_173f54], ds
    mov ax, [frame_state_173fa4]
    mov cx, [frame_state_173f54]
    shl eax, byte 0x4
    mov [frame_state_173f98], dx
    mov [frame_state_173f50], eax
    lea ebx, [eax + 0xa]
    mov edx, ds
    mov eax, frame_state_173fac
    call far_memmove
    push strict byte 0x2
    push strict dword frame_state_173fac
    call open
    mov [frame_state_173f96], ax
    cwde
    add esp, 0x8
    cmp eax, -1
    jz near .branch_37963
    call request_cd_disk_info
    movsx eax, word [frame_state_173f96]
    call read_cd_track_info
    movsx ebx, word [first_cd_track]
    jmp short .branch_37a48

.branch_37a37:
    xor edx, edx
    movsx eax, word [frame_state_173f96]
    mov dl, bl
    call read_cd_track_start
    inc ebx

.branch_37a48:
    movsx eax, word [last_cd_track]
    cmp ebx, eax
    jng short .branch_37a37
    movsx eax, word [first_cd_track]
    mov [selected_cd_track], eax
    mov eax, 0x1
    pop edx
    pop ecx
    pop ebx
    ret
