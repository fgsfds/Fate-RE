; Map video memory.
BITS 32
ORG 0x43b71

frame_state_195f equ 0x195f
frame_state_197d equ 0x197d
frame_state_19a1 equ 0x19a1
frame_state_19c1 equ 0x19c1
print_runtime_message equ 0x40bb4
runtime_exit equ 0x60353
int386 equ 0x630b3
frame_state_286b58 equ 0x286b58

map_video_memory:
    push ebx
    push ecx
    push esi
    push edi
    sub esp, 0x1c
    mov esi, eax
    mov ebx, 0x1
    xor edx, edx
    mov eax, 0x31
    mov [esp], dx
    mov [esp + 0x8], bx
    mov ebx, esp
    mov edx, esp
    call int386
    cld
    mov ax, ds
    mov es, eax
    cmp dword [esp + 0x18], 0x0
    jz short .branch_43bb9
    push strict dword frame_state_195f
    call print_runtime_message
    add esp, 0x4
    xor eax, eax
    call runtime_exit

.branch_43bb9:
    mov edi, 0x9
    mov eax, 0x8092
    mov ebx, esp
    xor ecx, ecx
    mov edx, esp
    mov cx, [esp]
    mov [esp + 0x8], ax
    mov eax, 0x31
    mov [esp], di
    mov [esp + 0x4], cx
    call int386
    cld
    mov ax, ds
    mov es, eax
    mov edx, 0x800
    mov ebx, 0x3f
    mov eax, 0x31
    mov [esp + 0x8], si
    mov [esp], dx
    mov [esp + 0x10], bx
    mov edx, esi
    mov ebx, esp
    sar edx, byte 0x10
    mov esi, 0xffff
    mov [esp + 0x4], dx
    mov edx, esp
    mov [esp + 0x14], si
    call int386
    cld
    mov ax, ds
    mov es, eax
    cmp dword [esp + 0x18], 0x0
    jz short .branch_43c46
    push strict dword frame_state_197d
    call print_runtime_message
    add esp, 0x4
    xor eax, eax
    call runtime_exit

.branch_43c46:
    mov edi, 0x7
    xor edx, edx
    xor ebx, ebx
    mov dx, [esp + 0x4]
    mov bx, [esp + 0x8]
    shl edx, byte 0x10
    mov [esp], di
    add edx, ebx
    mov ebx, esp
    mov [frame_state_286b58], edx
    sar edx, byte 0x10
    mov ax, [frame_state_286b58]
    mov [esp + 0x8], dx
    mov [esp + 0xc], ax
    mov edx, esp
    mov eax, 0x31
    mov [esp + 0x4], cx
    call int386
    cld
    mov ax, ds
    mov es, eax
    cmp dword [esp + 0x18], 0x0
    jz short .branch_43caf
    push strict dword frame_state_19a1
    call print_runtime_message
    add esp, 0x4
    xor eax, eax
    call runtime_exit

.branch_43caf:
    mov eax, 0x8
    mov edx, 0x3f
    mov ebx, 0xffff
    mov [esp], ax
    mov [esp + 0x8], dx
    mov [esp + 0xc], bx
    mov ebx, esp
    mov edx, esp
    mov eax, 0x31
    mov [esp + 0x4], cx
    call int386
    cld
    mov ax, ds
    mov es, eax
    cmp dword [esp + 0x18], 0x0
    jz short .branch_43d00
    push strict dword frame_state_19c1
    call print_runtime_message
    add esp, 0x4
    xor eax, eax
    call runtime_exit

.branch_43d00:
    mov edx, ecx
    xor eax, eax
    add esp, 0x1c
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
