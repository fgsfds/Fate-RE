; Release digital audio drivers and manage their DOS and DPMI buffers.
BITS 32
ORG 0x61ca3

driver_slots equ 0x1663c
dpmi_audio_exchange equ 0x16650
dpmi_buffer_address equ 0x1665c
driver_call_66641 equ 0x66641
driver_call_66754 equ 0x66754
driver_call_66881 equ 0x66881
query_extender equ 0x669a0
release_dos_buffer equ 0x66580
unload_driver_image equ 0x660f2
release_driver_workspace equ 0x66246
lock_memory_region equ 0x66391
allocate_dos_buffer equ 0x6654a
allocate_exchange_block equ 0x669bd
query_dpmi_buffer equ 0x66a2c
copy_far_memory equ 0x63272
release_exchange_block equ 0x669fe
map_dpmi_buffer equ 0x66ae5
free_dpmi_buffer equ 0x66a98

audio_driver_shutdown:
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x14
    mov dword [ebp - 0x14], eax
    mov dword [ebp - 0x10], edx
    mov dword [ebp - 0xc], ebx
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .check_driver_workspace
    mov dword [ebp - 8], 0xa
    jmp near .return_shutdown_status

.check_driver_workspace:
    mov eax, dword [ebp - 4]
    test byte [eax], 2
    jne short .stop_driver
    mov dword [ebp - 8], 1
    jmp near .return_shutdown_status

.stop_driver:
    mov eax, dword [ebp - 4]
    mov dword [eax + 0x30], 0
    mov eax, dword [ebp - 4]
    movzx eax, word [eax + 0xdc]
    push eax
    mov eax, dword [ebp - 4]
    push dword [eax + 0xd8]
    mov eax, dword [ebp - 4]
    movzx eax, word [eax + 0xe4]
    push eax
    mov eax, dword [ebp - 4]
    push dword [eax + 0xe0]
    call driver_call_66641
    add esp, 0x10
    mov eax, dword [ebp - 4]
    movzx eax, word [eax + 0xdc]
    push eax
    mov eax, dword [ebp - 4]
    push dword [eax + 0xd8]
    mov eax, dword [ebp - 4]
    movzx eax, word [eax + 0xe4]
    push eax
    mov eax, dword [ebp - 4]
    push dword [eax + 0xe0]
    call driver_call_66754
    add esp, 0x10
    mov eax, dword [ebp - 4]
    push dword [eax + 0x64]
    call driver_call_66881
    add esp, 4
    mov eax, dword [ebp - 4]
    test byte [eax], 4
    je short .skip_buffer_release
    cmp dword [ebp - 0x10], 0
    jne short .release_audio_buffer

.skip_buffer_release:
    jmp short .check_driver_image

.release_audio_buffer:
    mov eax, dword [ebp - 4]
    and byte [eax], 0xfb
    call query_extender
    and eax, 0xff
    cmp eax, 3
    jne short .release_legacy_buffer
    mov eax, dword [ebp - 4]
    mov ecx, dword [eax + 0xf0]
    mov eax, dword [ebp - 4]
    mov esi, dword [eax + 0x100]
    mov eax, dword [ebp - 4]
    mov ax, word [eax + 0xf8]
    mov ebx, dword [ebp - 4]
    mov ebx, dword [ebx + 0xf4]
    mov edx, eax
    mov eax, ebx
    movzx eax, dx
    mov ebx, ecx
    mov edx, esi
    call release_dpmi_audio_buffer
    jmp short .check_driver_image

.release_legacy_buffer:
    mov eax, dword [ebp - 4]
    mov ax, word [eax + 0xf8]
    mov ebx, dword [ebp - 4]
    mov ebx, dword [ebx + 0xf4]
    mov edx, eax
    mov eax, ebx
    movzx eax, dx
    push eax
    call release_dos_buffer
    add esp, 4
    mov eax, dword [ebp - 4]
    and byte [eax], 0xfb

.check_driver_image:
    mov eax, dword [ebp - 4]
    test byte [eax], 2
    je short .skip_image_release
    cmp dword [ebp - 0xc], 0
    jne short .release_driver_image

.skip_image_release:
    jmp short .clear_driver_slot

.release_driver_image:
    mov eax, dword [ebp - 0x14]
    call unload_driver_image
    mov eax, dword [ebp - 4]
    mov word [eax + 0xdc], 0
    mov eax, dword [ebp - 4]
    mov dword [eax + 0xd8], 0
    mov eax, dword [ebp - 4]
    mov word [eax + 0xe4], 0
    mov eax, dword [ebp - 4]
    mov dword [eax + 0xe0], 0
    mov eax, dword [ebp - 4]
    mov edx, dword [eax + 0x50]
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x48]
    call release_driver_workspace
    mov edx, 0x1e00
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    call release_driver_workspace
    mov eax, dword [ebp - 4]
    and byte [eax], 0xfd

.clear_driver_slot:
    mov eax, dword [ebp - 0x14]
    shl eax, 2
    mov dword [eax + driver_slots], 0
    mov eax, dword [ebp - 4]
    and byte [eax], 0xfe
    mov dword [ebp - 8], 0

.return_shutdown_status:
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    pop ecx
    ret

allocate_audio_buffer:
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x18
    mov dword [ebp - 0x18], eax
    mov dword [ebp - 0x14], edx
    mov dword [ebp - 0x10], ebx
    mov dword [ebp - 0xc], ecx
    call query_extender
    and eax, 0xff
    cmp eax, 3
    jne short .allocate_legacy_buffer
    mov ebx, dword [ebp - 0x14]
    mov edx, dword [ebp - 0x10]
    mov eax, dword [ebp - 0xc]
    call allocate_dpmi_audio_buffer
    test eax, eax
    je short .lock_dpmi_buffer
    mov dword [ebp - 8], 0
    jmp near .return_buffer_address

