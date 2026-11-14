; Scan the HMI detector file and query the matching driver image.
BITS 32
ORG 0x6b2d4

lseek_ equ 0x615b6
read_ equ 0x615f7
read_driver_image equ 0x6e666
read_driver_command_table equ 0x666cb
get_driver_tables equ 0x668b6
copy_driver_record equ 0x668f5
get_detector_callback equ 0x63fb5
set_driver_callback equ 0x6693f
driver_command_0 equ 0x66664
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
command_table equ 0x16970
code_selector equ 0x169ec
code_offset equ 0x169e8
command_table_flags equ 0x169ad
active_command_table equ 0x169dc
active_entry_offset equ 0x169f4

detect_audio_driver:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x28
    mov dword [ebp - 0x28], eax
    mov dword [ebp - 0x24], edx
    mov dword [ebp - 4], 0
    mov dword [ebp - 8], 0
    mov dword [ebp - 0x18], 0
    mov dword [ebp - 0x1c], 0
    cmp dword [ebp - 0x24], 0
    jne short .check_driver_id
    mov dword [ebp - 0x20], 2
    jmp near .return

.check_driver_id:
    cmp dword [ebp - 0x28], 0xe000
    jb short .invalid_driver_id
    cmp dword [ebp - 0x28], 0xe200
    jbe short .rewind_file

.invalid_driver_id:
    mov dword [ebp - 0x20], 6
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
    cmp dword [ebp - 4], 0
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
    mov dword [ebp - 0x14], eax
    mov eax, dword [entry_id]
    cmp eax, dword [ebp - 0x28]
    jne short .skip_entry
    test byte [entry_flags], 0x80
    jne short .load_entry

.skip_entry:
    jmp short .seek_past_entry

.load_entry:
    mov dword [ebp - 4], 1
    lea eax, [ebp - 0x10]
    push eax
    mov edx, dword [ebp - 0x14]
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
    mov edx, dword [ebp - 0x14]
    mov eax, dword [detector_file]
    call lseek_

.advance_entry:
    inc dword [entry_index]
    jmp near .check_entry

.check_match:
    cmp dword [ebp - 4], 0
    je near .missing_driver
    mov eax, command_table
    push eax
    movzx eax, word [data_selector]
    push eax
    push dword [data_offset]
    movzx eax, word [code_selector]
    push eax
    push dword [code_offset]
    call read_driver_command_table
    add esp, 0x14
    test byte [command_table_flags], 1
    je short .probe_driver
    movzx eax, word [data_selector]
    push eax
    push dword [data_offset]
    movzx eax, word [code_selector]
    push eax
    push dword [code_offset]
    call get_driver_tables
    add esp, 0x10
    mov dword [ebp - 0x18], 0

.read_callback_record:
    push dword [ebp - 0x18]
    call copy_driver_record
    add esp, 4
    test eax, eax
    je short .probe_driver
    push dword [ebp - 0x18]
    call copy_driver_record
    add esp, 4
    call get_detector_callback
    mov dword [ebp - 0x1c], eax
    push dword [ebp - 0x1c]
    push dword [ebp - 0x18]
    call set_driver_callback
    add esp, 8
    inc dword [ebp - 0x18]
    jmp short .read_callback_record

.probe_driver:
    movzx eax, word [data_selector]
    push eax
    push dword [data_offset]
    movzx eax, word [code_selector]
    push eax
    push dword [code_offset]
    call driver_command_0
    add esp, 0x10
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    je short .probe_failed
    mov eax, dword [ebp - 0x24]
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
    mov eax, dword [ebp - 0x24]
    add eax, 0x6c
    mov dword [active_command_table], eax
    mov eax, dword [ebp - 8]
    mov edx, dword [ebp - 0x24]
    mov dword [edx + 0x5c], eax
    mov eax, dword [ebp - 0x24]
    mov edx, dword [eax + 0xd0]
    mov eax, dword [ebp - 0x24]
    mov dword [eax + 0x104], edx
    mov eax, dword [ebp - 0xc]
    mov dword [active_entry_offset], eax
    mov dword [ebp - 0x20], 0
    jmp short .return

.probe_failed:
    mov dword [ebp - 0x20], 8
    jmp short .return

.missing_driver:
    mov dword [ebp - 0x20], 7

.return:
    mov eax, dword [ebp - 0x20]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret
