; Service digital drivers and queue or stop their samples.
BITS 32
ORG 0x620d6

driver_slots equ 0x1663c
close_descriptor equ 0x64c20
service_driver equ 0x66b75
memcpy equ 0x63245

service_audio_driver_0:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0
    push dword [driver_slots]
    call service_driver
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

service_audio_driver_1:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0
    push dword [driver_slots + 4]
    call service_driver
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

service_audio_driver_2:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0
    push dword [driver_slots + 8]
    call service_driver
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

service_audio_driver_3:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0
    push dword [driver_slots + 12]
    call service_driver
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

service_audio_driver_4:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0
    push dword [driver_slots + 16]
    call service_driver
    add esp, 4
    pop ebp
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

audio_noop_62185:
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

close_:
    jmp near close_descriptor

audio_noop_6219f:
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

queue_audio_sample:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x18
    mov dword [ebp - 0x18], eax
    mov dword [ebp - 0x14], edx
    mov eax, dword [ebp - 0x18]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 0xc], eax
    cmp dword [ebp - 0xc], 0
    jne short .start_slot_scan
    mov dword [ebp - 0x10], 0xa
    jmp near .return_status

.start_slot_scan:
    mov dword [ebp - 4], 0

.check_slot_index:
    mov eax, dword [ebp - 4]
    mov edx, dword [ebp - 0xc]
    cmp eax, dword [edx + 0x14]
    jb short .check_slot_active
    jmp short .check_slot_found

.advance_slot:
    inc dword [ebp - 4]
    jmp short .check_slot_index

.check_slot_active:
    imul edx, dword [ebp - 4], 0xf0
    mov eax, dword [ebp - 0xc]
    mov eax, dword [eax + 0x58]
    add eax, edx
    test byte [eax + 0x21], 0x80
    jne short .advance_slot

.check_slot_found:
    mov eax, dword [ebp - 4]
    mov edx, dword [ebp - 0xc]
    cmp eax, dword [edx + 0x14]
    jne short .copy_sample
    mov dword [ebp - 0x10], 0xffffffff
    jmp near .return_status

.copy_sample:
    mov ebx, 0xf0
    mov edx, dword [ebp - 0x14]
    imul ecx, dword [ebp - 4], 0xf0
    mov eax, dword [ebp - 0xc]
    mov eax, dword [eax + 0x58]
    add eax, ecx
    call memcpy
    imul ebx, dword [ebp - 4], 0xf0
    mov eax, dword [ebp - 0xc]
    mov edx, dword [eax + 0x58]
    add edx, ebx
    mov eax, dword [ebp - 0x14]
    mov eax, dword [eax]
    mov dword [edx + 4], eax
    imul edx, dword [ebp - 4], 0xf0
    mov eax, dword [ebp - 0xc]
    mov eax, dword [eax + 0x58]
    add edx, eax
    mov eax, dword [ebp - 4]
    mov dword [edx + 0x28], eax
    mov eax, dword [ebp - 0xc]
    mov eax, dword [eax + 0x30]
    mov dword [ebp - 8], eax
    cmp dword [ebp - 8], 0
    jne short .find_queue_tail
    imul edx, dword [ebp - 4], 0xf0
    mov eax, dword [ebp - 0xc]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [eax + 0xec], 0
    imul edx, dword [ebp - 4], 0xf0
    mov eax, dword [ebp - 0xc]
    mov eax, dword [eax + 0x58]
    add eax, edx
    or byte [eax + 0x21], 0x80
    imul edx, dword [ebp - 4], 0xf0
    mov eax, dword [ebp - 0xc]
    mov ebx, dword [eax + 0x58]
    mov eax, dword [ebp - 0xc]
    add ebx, edx
    mov dword [eax + 0x30], ebx
    jmp short .record_slot

.find_queue_tail:
    mov eax, dword [ebp - 8]
    cmp dword [eax + 0xec], 0
    je short .append_sample
    mov eax, dword [ebp - 8]
    mov eax, dword [eax + 0xec]
    mov dword [ebp - 8], eax
    jmp short .find_queue_tail

.append_sample:
    imul edx, dword [ebp - 4], 0xf0
    mov eax, dword [ebp - 0xc]
    mov eax, dword [eax + 0x58]
    add eax, edx
    mov dword [eax + 0xec], 0
    imul edx, dword [ebp - 4], 0xf0
    mov eax, dword [ebp - 0xc]
    mov eax, dword [eax + 0x58]
    add eax, edx
    or byte [eax + 0x21], 0x80
    imul edx, dword [ebp - 4], 0xf0
    mov eax, dword [ebp - 0xc]
    mov ebx, dword [eax + 0x58]
    mov eax, dword [ebp - 8]
    add ebx, edx
    mov dword [eax + 0xec], ebx

.record_slot:
    mov eax, dword [ebp - 4]
    mov dword [ebp - 0x10], eax

.return_status:
    mov eax, dword [ebp - 0x10]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

request_sample_stop:
    push ebx
    push ecx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x10
    mov dword [ebp - 0x10], eax
    mov dword [ebp - 0xc], edx
    mov eax, dword [ebp - 0x10]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .check_sample_active
    mov dword [ebp - 8], 0xa
    jmp short .return_status

.check_sample_active:
    imul edx, dword [ebp - 0xc], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    test byte [eax + 0x21], 0x80
    jne short .flag_sample_stop
    mov dword [ebp - 8], 0
    jmp short .return_status

.flag_sample_stop:
    imul edx, dword [ebp - 0xc], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    or byte [eax + 0x21], 0x40
    mov dword [ebp - 8], 0

.return_status:
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    pop ecx
    pop ebx
    ret

request_all_samples_stop:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0x10
    mov dword [ebp - 0x10], eax
    mov eax, dword [ebp - 0x10]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .start_slot_scan
    mov dword [ebp - 0xc], 0xa
    jmp short .return_status

.start_slot_scan:
    mov dword [ebp - 8], 0

.check_slot_index:
    mov eax, dword [ebp - 8]
    mov edx, dword [ebp - 4]
    cmp eax, dword [edx + 0x14]
    jb short .flag_sample_stop
    jmp short .record_success

.advance_slot:
    inc dword [ebp - 8]
    jmp short .check_slot_index

.flag_sample_stop:
    imul edx, dword [ebp - 8], 0xf0
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x58]
    add eax, edx
    or byte [eax + 0x21], 0x40
    jmp short .advance_slot

.record_success:
    mov dword [ebp - 0xc], 0

.return_status:
    mov eax, dword [ebp - 0xc]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret

audio_noop_62414:
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

audio_noop_62429:
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

read_driver_field_1c:
    push ebx
    push ecx
    push edx
    push esi
    push edi
    push ebp
    mov ebp, esp
    sub esp, strict dword 0xc
    mov dword [ebp - 0xc], eax
    mov eax, dword [ebp - 0xc]
    shl eax, 2
    mov eax, dword [eax + driver_slots]
    mov dword [ebp - 4], eax
    cmp dword [ebp - 4], 0
    jne short .read_driver_value
    mov dword [ebp - 8], 0xa
    jmp short .return_value

.read_driver_value:
    mov eax, dword [ebp - 4]
    mov eax, dword [eax + 0x1c]
    mov dword [ebp - 8], eax

.return_value:
    mov eax, dword [ebp - 8]
    leave
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    ret
