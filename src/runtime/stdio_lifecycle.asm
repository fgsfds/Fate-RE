; Initialize and shut down Watcom stream records, and consume console input.
BITS 32
ORG 0x6adc6

shutdown_stream equ 0x60831
malloc_ equ 0x6126d
free_recycled_streams equ 0x647a5
fatal_runtime_error equ 0x6e69c
stderr_buffer_flags equ 0x14295
static_streams equ 0x14254
allocation_error_message equ 0x1ec0
open_streams equ 0x2891e0
recycled_streams equ 0x2891dc
standard_streams_end equ 0x142d6
pending_console_char equ 0x1448c

initialize_standard_streams:
    push ebx
    push ecx
    push edx
    mov ah, byte [stderr_buffer_flags]
    and ah, 0xf8
    mov dl, ah
    mov byte [stderr_buffer_flags], ah
    or dl, 4
    mov ecx, static_streams
    mov byte [stderr_buffer_flags], dl
    jmp short .check_stream

.allocate_node:
    mov eax, 8
    call malloc_
    mov ebx, eax
    test eax, eax
    jne short .link_node
    mov eax, 8
    call malloc_
    mov ebx, eax
    test eax, eax
    jne short .link_node
    mov eax, allocation_error_message
    mov edx, 1
    call fatal_runtime_error

.link_node:
    mov edx, dword [open_streams]
    mov dword [ebx + 4], ecx
    mov dword [open_streams], ebx
    add ecx, 0x1a
    mov dword [ebx], edx

.check_stream:
    mov edx, dword [ecx + 0xc]
    test edx, edx
    jne short .allocate_node
    mov dword [recycled_streams], edx
    pop edx
    pop ecx
    pop ebx
    ret

shutdown_all_streams:
    xor eax, eax
    call close_nonstandard_streams.close_from_index
    jmp near free_recycled_streams

close_nonstandard_streams:
    mov eax, 5

.close_from_index:
    push ebx
    push ecx
    push edx
    push esi
    mov edx, eax
    shl eax, 2
    sub eax, edx
    shl eax, 2
    add eax, edx
    mov esi, static_streams
    add eax, eax
    xor ebx, ebx
    add esi, eax
    mov eax, dword [open_streams]
    jmp short .check_node

.inspect_stream:
    mov ecx, dword [eax]
    mov eax, dword [eax + 4]
    mov edx, 1
    test byte [eax + 0xd], 0x40
    jne short .close_stream
    cmp eax, esi
    jb short .next_stream
    cmp eax, standard_streams_end
    jae short .close_stream
    xor edx, edx

.close_stream:
    call shutdown_stream
    inc ebx

.next_stream:
    mov eax, ecx

.check_node:
    test eax, eax
    jne short .inspect_stream
    mov eax, ebx
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

read_console_character:
    push edx
    xor edx, edx
    mov eax, dword [pending_console_char]
    mov dword [pending_console_char], edx
    test eax, eax
    jne short .return
    mov ah, 1
    int 0x21
    and eax, 0xff

.return:
    pop edx
    ret
