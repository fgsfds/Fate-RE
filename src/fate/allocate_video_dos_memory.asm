; Allocate video dos memory.
BITS 32
ORG 0x43a50

frame_state_1944 equ 0x1944
frame_state_13fe8 equ 0x13fe8
frame_state_13fec equ 0x13fec
frame_state_33a1d equ 0x33a1d
print_runtime_message equ 0x40bb4
register_exit_callback equ 0x40c0d
dpmi_real_mode_far_call equ 0x438f9
runtime_exit equ 0x60353
int386 equ 0x630b3
copy_far_memory equ 0x63272
frame_state_286b80 equ 0x286b80

allocate_video_dos_memory:
    push ecx
    push esi
    push edi
    push ebp
    sub esp, 0x28
    mov esi, eax
    mov edi, edx
    mov ebp, ebx
    cmp dword [frame_state_13fec], 0x0
    jnz short .branch_43acf
    mov edx, 0x100
    mov eax, [frame_state_13fe8]
    mov ebx, esp
    add eax, 0xf
    mov [esp], dx
    sar eax, byte 0x4
    mov edx, esp
    mov [esp + 0x4], ax
    mov eax, 0x31
    call int386
    cld
    mov ax, ds
    mov es, eax
    cmp dword [esp + 0x18], 0x0
    jz short .branch_43aae
    push strict dword frame_state_1944
    call print_runtime_message
    add esp, 0x4
    xor eax, eax
    call runtime_exit

.branch_43aae:
    xor eax, eax
    mov ax, [esp + 0xc]
    mov [frame_state_13fec], eax
    xor eax, eax
    mov ax, [esp]
    mov [frame_state_286b80], eax
    mov eax, frame_state_33a1d
    call register_exit_callback

.branch_43acf:
    mov ax, [frame_state_286b80]
    push ebp
    mov word [esp + 0x28], ds
    mov ebx, edi
    mov [esp + 0x20], ax
    mov ecx, [esp + 0x28]
    mov word [esi + 0xa], 0x0
    xor eax, eax
    mov dx, [frame_state_13fec]
    call copy_far_memory
    lea ecx, [esp + 0x1c]
    mov eax, 0x10
    mov ebx, esi
    mov edx, esi
    call dpmi_real_mode_far_call
    mov edx, [esp + 0x24]
    mov cx, [frame_state_13fec]
    push ebp
    mov eax, edi
    xor ebx, ebx
    call copy_far_memory
    add esp, 0x28
    pop ebp
    pop edi
    pop esi
    pop ecx
    ret
