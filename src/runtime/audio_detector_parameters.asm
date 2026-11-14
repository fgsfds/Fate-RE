; Query and apply parameters for the selected HMI detector image.
BITS 32
ORG 0x6bb13

lseek_ equ 0x615b6
windows_driver_interrupt equ 0x6684c
read_driver_parameters equ 0x66687
windows_driver_interrupt_stop equ 0x66881
driver_command_3 equ 0x66724
active_entry_offset equ 0x169f4
detector_file equ 0x169f0
data_selector equ 0x169e4
data_offset equ 0x169e0
code_selector equ 0x169ec
code_offset equ 0x169e8
parameter_ax equ 0x16bf0
parameter_cl equ 0x16bf4
parameter_ch equ 0x16bf8
parameter_dx equ 0x16bfc
detector_values equ 0x16a04

%macro detector_marker 0
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
%endmacro

query_detected_audio_parameters:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0xc
    mov dword [ebp - 0xc], eax
    cmp dword [ebp - 0xc], 0
    jne short .seek_active_entry
    mov dword [ebp - 8], 2
    jmp near .return

.seek_active_entry:
    xor ebx, ebx
    mov edx, dword [active_entry_offset]
    mov eax, dword [detector_file]
    call lseek_
    mov dword [ebp - 4], 0

.start_windows_entry:
    mov ecx, dword [ebp - 4]
    add ecx, ecx
    mov eax, dword [ebp - 0xc]
    mov dx, word [eax + 0xb8]
    mov eax, dword [ebp - 0xc]
    mov ebx, dword [eax + 0xb4]
    mov gs, dx
    lea eax, [nosplit ebx + ecx]
    db 0x66, 0x65, 0x83, 0x38, 0xff ; CMP WORD [GS:EAX], -1, original prefix order.
    je short .query_parameters
    mov ecx, dword [ebp - 4]
    add ecx, ecx
    mov eax, dword [ebp - 0xc]
    mov dx, word [eax + 0xb8]
    mov eax, dword [ebp - 0xc]
    mov ebx, dword [eax + 0xb4]
    mov gs, dx
    lea eax, [nosplit ebx + ecx]
    movsx eax, word [gs:eax]
    push eax
    call windows_driver_interrupt
    add esp, 4
    inc dword [ebp - 4]
    jmp short .start_windows_entry

.query_parameters:
    movzx eax, word [data_selector]
    push eax
    push dword [data_offset]
    movzx eax, word [code_selector]
    push eax
    push dword [code_offset]
    call read_driver_parameters
    add esp, 0x10
    mov dword [ebp - 4], 0

.stop_windows_entry:
    mov ecx, dword [ebp - 4]
    add ecx, ecx
    mov eax, dword [ebp - 0xc]
    mov dx, word [eax + 0xb8]
    mov eax, dword [ebp - 0xc]
    mov ebx, dword [eax + 0xb4]
    mov gs, dx
    lea eax, [nosplit ebx + ecx]
    db 0x66, 0x65, 0x83, 0x38, 0xff ; CMP WORD [GS:EAX], -1, original prefix order.
    je short .store_parameters
    mov ecx, dword [ebp - 4]
    add ecx, ecx
    mov eax, dword [ebp - 0xc]
    mov dx, word [eax + 0xb8]
    mov eax, dword [ebp - 0xc]
    mov ebx, dword [eax + 0xb4]
    mov gs, dx
    lea eax, [nosplit ebx + ecx]
    movsx eax, word [gs:eax]
    push eax
    call windows_driver_interrupt_stop
    add esp, 4
    inc dword [ebp - 4]
    jmp short .stop_windows_entry

.store_parameters:
    mov edx, dword [parameter_ax]
    mov eax, dword [ebp - 0xc]
    mov dword [eax + 0x5c], edx
    mov edx, dword [parameter_cl]
    mov eax, dword [ebp - 0xc]
    mov dword [eax + 0x64], edx
    mov edx, dword [parameter_ch]
    mov eax, dword [ebp - 0xc]
    mov dword [eax + 0x60], edx
    mov edx, dword [parameter_dx]
    mov eax, dword [ebp - 0xc]
    mov dword [eax + 0x68], edx
    mov eax, dword [ebp - 0xc]
    test byte [eax + 0xa8], 1
    jne short .accept_unrestricted
    cmp dword [parameter_ch], 1
    jbe short .reject_parameter_range
    cmp dword [parameter_ch], 0x10
    jb short .accept_parameter_range

.reject_parameter_range:
    jmp short .invalid_parameter

.accept_parameter_range:
    mov dword [ebp - 8], 0
    jmp short .return

.invalid_parameter:
    mov dword [ebp - 8], 0x11
    jmp short .return

.accept_unrestricted:
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

apply_detected_audio_parameters:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x20
    mov dword [ebp - 0x20], eax
    cmp dword [ebp - 0x20], 0
    jne short .read_parameters
    mov dword [ebp - 0x1c], 2
    jmp near .return

.read_parameters:
    mov eax, dword [ebp - 0x20]
    mov eax, dword [eax + 0x5c]
    mov dword [ebp - 4], eax
    mov eax, dword [ebp - 0x20]
    mov eax, dword [eax + 0x64]
    mov dword [ebp - 0xc], eax
    mov eax, dword [ebp - 0x20]
    mov eax, dword [eax + 0x60]
    mov dword [ebp - 8], eax
    mov eax, dword [ebp - 0x20]
    test byte [eax + 0xa8], 1
    jne short .apply_parameters
    cmp dword [ebp - 8], 2
    jb short .invalid_parameter
    cmp dword [ebp - 8], 0xf
    jbe short .apply_parameters

.invalid_parameter:
    mov dword [ebp - 0x1c], 0x11
    jmp short .return

.apply_parameters:
    mov eax, dword [ebp - 0x20]
    push dword [eax + 0x64]
    call windows_driver_interrupt
    add esp, 4
    movzx eax, word [data_selector]
    push eax
    push dword [data_offset]
    push dword [ebp - 0xc]
    push dword [ebp - 8]
    push dword [ebp - 4]
    movzx eax, word [code_selector]
    push eax
    push dword [code_offset]
    call driver_command_3
    add esp, 0x1c
    mov dword [ebp - 0x18], eax
    mov eax, dword [ebp - 0x20]
    push dword [eax + 0x64]
    call windows_driver_interrupt_stop
    add esp, 4
    mov eax, dword [ebp - 0x18]
    mov dword [ebp - 0x1c], eax

.return:
    mov eax, dword [ebp - 0x1c]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

audio_detection_end:
    detector_marker

audio_detection_lookup_start:
    detector_marker

lookup_audio_detector_value:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 8
    mov dword [ebp - 8], eax
    mov eax, dword [ebp - 8]
    shl eax, 2
    mov eax, dword [eax + detector_values]
    mov dword [ebp - 4], eax
    mov eax, dword [ebp - 4]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

audio_detection_lookup_end:
    detector_marker
