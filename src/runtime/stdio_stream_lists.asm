; Manage active and recycled Watcom stream records.
BITS 32
ORG 0x646bd

malloc equ 0x6126d
memset equ 0x61350
set_errno equ 0x6468e
free equ 0x6170a
stream_hook equ 0x144a5
recycled_streams equ 0x2891dc
static_streams equ 0x14254
static_streams_end equ 0x1445c
open_streams equ 0x2891e0

call_stream_hook:
    call dword [stream_hook]
    ret

allocate_stream:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov esi, dword [recycled_streams]
    test esi, esi
    je short start_static_scan
    mov ecx, dword [esi + 4]
    mov edi, dword [ecx + 0xc]
    mov eax, dword [esi]
    and edi, strict dword 0x4003
    mov dword [recycled_streams], eax
    or di, 3
    jmp short initialize_stream

start_static_scan:
    mov ecx, static_streams
    jmp short check_static_limit

check_static_stream:
    test byte [ecx + 0xc], 3
    jne short next_static_stream
    mov eax, 8
    call malloc
    mov esi, eax
    test eax, eax
    je short allocation_failed
    mov edi, 3
    jmp short initialize_stream

next_static_stream:
    add ecx, 0x1a

check_static_limit:
    cmp ecx, static_streams_end
    jb short check_static_stream
    mov eax, 0x22
    mov edi, 0x4003
    call malloc
    mov ecx, eax
    mov esi, eax
    test eax, eax
    je short allocation_failed
    lea ecx, [eax + 8]

initialize_stream:
    mov ebx, 0x1a
    mov eax, ecx
    xor edx, edx
    call memset
    mov dword [ecx + 0xc], edi
    mov eax, dword [open_streams]
    mov dword [esi + 4], ecx
    mov dword [open_streams], esi
    mov dword [esi], eax
    mov eax, ecx
    jmp short return_stream

allocation_failed:
    mov eax, 5
    call set_errno
    xor eax, eax

return_stream:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

recycle_stream:
    push ebx
    push ecx
    push edx
    mov ebx, eax
    mov edx, open_streams

scan_open_streams:
    mov eax, dword [edx]
    test eax, eax
    je short return_recycle
    mov ecx, dword [eax + 4]
    cmp ebx, ecx
    je short unlink_open_stream
    mov edx, eax
    jmp short scan_open_streams

unlink_open_stream:
    mov cl, byte [ecx + 0xc]
    or cl, 3
    mov byte [ebx + 0xc], cl
    mov ebx, dword [eax]
    mov dword [edx], ebx
    mov edx, dword [recycled_streams]
    mov dword [recycled_streams], eax
    mov dword [eax], edx

return_recycle:
    pop edx
    pop ecx
    pop ebx
    ret

free_recycled_streams:
    push edx

read_recycled_head:
    mov edx, dword [recycled_streams]
    test edx, edx
    je short return_free
    mov eax, edx
    mov edx, dword [edx]
    call free
    mov dword [recycled_streams], edx
    jmp short read_recycled_head

return_free:
    pop edx
    ret
