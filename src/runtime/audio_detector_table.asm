; Load a detector entry and return its command table without probing the hardware.
BITS 32
ORG 0x6b54b

lseek_ equ 0x615b6
read_ equ 0x615f7
read_driver_image equ 0x6e666
read_driver_command_table equ 0x666cb
entry_index equ 0x169f8
detector_file equ 0x169f0
file_header equ 0x16914
entry_count equ 0x16934
entry_header equ 0x16940
entry_size equ 0x16964
entry_id equ 0x16968
entry_flags equ 0x1696d
data_selector equ 0x169e4
data_offset equ 0x169e0
code_selector equ 0x169ec
code_offset equ 0x169e8
active_command_table equ 0x169dc
active_entry_offset equ 0x169f4

load_detector_command_table:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x1c
    mov dword [ebp - 0x1c], eax
    mov dword [ebp - 0x18], edx
    mov dword [ebp - 8], 0
    cmp dword [ebp - 0x18], 0
    jne short .check_driver_id
    mov dword [ebp - 0x14], 2
    jmp near .return

.check_driver_id:
    cmp dword [ebp - 0x1c], 0xe000
    jb short .invalid_driver_id
    cmp dword [ebp - 0x1c], 0xe200
    jbe short .rewind_file

.invalid_driver_id:
    mov dword [ebp - 0x14], 6
    jmp near .return

.rewind_file:
    mov dword [entry_index], 0
    xor ebx, ebx
    xor edx, edx
    mov eax, dword [detector_file]
    call lseek_
    mov ebx, 0x2c
    mov edx, file_header
    mov eax, dword [detector_file]
    call read_

.check_entry:
    mov eax, dword [entry_index]
    cmp eax, dword [entry_count]
    ja short .finish_scan
    cmp dword [ebp - 8], 0
    je short .read_entry

.finish_scan:
    jmp near .check_match

.read_entry:
    mov ebx, 1
    xor edx, edx
    mov eax, dword [detector_file]
    call lseek_
    mov dword [ebp - 0xc], eax
    mov ebx, 0x30
    mov edx, entry_header
    mov eax, dword [detector_file]
    call read_
    mov eax, dword [entry_size]
    mov dword [ebp - 4], eax
    mov eax, dword [entry_id]
    cmp eax, dword [ebp - 0x1c]
    jne short .skip_entry
    test byte [entry_flags], 0x80
    jne short .load_entry

.skip_entry:
    jmp short .seek_past_entry

.load_entry:
    mov dword [ebp - 8], 1
    lea eax, [ebp - 0x10]
    push eax
    mov edx, dword [ebp - 4]
    mov bx, word [data_selector]
    mov eax, dword [data_offset]
    mov esi, dword [detector_file]
    mov ecx, ebx
    mov ebx, eax
    mov eax, esi
    call read_driver_image
    jmp short .advance_entry

.seek_past_entry:
    mov ebx, 1
    mov edx, dword [ebp - 4]
    mov eax, dword [detector_file]
    call lseek_

.advance_entry:
    inc dword [entry_index]
    jmp near .check_entry

.check_match:
    cmp dword [ebp - 8], 0
    je short .missing_driver
    mov eax, dword [ebp - 0x18]
    add eax, 0x6c
    push eax
    movzx eax, word [data_selector]
    push eax
    push dword [data_offset]
    movzx eax, word [code_selector]
    push eax
    push dword [code_offset]
    call read_driver_command_table
    add esp, 0x14
    mov eax, dword [ebp - 0x18]
    add eax, 0x6c
    mov dword [active_command_table], eax
    mov eax, dword [ebp - 0xc]
    mov dword [active_entry_offset], eax
    mov dword [ebp - 0x14], 0
    jmp short .return

.missing_driver:
    mov dword [ebp - 0x14], 7

.return:
    mov eax, dword [ebp - 0x14]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
