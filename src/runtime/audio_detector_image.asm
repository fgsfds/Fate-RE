; Open and close the HMI audio detection file and its DPMI image.
BITS 32
ORG 0x6b0ea

strcpy_ equ 0x60333
strcat_ equ 0x60223
open_ equ 0x61368
read_ equ 0x615f7
allocate_driver_memory equ 0x6640b
get_driver_alias equ 0x664ed
lock_memory_region equ 0x66391
lseek_ equ 0x615b6
close_ equ 0x6219a
unlock_memory_region equ 0x663ce
release_driver_memory equ 0x664b7
detector_flags equ 0x16810
detector_path equ 0x16894
detector_filename equ 0x1ef0
detector_file equ 0x169f0
detector_header equ 0x16914
detector_linear_base equ 0x16a00
detector_memory_handle equ 0x169fc
detector_data_selector equ 0x169e4
detector_data_offset equ 0x169e0
detector_code_selector equ 0x169ec
detector_code_offset equ 0x169e8

audio_detection_noop:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

open_audio_detector:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x10
    mov dword [ebp - 0x10], eax
    test byte [detector_flags], 1
    je short .check_directory
    mov dword [ebp - 0xc], 3
    jmp near .return

.check_directory:
    cmp dword [ebp - 0x10], 0
    je short .use_filename
    mov edx, dword [ebp - 0x10]
    mov eax, detector_path
    call strcpy_
    mov edx, detector_filename
    mov eax, detector_path
    call strcat_
    jmp short .open_file

.use_filename:
    mov edx, detector_filename
    mov eax, detector_path
    call strcpy_

.open_file:
    push 0x200
    mov eax, detector_path
    push eax
    call open_
    add esp, 8
    mov dword [detector_file], eax
    cmp dword [detector_file], -1
    jne short .allocate_image
    mov dword [ebp - 0xc], 0xf
    jmp near .return

.allocate_image:
    mov ebx, 0x2c
    mov edx, detector_header
    mov eax, dword [detector_file]
    call read_
    mov eax, detector_linear_base
    push eax
    mov eax, detector_memory_handle
    push eax
    push 0x1000
    call allocate_driver_memory
    mov ebx, edx
    mov ecx, eax
    add esp, 0xc
    mov word [detector_data_selector], bx
    mov dword [detector_data_offset], ecx
    cmp dword [detector_data_offset], 0
    jne short .create_code_alias
    cmp word [detector_data_selector], 0
    jne short .create_code_alias
    mov dword [ebp - 0xc], 5
    jmp short .return

.create_code_alias:
    movzx eax, word [detector_data_selector]
    push eax
    push dword [detector_data_offset]
    call get_driver_alias
    mov ebx, edx
    mov ecx, eax
    add esp, 8
    mov word [detector_code_selector], bx
    mov dword [detector_code_offset], ecx
    push 0x1000
    push dword [detector_linear_base]
    call lock_memory_region
    add esp, 8
    test eax, eax
    je short .rewind_file
    mov dword [ebp - 0xc], 5
    jmp short .return

.rewind_file:
    xor ebx, ebx
    xor edx, edx
    mov eax, dword [detector_file]
    call lseek_
    or byte [detector_flags], 1
    mov dword [ebp - 0xc], 0

.return:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

close_audio_detector:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 4
    and byte [detector_flags], 0xfe
    mov eax, dword [detector_file]
    call close_
    push 0x1000
    push dword [detector_linear_base]
    call unlock_memory_region
    add esp, 8
    test eax, eax
    je short .release_image
    mov dword [ebp - 4], 5
    jmp short .return

.release_image:
    push dword [detector_memory_handle]
    movzx eax, word [detector_data_selector]
    push eax
    push dword [detector_data_offset]
    call release_driver_memory
    add esp, 0xc
    push dword [detector_memory_handle]
    movzx eax, word [detector_code_selector]
    push eax
    push dword [detector_code_offset]
    call release_driver_memory
    add esp, 0xc
    mov dword [ebp - 4], 0

.return:
    mov eax, dword [ebp - 4]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
