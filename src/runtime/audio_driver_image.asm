; Locate the matching HMI driver image and release its mapped regions.
BITS 32
ORG 0x65f10

strcat_ equ 0x60223
strcpy_ equ 0x60333
open_ equ 0x61368
lseek_ equ 0x615b6
read_ equ 0x615f7
close_ equ 0x6219a
lock_memory_region equ 0x66391
unlock_memory_region equ 0x663ce
allocate_driver_memory equ 0x6640b
release_driver_memory equ 0x664b7
get_driver_alias equ 0x664ed
read_driver_image equ 0x6e666
driver_directory equ 0x1653c
driver_path equ 0x165bc
driver_filename equ 0x1e80
file_header equ 0x16660
entry_count equ 0x16680
entry_header equ 0x1668c
entry_id equ 0x166b4
entry_flags equ 0x166b9
entry_size equ 0x166b0
driver_slots equ 0x1663c

load_audio_driver_image:
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x24
    mov dword [ebp - 0x24], eax
    mov dword [ebp - 0x20], edx
    mov dword [ebp - 0x1c], ebx
    mov dword [ebp - 0x18], ecx
    mov dword [ebp - 8], 0
    mov dword [ebp - 0xc], 0
    cmp dword [ebp - 0x20], 5
    jbe short .check_driver_id
    mov dword [ebp - 0x14], 0xa
    jmp near .return

.check_driver_id:
    cmp dword [ebp - 0x24], 0xe000
    jb short .reject_driver_id
    cmp dword [ebp - 0x24], 0xe200
    jbe short .open_driver_file

.reject_driver_id:
    mov dword [ebp - 0x14], 6
    jmp near .return

.open_driver_file:
    mov edx, driver_directory
    mov eax, driver_path
    call strcpy_
    mov edx, driver_filename
    mov eax, driver_path
    call strcat_
    push strict dword 0x200
    mov eax, driver_path
    push eax
    call open_
    add esp, 8
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], -1
    jne short .read_file_header
    mov dword [ebp - 0x14], 0xf
    jmp near .return

.read_file_header:
    mov ebx, 0x2c
    mov edx, file_header
    mov eax, dword [ebp - 4]
    call read_

.check_entry_count:
    mov eax, dword [ebp - 8]
    cmp eax, dword [entry_count]
    ja short .close_after_scan
    cmp dword [ebp - 0xc], 0
    je short .read_entry_header

.close_after_scan:
    jmp near .close_file

.read_entry_header:
    mov ebx, 0x30
    mov edx, entry_header
    mov eax, dword [ebp - 4]
    call read_
    mov eax, dword [entry_id]
    cmp eax, dword [ebp - 0x24]
    jne short .skip_entry
    test byte [entry_flags], 0x80
    jne short .allocate_image

.skip_entry:
    jmp near .seek_past_entry

.allocate_image:
    mov dword [ebp - 0xc], 1
    push dword [ebp + 0x18]
    push dword [ebp + 0x10]
    push dword [entry_size]
    call allocate_driver_memory
    mov ebx, edx
    mov ecx, eax
    add esp, 0xc
    mov eax, dword [ebp - 0x18]
    mov word [eax + 4], bx
    mov eax, dword [ebp - 0x18]
    mov dword [eax], ecx
    mov eax, dword [ebp - 0x18]
    mov ax, word [eax + 4]
    mov ecx, dword [ebp - 0x18]
    mov edx, dword [ecx]
    test edx, edx
    jne short .create_alias
    test ax, ax
    jne short .create_alias
    mov dword [ebp - 0x14], 5
    jmp near .return

.create_alias:
    mov eax, dword [ebp - 0x18]
    movzx eax, word [eax + 4]
    push eax
    mov eax, dword [ebp - 0x18]
    push dword [eax]
    call get_driver_alias
    mov ebx, edx
    mov ecx, eax
    add esp, 8
    mov eax, dword [ebp - 0x1c]
    mov word [eax + 4], bx
    mov eax, dword [ebp - 0x1c]
    mov dword [eax], ecx
    push dword [entry_size]
    mov ecx, dword [ebp + 0x18]
    push dword [ecx]
    call lock_memory_region
    add esp, 8
    test eax, eax
    je short .read_image
    mov dword [ebp - 0x14], 5
    jmp short .return

.read_image:
    lea eax, [ebp - 0x10]
    push eax
    mov edx, dword [entry_size]
    mov ebx, dword [ebp - 0x18]
    mov bx, word [ebx + 4]
    mov eax, dword [ebp - 0x18]
    mov eax, dword [eax]
    mov esi, dword [ebp - 4]
    mov ecx, ebx
    mov ebx, eax
    mov eax, esi
    call read_driver_image
    mov dl, byte [entry_size]
    mov eax, dword [ebp + 0x14]
    mov byte [eax], dl
    jmp short .advance_entry

.seek_past_entry:
    mov ebx, 1
    mov edx, dword [entry_size]
    mov eax, dword [ebp - 4]
    call lseek_

.advance_entry:
    inc dword [ebp - 8]
    jmp near .check_entry_count

.close_file:
    mov eax, dword [ebp - 4]
    call close_
    mov dword [ebp - 0x14], 0

.return:
    mov eax, dword [ebp - 0x14]
    leave
    pop edi
    pop esi
    ret 0xc

unload_audio_driver_image:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0xc
    mov dword [ebp - 0xc], eax
    cmp dword [ebp - 0xc], 5
    jbe short .get_slot
    mov dword [ebp - 8], 0xa
    jmp near .return

.get_slot:
    mov eax, dword [ebp - 0xc]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .unlock_image
    mov dword [ebp - 8], 0xa
    jmp near .return

.unlock_image:
    mov eax, dword [ebp - 4]
    push dword [eax + 0xe8]
    mov eax, dword [ebp - 4]
    push dword [eax + 0xec]
    call unlock_memory_region
    add esp, 8
    test eax, eax
    je short .release_allocations
    mov dword [ebp - 8], 5
    jmp short .return

.release_allocations:
    mov eax, dword [ebp - 4]
    push dword [eax + 0xfc]
    mov eax, dword [ebp - 4]
    movzx eax, word [eax + 0xdc]
    push eax
    mov eax, dword [ebp - 4]
    push dword [eax + 0xd8]
    call release_driver_memory
    add esp, 0xc
    mov eax, dword [ebp - 4]
    push dword [eax + 0xfc]
    mov eax, dword [ebp - 4]
    movzx eax, word [eax + 0xe4]
    push eax
    mov eax, dword [ebp - 4]
    push dword [eax + 0xe0]
    call release_driver_memory
    add esp, 0xc
    mov dword [ebp - 8], 0

.return:
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