.lock_dpmi_buffer:
    push dword [ebp - 0x18]
    mov eax, dword [ebp - 0xc]
    push dword [eax]
    call lock_memory_region
    add esp, 8
    mov eax, dword [ebp - 0xc]
    mov eax, dword [eax]
    mov dword [ebp - 8], eax
    jmp short .return_buffer_address

.allocate_legacy_buffer:
    lea eax, [ebp - 4]
    push eax
    push dword [ebp - 0x14]
    mov eax, dword [ebp - 0x18]
    shr eax, 4
    add eax, 4
    push eax
    call allocate_dos_buffer
    add esp, 0xc

.check_segment_boundary:
    mov eax, dword [ebp - 0x14]
    mov edx, dword [eax]
    and edx, 0xffff
    mov eax, 0xffff
    sub eax, dword [ebp - 0x18]
    cmp edx, eax
    jbe short .save_legacy_buffer
    lea eax, [ebp - 4]
    push eax
    push dword [ebp - 0x14]
    mov eax, dword [ebp - 0x18]
    shr eax, 4
    add eax, 4
    push eax
    call allocate_dos_buffer
    add esp, 0xc
    jmp short .check_segment_boundary

.save_legacy_buffer:
    xor ebx, ebx
    mov edx, dword [ebp - 4]
    mov eax, dword [ebp - 0xc]
    mov word [eax + 4], dx
    mov eax, dword [ebp - 0xc]
    mov dword [eax], ebx
    mov eax, dword [ebp - 0x14]
    mov eax, dword [eax]
    mov dword [ebp - 8], eax

.return_buffer_address:
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    ret

allocate_dpmi_audio_buffer:
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x30
    mov dword [ebp - 0x28], eax
    mov dword [ebp - 0x24], edx
    mov dword [ebp - 0x10], ebx
    mov dword [ebp - 0x14], 0
    mov dword [ebp - 0x18], 0
    mov eax, dword [ebp - 0x28]
    mov word [eax + 4], 0
    mov eax, dword [ebp - 0x28]
    mov dword [eax], 0
    mov eax, dword [ebp - 0x24]
    mov dword [eax], 0
    mov eax, dword [ebp - 0x10]
    mov dword [eax], 0
    mov dword [ebp - 4], 0
    lea eax, [ebp - 4]
    push eax
    lea eax, [ebp - 0xc]
    push eax
    push 0x20
    call allocate_exchange_block
    add esp, 0xc
    test eax, eax
    je short .prepare_dpmi_request
    mov dword [ebp - 0x20], 0
    jmp near .return_dpmi_status

.prepare_dpmi_request:
    xor edx, edx
    mov eax, dword [ebp - 0xc]
    mov word [ebp - 0x2c], ax
    mov dword [ebp - 0x30], edx
    lgs edx, [ebp - 0x30]
    mov dword gs:[edx], 0x1000
    push dword [ebp - 4]
    call query_dpmi_buffer
    add esp, 4
    mov dword [ebp - 0x18], eax
    push 0x10
    mov ebx, dword [ebp - 0x2c]
    mov edx, dword [ebp - 0x30]
    mov esi, ds
    mov ecx, dpmi_audio_exchange
    mov eax, esi
    mov esi, ecx
    mov ecx, ebx
    mov ebx, edx
    mov edx, eax
    mov eax, esi
    call copy_far_memory
    push dword [ebp - 4]
    push dword [ebp - 0xc]
    call release_exchange_block
    add esp, 8
    cmp dword [ebp - 0x18], 0
    jne short .record_dpmi_error
    and word [dpmi_buffer_address], 0xf000
    push dword [dpmi_buffer_address]
    call map_dpmi_buffer
    add esp, 4
    mov dword [ebp - 0x1c], eax
    mov eax, dword [dpmi_buffer_address]
    mov dword [ebp - 0x14], eax
    mov ebx, dword [ebp - 0x1c]
    xor edx, edx
    mov eax, dword [ebp - 0x28]
    mov word [eax + 4], dx
    mov eax, dword [ebp - 0x28]
    mov dword [eax], ebx
    mov eax, dword [ebp - 0x14]
    mov edx, dword [ebp - 0x10]
    mov dword [edx], eax
    mov dword [ebp - 0x20], 0
    jmp short .return_dpmi_status

.record_dpmi_error:
    mov dword [ebp - 0x20], 5

.return_dpmi_status:
    mov eax, dword [ebp - 0x20]
    leave
    pop edi
    pop esi
    pop ecx
    ret

release_dpmi_audio_buffer:
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x1c
    mov dword [ebp - 0x10], eax
    mov dword [ebp - 0x14], edx
    mov dword [ebp - 4], ebx
    lea edx, [ebp - 0xc]
    push edx
    lea edx, [ebp - 8]
    push edx
    push 0x20
    call allocate_exchange_block
    add esp, 0xc
    xor edx, edx
    mov eax, dword [ebp - 8]
    mov word [ebp - 0x18], ax
    mov dword [ebp - 0x1c], edx
    push 0x10
    mov edx, ds
    mov esi, dpmi_audio_exchange
    mov ebx, edx
    mov edx, esi
    mov eax, dword [ebp - 0x18]
    mov esi, dword [ebp - 0x1c]
    mov ecx, ebx
    mov ebx, edx
    mov edx, eax
    mov eax, esi
    call copy_far_memory
    push dword [ebp - 0xc]
    call free_dpmi_buffer
    add esp, 4
    push dword [ebp - 0xc]
    push dword [ebp - 8]
    call release_exchange_block
    add esp, 8
    leave
    pop edi
    pop esi
    pop ecx
    ret
